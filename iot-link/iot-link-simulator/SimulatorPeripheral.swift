//
//  SimulatorPeripheral.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import CoreBluetooth
import Foundation

/// BLE peripheral emulating an unprovisioned IoT appliance.
///
/// Built as an `actor` owning the `CBPeripheralManager` and all mutable state (LED,
/// telemetry subscription, the telemetry task). Manager callbacks - which fire on a
/// private queue - are funneled in through a `nonisolated` `PeripheralDelegateProxy`,
/// mirroring the central-side concurrency design.
actor SimulatorPeripheral {
    
    private let peripheralQueue = DispatchQueue(label: "com.iotlink.simulator.peripheral", qos: .userInitiated)
    private let proxy = PeripheralDelegateProxy()
    
    // Created once in `init`, thereafter only messaged (it manages its own queue), so it
    // is held outside the actor's isolation - consistent with the central-side design.
    nonisolated(unsafe) private let manager: CBPeripheralManager
    
    // Mutable characteristics retained so we can update values and notify.
    private let telemetryCharacteristic: CBMutableCharacteristic
    private let controlCharacteristic: CBMutableCharacteristic
    private let provisioningCharacteristic: CBMutableCharacteristic
    
    private var ledState: LEDState = .off
    private var isTelemetrySubscribed = false
    private var isTelemetryPaused = false
    private var telemetryTask: Task<Void, Never>?
    private var ticker = TelemetryTicker()
    
    init() {
        telemetryCharacteristic = CBMutableCharacteristic(
            type: GATTProfile.Characteristic.telemetry,
            properties: [.notify],
            value: nil,
            permissions: []
        )
        controlCharacteristic = CBMutableCharacteristic(
            type: GATTProfile.Characteristic.control,
            properties: [.read, .writeWithoutResponse, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        provisioningCharacteristic = CBMutableCharacteristic(
            type: GATTProfile.Characteristic.provisioning,
            properties: [.write, .notify],
            value: nil,
            permissions: [.writeable]
        )
        
        manager = CBPeripheralManager(delegate: proxy, queue: peripheralQueue)
        wireProxy()
    }
    
    // MARK: - Keyboard Commands
    
    /// Toggles the LED locally (as if a physical button were pressed), notifying any
    /// subscribed central of the new state.
    func toggleLED() {
        setLED(ledState.toggled, source: "local toggle")
    }
    
    /// Pauses or resumes telemetry emission without unsubscribing.
    func toggleTelemetryPaused() {
        isTelemetryPaused.toggle()
        log(.telemetry, isTelemetryPaused ? "paused" : "resumed")
        reconcileTelemetryTask()
    }
    
    /// Drops all central connections by restarting advertising (useful for demoing the
    /// central's reconnection behavior in a later milestone).
    func dropConnection() {
        log(.connection, "forcing disconnect - restarting advertising")
        manager.removeAllServices()
        addServiceAndAdvertise()
    }
}

// MARK: - Setup & Callback Wiring

private extension SimulatorPeripheral {
    
    nonisolated func wireProxy() {
        proxy.onUpdateState = { [weak self] state in
            Task { await self?.handleStateUpdate(state) }
        }
        proxy.onSubscribe = { [weak self] characteristic in
            Task { await self?.handleSubscribe(characteristic.value) }
        }
        proxy.onUnsubscribe = { [weak self] characteristic in
            Task { await self?.handleUnsubscribe(characteristic.value) }
        }
        proxy.onReadRequest = { [weak self] request in
            Task { await self?.handleRead(request.value) }
        }
        proxy.onWriteRequests = { [weak self] requests in
            Task { await self?.handleWrites(requests.value) }
        }
    }
    
    func addServiceAndAdvertise() {
        let service = CBMutableService(type: GATTProfile.service, primary: true)
        service.characteristics = [
            provisioningCharacteristic,
            telemetryCharacteristic,
            controlCharacteristic
        ]
        manager.add(service)
        manager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [GATTProfile.service],
            CBAdvertisementDataLocalNameKey: "IoT-Link Simulator"
        ])
        log(.radio, "advertising SmartDeviceService…")
    }
}

// MARK: - Manager Callbacks

private extension SimulatorPeripheral {
    
