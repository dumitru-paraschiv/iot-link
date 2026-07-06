//
//  TelemetryTicker.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

/// Generates organic-looking telemetry via a bounded random walk.
///
/// Each `next()` nudges temperature and humidity by a small random delta and clamps the
/// result to a realistic range, so the dashboard reads as a live sensor rather than a
/// static or obviously-synthetic source. The type is a value type; the driving `Task`
/// lives in `SimulatorPeripheral`, which owns cadence and lifecycle.
nonisolated struct TelemetryTicker: Sendable {
    
    /// Emission cadence while a central is subscribed.
    static let interval: Duration = .seconds(1)
    
    private var temperature: Double
    private var humidity: Double
    
    private let temperatureRange: ClosedRange<Double>
    private let humidityRange: ClosedRange<Double>
    private let temperatureDrift: Double
    private let humidityDrift: Double
    
    init(temperature: Double = 22.0,
         humidity: Double = 45.0,
         temperatureRange: ClosedRange<Double> = 18.0 ... 26.0,
         humidityRange: ClosedRange<Double> = 30.0 ... 60.0,
         temperatureDrift: Double = 0.1,
         humidityDrift: Double = 0.3) {
        self.temperature = temperature
        self.humidity = humidity
        self.temperatureRange = temperatureRange
        self.humidityRange = humidityRange
        self.temperatureDrift = temperatureDrift
        self.humidityDrift = humidityDrift
    }
    
    /// Advances the walk one step and returns the new reading.
    mutating func next() -> TelemetryReading {
        temperature = drift(temperature, by: temperatureDrift, within: temperatureRange)
        humidity = drift(humidity, by: humidityDrift, within: humidityRange)
        return TelemetryReading(temperature: temperature, humidity: humidity)
    }
    
    private func drift(_ value: Double,
                       by magnitude: Double,
                       within range: ClosedRange<Double>) -> Double {
        let delta = Double.random(in: -magnitude ... magnitude)
        let next = value + delta
        return min(max(next, range.lowerBound), range.upperBound)
    }
}
