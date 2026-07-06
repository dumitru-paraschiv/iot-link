//
//  BluetoothCentralService.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 05.07.2026.
//

import Combine
import CoreBluetooth
import Foundation

protocol BluetoothCentralService: Sendable {
    
    /// Current connection state, replayed to new subscribers.
    var statePublisher: AnyPublisher<BluetoothState, Never> { get }
    
    /// Peripherals discovered during the current scan, replayed to new subscribers.
    var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> { get }
    
    func startScanning() async
    func stopScanning() async
    func connect(to id: UUID) async
    func disconnect() async
    
    /// Writes Wi-Fi credentials to the provisioning characteristic and awaits the
    /// peripheral's status-byte handshake notification.
    ///
    /// - Returns: the peripheral's `ProvisioningStatus` (e.g. `.success`, `.invalidPayload`).
    /// - Throws: `ProvisioningError` if the device is not ready, the credentials cannot be
    ///   serialized, the write fails, no acknowledgment arrives within the timeout, or the
    ///   response is unrecognized.
    func provision(_ credentials: WiFiCredentials) async throws -> ProvisioningStatus
}

/// BLE central built as an `actor` that owns the `CBCentralManager` and all mutable
/// state. Delegate callbacks - which fire on the private central queue - are funneled
/// back into the actor through a `nonisolated` `CentralDelegateProxy`.
///
/// Scope (Milestone 2): permission/state handling, scanning, connect/disconnect, and
/// service + characteristic discovery. Characteristic I/O (telemetry, LED, provisioning)
/// and reconnection back-off arrive in later milestones.
actor DefaultBluetoothCentralService: BluetoothCentralService {
    
    private let centralQueue = DispatchQueue(label: "com.iotlink.bluetooth.central", qos: .userInitiated)
    private let proxy = CentralDelegateProxy()
    
    // Created once in `init` and thereafter only sent messages (it manages its own
    // queue), so it is safe to hold outside the actor's isolation. This also lets the
    // synchronous `init` assign it without a cross-actor hop under the project's
    // `-default-isolation=MainActor` setting.
    nonisolated(unsafe) private let centralManager: CBCentralManager
    
    /// The peripheral we are currently connecting to / connected to. Retained so
    /// CoreBluetooth does not deallocate it mid-connection.
    private var activePeripheral: CBPeripheral?
    
    /// Peripherals seen during the current scan, keyed by identifier.
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    
    /// Characteristics cached after discovery, keyed by their UUID. Consumed by later
    /// milestones for telemetry/LED/provisioning I/O.
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    
    /// Continuation for the in-flight `provision(_:)` call, resumed by the provisioning
    /// characteristic's status notification or the timeout. `nil` when idle.
    private var provisioningContinuation: CheckedContinuation<ProvisioningStatus, Error>?
    
    /// How long to wait for the provisioning handshake before giving up.
    private let provisioningTimeout: Duration = .seconds(10)
    
    // Subjects are mutated only from within the actor; exposed read-only as publishers.
    nonisolated(unsafe) private let stateSubject = CurrentValueSubject<BluetoothState, Never>(.unknown)
    nonisolated(unsafe) private let peripheralsSubject = CurrentValueSubject<[DiscoveredPeripheral], Never>([])
    
    nonisolated var statePublisher: AnyPublisher<BluetoothState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    nonisolated var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> {
        peripheralsSubject.eraseToAnyPublisher()
    }
    
    init() {
        centralManager = CBCentralManager(delegate: proxy, queue: centralQueue)
        wireProxy()
    }
    
    // MARK: - Public API
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            trace("ignored - central not powered on (state: \(stateSubject.value))")
            return
        }
        discoveredPeripherals.removeAll()
        peripheralsSubject.send([])
        stateSubject.send(.scanning)
        centralManager.scanForPeripherals(withServices: [GATTProfile.service])
    }
    
    func stopScanning() {
        centralManager.stopScan()
        if stateSubject.value == .scanning {
            stateSubject.send(.idle)
        }
    }
    
    func connect(to id: UUID) {
        guard let peripheral = discoveredPeripherals[id] else {
            trace("no discovered peripheral for id <\(id)>")
            return
        }
        centralManager.stopScan()
        activePeripheral = peripheral
        stateSubject.send(.connecting)
        centralManager.connect(peripheral)
    }
    
    func disconnect() {
        finishProvisioning(with: .failure(ProvisioningError.notReady))
        guard let peripheral = activePeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func provision(_ credentials: WiFiCredentials) async throws -> ProvisioningStatus {
        guard let peripheral = activePeripheral,
              let characteristic = characteristics[GATTProfile.Characteristic.provisioning] else {
            throw ProvisioningError.notReady
        }
        guard provisioningContinuation == nil else {
            throw ProvisioningError.notReady
        }
        guard let packet = credentials.serialize() else {
            throw ProvisioningError.invalidCredentials
        }
        
        stateSubject.send(.provisioning)
        
        // Suspend until the peripheral's status notification (or the timeout) resumes us.
        // The write is issued from inside the continuation body so a synchronously-delivered
        // ack can never race ahead of the continuation being stored.
        let status = try await withCheckedThrowingContinuation { continuation in
            provisioningContinuation = continuation
            peripheral.writeValue(packet, for: characteristic, type: .withResponse)
            startProvisioningTimeout()
        }
        
        stateSubject.send(status == .success ? .provisioned : .connected)
        return status
    }
}