    func handleStateUpdate(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            log(.radio, "Bluetooth powered on")
            addServiceAndAdvertise()
        case .poweredOff:
            log(.radio, "Bluetooth powered off")
        case .unauthorized:
            log(.radio, "Bluetooth unauthorized - grant permission to advertise")
        case .unsupported:
            log(.radio, "Bluetooth LE peripheral role unsupported on this Mac")
        case .resetting, .unknown:
            log(.radio, "Bluetooth state: \(state.rawValue)")
        @unknown default:
            log(.radio, "Bluetooth state: \(state.rawValue)")
        }
    }
    
    func handleSubscribe(_ characteristic: CBCharacteristic) {
        guard characteristic.uuid == GATTProfile.Characteristic.telemetry else { return }
        isTelemetrySubscribed = true
        log(.telemetry, "central subscribed - starting stream")
        reconcileTelemetryTask()
    }
    
    func handleUnsubscribe(_ characteristic: CBCharacteristic) {
        guard characteristic.uuid == GATTProfile.Characteristic.telemetry else { return }
        isTelemetrySubscribed = false
        log(.telemetry, "central unsubscribed - stopping stream")
        reconcileTelemetryTask()
    }
    
    func handleRead(_ request: CBATTRequest) {
        guard request.characteristic.uuid == GATTProfile.Characteristic.control else {
            manager.respond(to: request, withResult: .attributeNotFound)
            return
        }
        request.value = Serialization.encodeLED(ledState)
        manager.respond(to: request, withResult: .success)
        log(.control, "read → LED \(ledState == .on ? "ON" : "OFF")")
    }
    
    func handleWrites(_ requests: [CBATTRequest]) {
        for request in requests {
            switch request.characteristic.uuid {
            case GATTProfile.Characteristic.control:
                handleControlWrite(request)
            case GATTProfile.Characteristic.provisioning:
                handleProvisioningWrite(request)
            default:
                manager.respond(to: request, withResult: .attributeNotFound)
            }
        }
    }
    
    func handleControlWrite(_ request: CBATTRequest) {
        // WriteWithoutResponse: CoreBluetooth does not expect a `respond(to:)` here.
        setLED(Serialization.decodeLED(request.value ?? Data()), source: "write")
    }
    
    /// Updates the LED state and notifies subscribed centrals of the change, so the app's
    /// control reflects the device's true state regardless of what caused the change.
    func setLED(_ state: LEDState, source: String) {
        ledState = state
        log(.control, "LED \(state == .on ? "ON" : "OFF") (\(source))")
        manager.updateValue(
            Serialization.encodeLED(state),
            for: controlCharacteristic,
            onSubscribedCentrals: nil
        )
    }
    
    func handleProvisioningWrite(_ request: CBATTRequest) {
        let payload = request.value ?? Data()
        
        do {
            let credentials = try Serialization.decodeProvisioning(payload)
            manager.respond(to: request, withResult: .success)
            log(.provisioning, "received credentials - SSID <\(credentials.ssid)> (\(payload.count)B)")
            Task { await self.completeProvisioning() }
        } catch {
            manager.respond(to: request, withResult: .success)
            log(.provisioning, "invalid payload (\(payload.count)B) → 0x01")
            notifyProvisioning(.invalidPayload)
        }
    }
    
    /// After a short simulated delay, acknowledge a valid credential packet with success.
    func completeProvisioning() async {
        try? await Task.sleep(for: .milliseconds(500))
        log(.provisioning, "credentials accepted → 0x00")
        notifyProvisioning(.success)
    }
    
    func notifyProvisioning(_ status: ProvisioningStatus) {
        let data = Data([status.rawValue])
        manager.updateValue(data, for: provisioningCharacteristic, onSubscribedCentrals: nil)
    }
}

// MARK: - Telemetry Task

private extension SimulatorPeripheral {
    
    /// Starts the telemetry loop when subscribed and not paused; cancels it otherwise.
    func reconcileTelemetryTask() {
        let shouldRun = isTelemetrySubscribed && !isTelemetryPaused
        
        if shouldRun, telemetryTask == nil {
            telemetryTask = Task { [weak self] in
                await self?.runTelemetryLoop()
            }
        } else if !shouldRun {
            telemetryTask?.cancel()
            telemetryTask = nil
        }
    }
    
    func runTelemetryLoop() async {
        while !Task.isCancelled {
            let reading = ticker.next()
            let data = Serialization.encodeTelemetry(reading)
            manager.updateValue(data, for: telemetryCharacteristic, onSubscribedCentrals: nil)
            log(.telemetry, String(format: "%.2f°C  %.2f%%", reading.temperature, reading.humidity))
            try? await Task.sleep(for: TelemetryTicker.interval)
        }
    }
}
