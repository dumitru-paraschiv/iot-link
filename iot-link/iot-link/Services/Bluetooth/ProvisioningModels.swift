//
//  ProvisioningModels.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

/// Wi-Fi credentials entered by the user, serialized to the provisioning characteristic.
///
/// Central-side counterpart of the simulator's `WiFiCredentials`. The two targets share
/// only the wire contract in `docs/GATT_SPEC.md`, not code.
nonisolated struct WiFiCredentials: Sendable, Equatable {
    
    let ssid: String
    let password: String
}

/// Handshake status byte returned by the peripheral on the provisioning characteristic.
nonisolated enum ProvisioningStatus: UInt8, Sendable {
    
    case success = 0x00
    case invalidPayload = 0x01
    case authFailure = 0x02
    case wifiTimeout = 0x03
}

/// Failure while provisioning a device.
nonisolated enum ProvisioningError: Error, Equatable {
    
    /// The credentials exceeded the spec's byte bounds and could not be serialized.
    case invalidCredentials
    /// The characteristic write failed at the ATT layer.
    case writeFailed
    /// No status notification arrived within the timeout window.
    case timedOut
    /// The peripheral replied with an unrecognized status byte.
    case invalidResponse
    /// The device is not in a state where it can be provisioned (e.g. not connected).
    case notReady
}

// MARK: - Serialization

extension WiFiCredentials {
    
    /// Spec bounds per `docs/GATT_SPEC.md` provisioning payload.
    nonisolated static let maxSSIDLength = 32
    nonisolated static let maxPasswordLength = 64
    
    /// Serializes to `[SSID Length][Password Length][SSID bytes][Password bytes]`.
    ///
    /// - Returns: the packet, or `nil` if either field is empty, not UTF-8 encodable, or
    ///   exceeds its spec bound.
    nonisolated func serialize() -> Data? {
        guard let ssidData = ssid.data(using: .utf8),
              let passwordData = password.data(using: .utf8) else { return nil }
        
        guard ssidData.isNotEmpty,
              ssidData.count <= Self.maxSSIDLength,
              passwordData.count <= Self.maxPasswordLength else { return nil }
        
        var packet = Data(capacity: 2 + ssidData.count + passwordData.count)
        packet.append(UInt8(ssidData.count))
        packet.append(UInt8(passwordData.count))
        packet.append(ssidData)
        packet.append(passwordData)
        return packet
    }
}
