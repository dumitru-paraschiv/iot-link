//
//  SettingsModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

struct SettingsModel {
    
    private(set) var isDeviceConnected: Bool
    
    init(isDeviceConnected: Bool = false) {
        self.isDeviceConnected = isDeviceConnected
    }
}

// MARK: Extensions

extension SettingsModel {
    
    /// Title for the provisioning entry: adding a first device vs replacing the connected
    /// one (opening the scanner drops the current device — see `ScanViewModel`).
    var addDeviceTitle: String {
        isDeviceConnected ? "Replace Device" : "Add Device"
    }
}

extension SettingsModel {
    
    mutating func accept(isDeviceConnected: Bool) {
        self.isDeviceConnected = isDeviceConnected
    }
}
