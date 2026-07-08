//
//  AccountServiceTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("AccountService persistence")
final class AccountServiceTests {

    private let suiteName = "AccountServiceTests-\(UUID().uuidString)"
    private let userDefaults: UserDefaults

    init() throws {
        userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    @Test("defaults to not onboarded")
    func defaultsToNotOnboarded() async {
        let service = await DefaultAccountService(userDefaults: userDefaults)
        let onboarded = await service.isOnboarded
        #expect(onboarded == false)
    }

    @Test("completeOnboarding persists across service instances")
    func completeOnboardingPersists() async {
        let service = await DefaultAccountService(userDefaults: userDefaults)
        await service.completeOnboarding()

        let onboarded = await service.isOnboarded
        #expect(onboarded)

        // A fresh instance over the same backing suite sees the persisted flag.
        let second = await DefaultAccountService(userDefaults: userDefaults)
        let persisted = await second.isOnboarded
        #expect(persisted)
    }
}
