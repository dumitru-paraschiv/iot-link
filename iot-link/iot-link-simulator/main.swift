//
//  main.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

// Entry point for the IoT-Link device simulator.
//
// Instantiates the BLE peripheral actor (which begins advertising once Bluetooth powers
// on), wires up keyboard commands, and parks the main thread on the dispatch run loop so
// CoreBluetooth's callbacks can be serviced. `dispatchMain()` never returns.

log(.radio, "IoT-Link device simulator starting…")

let peripheral = SimulatorPeripheral()
KeyboardCommands.start(forwardingTo: peripheral)

dispatchMain()
