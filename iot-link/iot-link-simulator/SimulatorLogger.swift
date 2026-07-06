//
//  SimulatorLogger.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

private nonisolated(unsafe) let sharedISOFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withTime, .withColonSeparatorInTime]
    return formatter
}()

/// Logs a timestamped, categorized line to the console.
///
/// A lightweight, self-contained sibling of the app's `trace`. `print()` performs atomic
/// writes, so output is never garbled across the actor and keyboard threads.
nonisolated func log(_ category: LogCategory, _ message: String) {
    let timestamp = sharedISOFormatter.string(from: Date())
    print("[\(timestamp)] \(category.symbol) \(message)")
}

/// Visual category prefix for a log line.
nonisolated enum LogCategory {
    
    case radio
    case connection
    case provisioning
    case telemetry
    case control
    case command
    
    var symbol: String {
        switch self {
        case .radio: "📡"
        case .connection: "🔗"
        case .provisioning: "🔑"
        case .telemetry: "🌡️"
        case .control: "💡"
        case .command: "⌨️"
        }
    }
}
