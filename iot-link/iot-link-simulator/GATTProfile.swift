//
//  GATTProfile.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import CoreBluetooth

/// Custom GATT profile advertised by the simulated IoT peripheral.
///
/// This is the peripheral-side counterpart of the iOS app's `GATTProfile`. The two
/// targets intentionally do not share code - like real firmware and a phone app, they
/// share only the wire contract defined in `docs/GATT_SPEC.md`. The four UUIDs below
/// must stay identical to the app's copy.
nonisolated enum GATTProfile {
    
    /// Primary service advertised to unprovisioned centrals.
    static let service = CBUUID(string: "E0C00001-C3B6-4B22-9F1C-123456789ABC")
    
    enum Characteristic {
        
        /// Write (With Response), Notify - receives Wi-Fi credentials, notifies status.
        static let provisioning = CBUUID(string: "E0C00002-C3B6-4B22-9F1C-123456789ABC")
        
        /// Notify - streams fixed-point Temperature & Humidity telemetry.
        static let telemetry = CBUUID(string: "E0C00003-C3B6-4B22-9F1C-123456789ABC")
        
        /// Read, WriteWithoutResponse - exposes and toggles the status LED.
        static let control = CBUUID(string: "E0C00004-C3B6-4B22-9F1C-123456789ABC")
    }
}
