//
//  ScanModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

struct ScanModel {
    
    private(set) var devices: [Device]
    private(set) var connectingDeviceID: UUID?
    
    init(devices: [Device] = [],
         connectingDeviceID: UUID? = nil) {
        self.devices = devices
        self.connectingDeviceID = connectingDeviceID
    }
    
    struct Device: Identifiable, Equatable {
        
        let id: UUID
        let name: String
        let signal: SignalStrength
        
        /// Three-tier signal bucket derived from RSSI, friendlier to display than raw dBm.
        enum SignalStrength: Int, Comparable {
            
            case weak
            case medium
            case strong
            
            static func < (lhs: SignalStrength, rhs: SignalStrength) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }
    }
}

// MARK: Extensions

extension ScanModel {
    
    static let builder = ScanModelBuilder.self
    
    var isConnecting: Bool { connectingDeviceID.isSome }
}

extension ScanModel {
    
    mutating func accept(devices: [Device]) {
        self.devices = devices
    }
    
    mutating func accept(connectingDeviceID: UUID?) {
        self.connectingDeviceID = connectingDeviceID
    }
}

// MARK: Builder

enum ScanModelBuilder {
    
    static func makeDevices(from peripherals: [DiscoveredPeripheral]) -> [ScanModel.Device] {
        peripherals
            .map { peripheral in
                ScanModel.Device(
                    id: peripheral.id,
                    name: peripheral.name ?? "Unknown Device",
                    signal: makeSignalStrength(from: peripheral.rssi)
                )
            }
        // Sort by signal tier, with a stable id tiebreaker so same-tier rows keep a
        // fixed order across the frequent updates from duplicate-allowed scanning.
            .sorted { lhs, rhs in
                lhs.signal != rhs.signal
                ? lhs.signal > rhs.signal
                : lhs.id.uuidString < rhs.id.uuidString
            }
    }
}

private extension ScanModelBuilder {
    
    static func makeSignalStrength(from rssi: Int) -> ScanModel.Device.SignalStrength {
        switch rssi {
        case (-60)...: .strong
        case (-80) ..< (-60): .medium
        default: .weak
        }
    }
}
