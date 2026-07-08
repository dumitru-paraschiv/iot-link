//
//  GATTProfile.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 05.07.2026.
//

import CoreBluetooth

/// Custom GATT profile for the IoT-Link `SmartDeviceService`.
///
/// UUIDs and byte layouts are defined in `docs/GATT_SPEC.md`. To mimic low-power
/// microcontroller constraints, the profile uses raw binary serialization rather
/// than verbose formats like JSON.
nonisolated enum GATTProfile {
    
    /// Primary service advertised by an unprovisioned IoT peripheral.
    static let service = CBUUID(string: "E0C00001-C3B6-4B22-9F1C-123456789ABC")
    
    enum Characteristic {
        
        /// Write (With Response), Notify - uploads Wi-Fi credentials, notifies status.
        static let provisioning = CBUUID(string: "E0C00002-C3B6-4B22-9F1C-123456789ABC")
        
        /// Notify - streams fixed-point Temperature & Humidity telemetry.
        static let telemetry = CBUUID(string: "E0C00003-C3B6-4B22-9F1C-123456789ABC")
        
        /// Read, WriteWithoutResponse - controls and monitors the status LED.
        static let control = CBUUID(string: "E0C00004-C3B6-4B22-9F1C-123456789ABC")
    }
}
