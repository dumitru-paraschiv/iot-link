//
//  BluetoothModels.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 05.07.2026.
//

import Foundation

/// Lifecycle of the BLE central, mirroring the state machine in `docs/ARCHITECTURE.md`.
///
/// Milestone 2 reaches `.connected` (services + characteristics discovered & cached);
/// Milestone 4 adds the provisioning sub-states; Milestone 6 adds `.reconnecting` for the
/// exponential back-off recovery loop.
nonisolated enum BluetoothState: Sendable, Equatable {
    
    case unknown
    case unauthorized
    case poweredOff
    case idle
    case scanning
    case connecting
    case discoveringServices
    case discoveringCharacteristics
    case connected
    case provisioning
    case provisioned
    /// An unexpected drop is being recovered via back-off attempts.
    case reconnecting
    /// Terminally disconnected — either intentional or after reconnection was exhausted.
    case disconnected
}

/// A peripheral surfaced during scanning, decoupled from `CBPeripheral`.
nonisolated struct DiscoveredPeripheral: Sendable, Equatable {
    
    let id: UUID
    let name: String?
    let rssi: Int
}
