//
//  TelemetryCodecTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

/// The simulator's `TelemetryReading` is compiled into this target and wins unqualified
/// lookup; the app's type under test must be module-qualified.
private typealias AppTelemetryReading = iot_link.TelemetryReading

@Suite("TelemetryReading parsing")
struct TelemetryCodecTests {

    @Test("decodes big-endian fixed-point values (÷ 100)")
    func knownVector() {
        // 0x09C4 = 2500 → 25.0 °C, 0x1388 = 5000 → 50.0 %
        let reading = AppTelemetryReading.parse(from: Data([0x09, 0xC4, 0x13, 0x88]))
        #expect(reading == AppTelemetryReading(temperature: 25.0, humidity: 50.0))
    }

    @Test("decodes negative temperatures via the Int16 bit pattern")
    func negativeTemperature() {
        // 0xFF38 = -200 as Int16 → -2.0 °C
        let reading = AppTelemetryReading.parse(from: Data([0xFF, 0x38, 0x13, 0x88]))
        #expect(reading == AppTelemetryReading(temperature: -2.0, humidity: 50.0))
    }

    @Test("rejects payloads that are not exactly 4 bytes", arguments: [0, 1, 3, 5])
    func rejectsWrongLength(count: Int) {
        let data = Data(repeating: 0x00, count: count)
        #expect(AppTelemetryReading.parse(from: data) == nil)
    }
}
