//
//  PeripheralModels.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

/// State of the simulated status LED, encoded as a single byte per `GATT_SPEC.md`.
nonisolated enum LEDState: UInt8, Sendable {
    
    case off = 0x00
    case on = 0x01
    
    var toggled: LEDState {
        self == .on ? .off : .on
    }
}

/// Provisioning handshake status byte returned on the provisioning characteristic.
///
/// `authFailure` / `wifiTimeout` are part of the wire contract but unused by the
/// simulator, which has no real Wi-Fi stack to authenticate against.
nonisolated enum ProvisioningStatus: UInt8, Sendable {
    
    case success = 0x00
    case invalidPayload = 0x01
    case authFailure = 0x02
    case wifiTimeout = 0x03
}

/// A decoded Wi-Fi credential packet received from the central.
nonisolated struct WiFiCredentials: Sendable, Equatable {
    
    let ssid: String
    let password: String
}

/// A single environmental reading, encoded as two big-endian fixed-point `Int16`s.
nonisolated struct TelemetryReading: Sendable, Equatable {
    
    /// Degrees Celsius.
    let temperature: Double
    
    /// Relative humidity percentage.
    let humidity: Double
}

/// Failure decoding an inbound provisioning packet. Maps to `ProvisioningStatus`.
nonisolated enum ProvisioningError: Error {
    
    case invalidPayload
}
