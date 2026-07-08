//
//  UserDefaultsExtensionsTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("Typed UserDefaults extensions")
final class UserDefaultsExtensionsTests {

    private let suiteName = "UserDefaultsExtensionsTests-\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("get returns nil for an unset key")
    func getUnset() {
        #expect(defaults.get(Bool.self, forKey: .isAppOnboarded) == nil)
    }

    @Test("set then get round-trips")
    func setGetRoundTrip() {
        defaults.set(true, forKey: .isAppOnboarded)
        #expect(defaults.get(Bool.self, forKey: .isAppOnboarded) == true)
    }

    @Test("inferred-type get matches the explicit-type variant")
    func inferredGet() {
        defaults.set(true, forKey: .isAppOnboarded)
        let value: Bool? = defaults.get(forKey: .isAppOnboarded)
        #expect(value == true)
    }

    @Test("get with a mismatched type returns nil")
    func wrongTypeGet() {
        defaults.set(true, forKey: .isAppOnboarded)
        #expect(defaults.get(String.self, forKey: .isAppOnboarded) == nil)
    }

    @Test("remove clears the stored value")
    func removeClears() {
        defaults.set(true, forKey: .isAppOnboarded)
        defaults.remove(forKey: .isAppOnboarded)
        #expect(defaults.get(Bool.self, forKey: .isAppOnboarded) == nil)
    }
}
