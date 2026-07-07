//
//  HomeModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

struct HomeModel {
    
    private(set) var phase: Phase
    private(set) var device: ConnectedDevice?
    private(set) var telemetry: TelemetryReading?
    private(set) var ledState: LEDState?
    
    init(phase: Phase = .empty,
         device: ConnectedDevice? = nil,
         telemetry: TelemetryReading? = nil,
         ledState: LEDState? = nil) {
        self.phase = phase
        self.device = device
        self.telemetry = telemetry
        self.ledState = ledState
    }
    
    enum Phase: Equatable {
        
        case empty
        case dashboard
        case connectionLost
    }
}

// MARK: Extensions

extension HomeModel {
    
    static let builder = HomeModelBuilder.self
    
    var isLEDOn: Bool {
        ledState == .on
    }
}

extension HomeModel {
    
    mutating func accept(phase: Phase) {
        self.phase = phase
    }
    
    mutating func accept(device: ConnectedDevice?) {
        self.device = device
    }
    
    mutating func accept(telemetry: TelemetryReading?) {
        self.telemetry = telemetry
    }
    
    mutating func accept(ledState: LEDState?) {
        self.ledState = ledState
    }
}

// MARK: Builder

enum HomeModelBuilder {
    
    static func makePhase(from state: BluetoothState) -> HomeModel.Phase? {
        switch state {
        case .connected, .provisioned: .dashboard
        case .disconnected: .connectionLost
        default: nil
        }
    }
}
