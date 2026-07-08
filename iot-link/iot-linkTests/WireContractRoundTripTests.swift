//
//  WireContractRoundTripTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

// The iOS app and the macOS simulator deliberately share no code — only the wire
// contract in docs/GATT_SPEC.md. Task 2 compiles the simulator's Serialization.swift +
// PeripheralModels.swift into this target, so these tests prove the two independent
// codec implementations agree byte-for-byte.
//
// Unqualified names resolve to the simulator's types; the app's need qualification.
private typealias SimCredentials = WiFiCredentials
private typealias SimTelemetryReading = TelemetryReading
private typealias AppCredentials = iot_link.WiFiCredentials
private typealias AppTelemetryReading = iot_link.TelemetryReading
private typealias AppLEDState = iot_link.LEDState

@Suite("Central ⇄ simulator wire contract")
struct WireContractRoundTripTests {

    @Test("credentials serialized by the central decode identically on the peripheral")
    func provisioningRoundTrip() throws {
        let app = AppCredentials(ssid: "Café-Network", password: "hunter2!")
        let packet = try #require(app.serialize())

        let sim = try Serialization.decodeProvisioning(packet)
        #expect(sim.ssid == app.ssid)
        #expect(sim.password == app.password)
    }

    @Test("telemetry encoded by the peripheral parses back on the central",
          arguments: [(23.47, 51.9), (-2.0, 0.0), (0.0, 100.0)])
    func telemetryRoundTrip(temperature: Double, humidity: Double) throws {
        let encoded = Serialization.encodeTelemetry(
            SimTelemetryReading(temperature: temperature, humidity: humidity)
        )
        let parsed = try #require(AppTelemetryReading.parse(from: encoded))

        // Fixed-point (× 100) round-to-nearest drifts by at most half a hundredth.
        #expect(abs(parsed.temperature - temperature) <= 0.005)
        #expect(abs(parsed.humidity - humidity) <= 0.005)
    }

    @Test("LED state crosses the wire in both directions")
    func ledRoundTrip() {
        #expect(Serialization.decodeLED(AppLEDState.on.serialize()) == .on)
        #expect(Serialization.decodeLED(AppLEDState.off.serialize()) == .off)
        #expect(AppLEDState.parse(from: Serialization.encodeLED(.on)) == .on)
        #expect(AppLEDState.parse(from: Serialization.encodeLED(.off)) == .off)
    }

    @Test("malformed packets are rejected by the peripheral", arguments: [
        Data(),                                 // header too short (0 bytes)
        Data([0x05]),                           // header too short (1 byte)
        Data([0x05, 0x02, 0x61, 0x62]),         // declared lengths exceed buffer
        Data([0x21, 0x00]),                     // SSID length 33 over spec bound
    ])
    func malformedPackets(packet: Data) {
        #expect(throws: ProvisioningError.invalidPayload) {
            _ = try Serialization.decodeProvisioning(packet)
        }
    }
}