// MARK: - Setup & Callback Wiring

private extension DefaultBluetoothCentralService {
    
    nonisolated func wireProxy() {
        proxy.onUpdateState = { [weak self] state in
            Task { await self?.handleStateUpdate(state) }
        }
        proxy.onDiscover = { [weak self] arguments in
            let (peripheral, rssi) = arguments
            Task { await self?.handleDiscover(peripheral.value, rssi: rssi) }
        }
        proxy.onConnect = { [weak self] peripheral in
            Task { await self?.handleConnect(peripheral.value) }
        }
        proxy.onFailToConnect = { [weak self] _ in
            Task { await self?.handleDisconnect() }
        }
        proxy.onDisconnect = { [weak self] _ in
            Task { await self?.handleDisconnect() }
        }
        proxy.onDiscoverServices = { [weak self] peripheral in
            Task { await self?.handleDiscoverServices(peripheral.value) }
        }
        proxy.onDiscoverCharacteristics = { [weak self] service in
            Task { await self?.handleDiscoverCharacteristics(service.value) }
        }
        proxy.onWriteValue = { [weak self] arguments in
            let (characteristic, error) = arguments
            Task { await self?.handleWriteValue(characteristic.value, error: error.value) }
        }
        proxy.onUpdateValue = { [weak self] characteristic in
            Task { await self?.handleUpdateValue(characteristic.value) }
        }
    }
}

// MARK: - State Machine

private extension DefaultBluetoothCentralService {
    
    func handleStateUpdate(_ state: CBManagerState) {
        switch state {
        case .poweredOn: stateSubject.send(.idle)
        case .poweredOff: stateSubject.send(.poweredOff)
        case .unauthorized: stateSubject.send(.unauthorized)
        case .unknown, .resetting: stateSubject.send(.unknown)
        case .unsupported: stateSubject.send(.unauthorized)
        @unknown default: stateSubject.send(.unknown)
        }
    }
    
    func handleDiscover(_ peripheral: CBPeripheral, rssi: Int) {
        discoveredPeripherals[peripheral.identifier] = peripheral
        
        let discovered = discoveredPeripherals.values
            .map { DiscoveredPeripheral(id: $0.identifier, name: $0.name, rssi: rssi) }
            .unique(by: \.id)
        
        peripheralsSubject.send(discovered)
    }
    
    func handleConnect(_ peripheral: CBPeripheral) {
        peripheral.delegate = proxy
        stateSubject.send(.discoveringServices)
        peripheral.discoverServices([GATTProfile.service])
    }
    
    func handleDiscoverServices(_ peripheral: CBPeripheral) {
        guard let service = peripheral.services?.first(where: { $0.uuid == GATTProfile.service }) else {
            trace("primary service not found")
            disconnect()
            return
        }
        stateSubject.send(.discoveringCharacteristics)
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    func handleDiscoverCharacteristics(_ service: CBService) {
        service.characteristics?.forEach { characteristics[$0.uuid] = $0 }
        
        // Subscribe to the provisioning characteristic so the status-byte handshake
        // notification is delivered once we write credentials.
        if let provisioning = characteristics[GATTProfile.Characteristic.provisioning] {
            activePeripheral?.setNotifyValue(true, for: provisioning)
        }
        
        stateSubject.send(.connected)
    }
    
    func handleWriteValue(_ characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == GATTProfile.Characteristic.provisioning else { return }
        // A write error means the ATT transaction failed; abort the pending provision.
        if error != nil {
            finishProvisioning(with: .failure(ProvisioningError.writeFailed))
        }
    }
    
    func handleUpdateValue(_ characteristic: CBCharacteristic) {
        guard characteristic.uuid == GATTProfile.Characteristic.provisioning else { return }
        
        guard let byte = characteristic.value?.first,
              let status = ProvisioningStatus(rawValue: byte) else {
            finishProvisioning(with: .failure(ProvisioningError.invalidResponse))
            return
        }
        finishProvisioning(with: .success(status))
    }
    
    func handleDisconnect() {
        finishProvisioning(with: .failure(ProvisioningError.notReady))
        activePeripheral = nil
        characteristics.removeAll()
        stateSubject.send(.disconnected)
    }
}

// MARK: - Provisioning Continuation

private extension DefaultBluetoothCentralService {
    
    /// Resumes the in-flight provisioning continuation exactly once, then clears it.
    /// Safe to call spuriously — a `nil` continuation is a no-op, which is what guards
    /// against a double-resume when a late notification and the timeout race.
    func finishProvisioning(with result: Result<ProvisioningStatus, Error>) {
        guard let continuation = provisioningContinuation else { return }
        provisioningContinuation = nil
        continuation.resume(with: result)
    }
    
    func startProvisioningTimeout() {
        Task { [provisioningTimeout] in
            try? await Task.sleep(for: provisioningTimeout)
            finishProvisioning(with: .failure(ProvisioningError.timedOut))
        }
    }
}
