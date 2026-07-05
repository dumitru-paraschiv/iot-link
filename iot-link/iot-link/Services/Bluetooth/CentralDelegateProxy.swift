//
//  CentralDelegateProxy.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 05.07.2026.
//

import CoreBluetooth

/// Bridges CoreBluetooth's delegate callbacks - which fire on the private central
/// queue - into the `DefaultBluetoothCentralService` actor.
///
/// The proxy is `nonisolated` and thread-agnostic: every delegate method simply
/// forwards to a `@Sendable` closure the actor installs at construction. Non-`Sendable`
/// CoreBluetooth objects are wrapped in `UncheckedSendable` to cross the boundary; the
/// invariant is that they are only dereferenced on the central queue or the actor.
nonisolated final class CentralDelegateProxy: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, @unchecked Sendable {
    
    var onUpdateState: SendableCallback<CBManagerState>?
    var onDiscover: SendableCallback<(UncheckedSendable<CBPeripheral>, Int)>?
    var onConnect: SendableCallback<UncheckedSendable<CBPeripheral>>?
    var onFailToConnect: SendableCallback<UncheckedSendable<CBPeripheral>>?
    var onDisconnect: SendableCallback<UncheckedSendable<CBPeripheral>>?
    var onDiscoverServices: SendableCallback<UncheckedSendable<CBPeripheral>>?
    var onDiscoverCharacteristics: SendableCallback<UncheckedSendable<CBService>>?
}

// MARK: - CBCentralManagerDelegate

extension CentralDelegateProxy {
    
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        onUpdateState?(central.state)
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        onDiscover?((UncheckedSendable(peripheral), RSSI.intValue))
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didConnect peripheral: CBPeripheral) {
        onConnect?(UncheckedSendable(peripheral))
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didFailToConnect peripheral: CBPeripheral,
                                    error: Error?) {
        onFailToConnect?(UncheckedSendable(peripheral))
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDisconnectPeripheral peripheral: CBPeripheral,
                                    error: Error?) {
        onDisconnect?(UncheckedSendable(peripheral))
    }
}

// MARK: - CBPeripheralDelegate

extension CentralDelegateProxy {
    
    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverServices error: Error?) {
        onDiscoverServices?(UncheckedSendable(peripheral))
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverCharacteristicsFor service: CBService,
                                error: Error?) {
        onDiscoverCharacteristics?(UncheckedSendable(service))
    }
}
