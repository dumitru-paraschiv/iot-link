//
//  WiFiCredentialsTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

/// The simulator's `WiFiCredentials` is compiled into this target and wins unqualified
/// lookup; the app's type under test must be module-qualified.
private typealias AppCredentials = iot_link.WiFiCredentials

@Suite("WiFiCredentials serialization")
struct WiFiCredentialsTests {

    @Test("lays out [ssidLen][pwdLen][ssid][pwd] per GATT_SPEC")
    func packetLayout() {
        let packet = AppCredentials(ssid: "MyWiFi", password: "secret42").serialize()

        var expected = Data([0x06, 0x08])
        expected.append(Data("MyWiFi".utf8))
        expected.append(Data("secret42".utf8))
        #expect(packet == expected)
    }

    @Test("counts multibyte UTF-8 SSIDs in bytes, not characters")
    func multibyteSSID() {
        // "Café" is 4 characters but 5 UTF-8 bytes.
        let packet = AppCredentials(ssid: "Café", password: "pw").serialize()

        #expect(packet?.first == 5)
        #expect(packet?.count == 2 + 5 + 2)
    }

    @Test("accepts fields exactly at the spec bounds (32/64)")
    func boundaryLengths() {
        let ssid = String(repeating: "s", count: 32)
        let password = String(repeating: "p", count: 64)
        let packet = AppCredentials(ssid: ssid, password: password).serialize()

        #expect(packet?.count == 2 + 32 + 64)
        #expect(packet?.first == 32)
    }

    @Test("allows an empty password (open network)")
    func emptyPassword() {
        let packet = AppCredentials(ssid: "Open", password: "").serialize()
        #expect(packet == Data([0x04, 0x00]) + Data("Open".utf8))
    }

    @Test("rejects an empty SSID")
    func emptySSID() {
        #expect(AppCredentials(ssid: "", password: "secret42").serialize() == nil)
    }

    @Test("rejects fields over the spec bounds")
    func overBounds() {
        let longSSID = String(repeating: "s", count: 33)
        let longPassword = String(repeating: "p", count: 65)

        #expect(AppCredentials(ssid: longSSID, password: "pw").serialize() == nil)
        #expect(AppCredentials(ssid: "net", password: longPassword).serialize() == nil)
    }
}
