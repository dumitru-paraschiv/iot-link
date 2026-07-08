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
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("defaults to not onboarded")
    func defaultsToNotOnboarded() async {
        let service = DefaultAccountService(defaults: defaults)
        let onboarded = await service.isOnboarded
        #expect(onboarded == false)
    }

    @Test("completeOnboarding persists across service instances")
    func completeOnboardingPersists() async {
        let service = DefaultAccountService(defaults: defaults)
        await service.completeOnboarding()

        let onboarded = await service.isOnboarded
        #expect(onboarded)

        // A fresh instance over the same backing suite sees the persisted flag.
        let second = DefaultAccountService(defaults: defaults)
        let persisted = await second.isOnboarded
        #expect(persisted)
    }
}
