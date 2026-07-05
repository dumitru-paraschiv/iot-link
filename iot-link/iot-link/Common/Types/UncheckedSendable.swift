//
//  UncheckedSendable.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 05.07.2026.
//

/// A transfer box for moving a non-`Sendable` reference across an isolation boundary.
///
/// Used to hand CoreBluetooth objects (e.g. `CBPeripheral`, `CBService`) from the
/// central queue into the `DefaultBluetoothCentralService` actor. Safe by invariant:
/// the wrapped reference is only ever touched on the central queue or the actor's
/// executor - never concurrently.
nonisolated struct UncheckedSendable<T>: @unchecked Sendable {
    
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}
