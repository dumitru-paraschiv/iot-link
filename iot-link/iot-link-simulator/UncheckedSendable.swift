//
//  UncheckedSendable.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

/// A transfer box for moving a non-`Sendable` reference across an isolation boundary.
///
/// Used to hand CoreBluetooth objects (e.g. `CBCentral`, `CBATTRequest`) from the
/// peripheral manager's callback queue into the `SimulatorPeripheral` actor. Safe by
/// invariant: the wrapped reference is only ever touched on the manager's queue or the
/// actor's executor - never concurrently.
nonisolated struct UncheckedSendable<T>: @unchecked Sendable {
    
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}
