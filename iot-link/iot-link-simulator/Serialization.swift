//
//  Serialization.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

/// Peripheral-side encode/decode of the raw byte layouts defined in `docs/GATT_SPEC.md`.
///
/// This is the mirror of the central's serialization: the simulator *decodes* what the
/// app writes (provisioning, LED) and *encodes* what it notifies (telemetry, LED reads).
nonisolated enum Serialization {
    
    // Bounds per GATT_SPEC.md provisioning payload.
    static let maxSSIDLength = 32
    static let maxPasswordLength = 64
    
    // MARK: - Provisioning (decode)
    
    /// Decodes a `[SSID Length][Password Length][SSID][Password]` credential packet.
    ///
    /// - Throws: `ProvisioningError.invalidPayload` if the header is missing, the declared
    ///   lengths exceed spec bounds, the buffer is too short, or the bytes are not UTF-8.
    static func decodeProvisioning(_ data: Data) throws -> WiFiCredentials {
        // Need at least the two length bytes.
        guard data.count >= 2 else { throw ProvisioningError.invalidPayload }
        
        // `Data` from CoreBluetooth may be non-zero-indexed; normalize to a 0-based array.
        let bytes = [UInt8](data)
        
        let ssidLength = Int(bytes[0])
        let passwordLength = Int(bytes[1])
        
        guard ssidLength <= maxSSIDLength,
              passwordLength <= maxPasswordLength else {
            throw ProvisioningError.invalidPayload
        }
        
        let expectedCount = 2 + ssidLength + passwordLength
        guard bytes.count == expectedCount else { throw ProvisioningError.invalidPayload }
        
        let ssidBytes = bytes[2 ..< (2 + ssidLength)]
        let passwordBytes = bytes[(2 + ssidLength) ..< expectedCount]
        
        guard let ssid = String(bytes: ssidBytes, encoding: .utf8),
              let password = String(bytes: passwordBytes, encoding: .utf8) else {
            throw ProvisioningError.invalidPayload
        }
        
        return WiFiCredentials(ssid: ssid, password: password)
    }
    
    // MARK: - Telemetry (encode)
    
    /// Encodes a reading as two big-endian `Int16`s (value × 100), 4 bytes total.
    static func encodeTelemetry(_ reading: TelemetryReading) -> Data {
        let rawTemp = Int16(clampedFixedPoint: reading.temperature)
        let rawHumidity = Int16(clampedFixedPoint: reading.humidity)
        
        var data = Data(capacity: 4)
        data.append(bigEndianBytes(of: rawTemp))
        data.append(bigEndianBytes(of: rawHumidity))
        return data
    }
    
    // MARK: - LED control
    
    /// Decodes the 1-byte LED control payload. Any non-`0x01` byte is treated as OFF.
    static func decodeLED(_ data: Data) -> LEDState {
        guard let first = data.first else { return .off }
        return first == LEDState.on.rawValue ? .on : .off
    }
    
    /// Encodes the current LED state as a single byte (for read responses).
    static func encodeLED(_ state: LEDState) -> Data {
        Data([state.rawValue])
    }
}

// MARK: - Helpers

private extension Serialization {
    
    static func bigEndianBytes(of value: Int16) -> Data {
        var bigEndian = value.bigEndian
        return withUnsafeBytes(of: &bigEndian) { Data($0) }
    }
}

private extension Int16 {
    
    /// Fixed-point encode (value × 100), clamped to `Int16` range to avoid overflow.
    init(clampedFixedPoint value: Double) {
        let scaled = (value * 100.0).rounded()
        let bounded = Swift.min(Swift.max(scaled, Double(Int16.min)), Double(Int16.max))
        self = Int16(bounded)
    }
}
