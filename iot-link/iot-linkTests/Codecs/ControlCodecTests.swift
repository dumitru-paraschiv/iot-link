//
//  ControlCodecTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

/// The simulator's counterparts are compiled into this target and win unqualified
/// lookup; the app's types under test must be module-qualified.
private typealias AppLEDState = iot_link.LEDState
private typealias AppProvisioningStatus = iot_link.ProvisioningStatus

@Suite("LEDState codec")
struct LEDStateCodecTests {

    @Test("round-trips both states", arguments: [AppLEDState.off, AppLEDState.on])
    fileprivate func roundTrip(state: AppLEDState) {
        #expect(AppLEDState.parse(from: state.serialize()) == state)
    }

    @Test("serializes to the single spec byte")
    func serializedBytes() {
        #expect(AppLEDState.off.serialize() == Data([0x00]))
        #expect(AppLEDState.on.serialize() == Data([0x01]))
    }

    @Test("treats any non-0x01 byte as off", arguments: [UInt8]([0x00, 0x02, 0x7F, 0xFF]))
    func nonOneIsOff(byte: UInt8) {
        #expect(AppLEDState.parse(from: Data([byte])) == .off)
    }

    @Test("treats empty data as off")
    func emptyIsOff() {
        #expect(AppLEDState.parse(from: Data()) == .off)
    }
}

@Suite("ProvisioningStatus raw bytes")
struct ProvisioningStatusTests {

    @Test("maps the four spec status bytes")
    func specBytes() {
        #expect(AppProvisioningStatus(rawValue: 0x00) == .success)
        #expect(AppProvisioningStatus(rawValue: 0x01) == .invalidPayload)
        #expect(AppProvisioningStatus(rawValue: 0x02) == .authFailure)
        #expect(AppProvisioningStatus(rawValue: 0x03) == .wifiTimeout)
    }

    @Test("rejects unknown bytes", arguments: [UInt8]([0x04, 0x10, 0xFF]))
    func unknownBytes(byte: UInt8) {
        #expect(AppProvisioningStatus(rawValue: byte) == nil)
    }
}
