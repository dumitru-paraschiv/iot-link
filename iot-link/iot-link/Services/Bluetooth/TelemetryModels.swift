//
//  TelemetryModels.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 07.07.2026.
//

import Foundation

/// A single environmental reading decoded from the telemetry characteristic.
///
/// Central-side counterpart of the simulator's `TelemetryReading`; the two targets share
/// only the wire contract in `docs/GATT_SPEC.md`, not code.
nonisolated struct TelemetryReading: Sendable, Equatable {
    
    /// Degrees Celsius.
    let temperature: Double
    
    /// Relative humidity percentage.
    let humidity: Double
}

/// State of the device's status LED, encoded as a single byte per `GATT_SPEC.md`.
nonisolated enum LEDState: UInt8, Sendable {
    
    case off = 0x00
    case on = 0x01
}

/// The peripheral the central is currently connected to, decoupled from `CBPeripheral`
/// so the ViewModel layer never touches CoreBluetooth types.
nonisolated struct ConnectedDevice: Sendable, Equatable {
    
    let id: UUID
    let name: String?
}

// MARK: - Serialization

extension TelemetryReading {
    
    /// Decodes the 4-byte payload: two Big-Endian `Int16`s (value ÷ 100).
    ///
    /// - Returns: the reading, or `nil` if the payload is not exactly 4 bytes.
    nonisolated static func parse(from data: Data) -> TelemetryReading? {
        guard data.count == 4 else { return nil }
        
        let bytes = [UInt8](data)
        let rawTemperature = Int16(bigEndianBytes: bytes[0], bytes[1])
        let rawHumidity = Int16(bigEndianBytes: bytes[2], bytes[3])
        
        return TelemetryReading(
            temperature: Double(rawTemperature) / 100.0,
            humidity: Double(rawHumidity) / 100.0
        )
    }
}

extension LEDState {
    
    /// Decodes the 1-byte control payload. Any non-`0x01` byte is treated as OFF.
    nonisolated static func parse(from data: Data) -> LEDState {
        guard let first = data.first else { return .off }
        return first == LEDState.on.rawValue ? .on : .off
    }
    
    /// Encodes the LED state as a single byte for the control write.
    nonisolated func serialize() -> Data {
        Data([rawValue])
    }
}

// MARK: - Helpers

private extension Int16 {
    
    /// Reassembles a Big-Endian `Int16` from its two bytes (most-significant first).
    nonisolated init(bigEndianBytes high: UInt8, _ low: UInt8) {
        self = Int16(bitPattern: (UInt16(high) << 8) | UInt16(low))
    }
}
