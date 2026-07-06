//
//  PeripheralDelegateProxy.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import CoreBluetooth

/// Bridges `CBPeripheralManager`'s delegate callbacks - which fire on the manager's
/// private queue - into the `SimulatorPeripheral` actor.
///
/// Mirrors the central-side `CentralDelegateProxy`: the proxy is `nonisolated` and
/// thread-agnostic, forwarding each callback to a `@Sendable` closure the actor installs
/// at construction. Non-`Sendable` CoreBluetooth objects are wrapped in `UncheckedSendable`
/// to cross the boundary. Conformance is declared on the class (not an extension) so it
/// inherits the type's `nonisolated` isolation under `-default-isolation=MainActor`.
nonisolated final class PeripheralDelegateProxy: NSObject, CBPeripheralManagerDelegate, @unchecked Sendable {
    
    var onUpdateState: (@Sendable (CBManagerState) -> Void)?
    var onSubscribe: (@Sendable (UncheckedSendable<CBCharacteristic>) -> Void)?
    var onUnsubscribe: (@Sendable (UncheckedSendable<CBCharacteristic>) -> Void)?
    var onReadRequest: (@Sendable (UncheckedSendable<CBATTRequest>) -> Void)?
    var onWriteRequests: (@Sendable (UncheckedSendable<[CBATTRequest]>) -> Void)?
}

// MARK: - CBPeripheralManagerDelegate

extension PeripheralDelegateProxy {
    
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        onUpdateState?(peripheral.state)
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       central: CBCentral,
                                       didSubscribeTo characteristic: CBCharacteristic) {
        onSubscribe?(UncheckedSendable(characteristic))
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       central: CBCentral,
                                       didUnsubscribeFrom characteristic: CBCharacteristic) {
        onUnsubscribe?(UncheckedSendable(characteristic))
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       didReceiveRead request: CBATTRequest) {
        onReadRequest?(UncheckedSendable(request))
    }
    
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       didReceiveWrite requests: [CBATTRequest]) {
        onWriteRequests?(UncheckedSendable(requests))
    }
}
