//
//  ReconnectionCoordinatorTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("ReconnectionCoordinator attempt budget")
struct ReconnectionCoordinatorTests {

    private static let jitter = 0.25

    private func makeCoordinator(maxAttempts: Int = 5) -> ReconnectionCoordinator {
        let policy = ReconnectionPolicy(
            baseDelay: .seconds(2),
            maxAttempts: maxAttempts,
            jitter: { Self.jitter }
        )
        return ReconnectionCoordinator(policy: policy)
    }

    @Test("delay for the next attempt follows the policy curve before any attempt is recorded")
    func initialDelay() {
        let coordinator = makeCoordinator()
        #expect(coordinator.delayForNextAttempt() == .seconds(2) + .seconds(Self.jitter))
    }

    @Test("delayForNextAttempt does not mutate the counter")
    func nonMutatingPeek() {
        let coordinator = makeCoordinator()
        _ = coordinator.delayForNextAttempt()
        #expect(coordinator.delayForNextAttempt() == .seconds(2) + .seconds(Self.jitter))
    }

    @Test("recordAttemptStarted advances the delay to the next step in the curve")
    func attemptAdvancesCurve() {
        var coordinator = makeCoordinator()
        coordinator.recordAttemptStarted()
        #expect(coordinator.delayForNextAttempt() == .seconds(4) + .seconds(Self.jitter))
        coordinator.recordAttemptStarted()
        #expect(coordinator.delayForNextAttempt() == .seconds(8) + .seconds(Self.jitter))
    }

    @Test("returns nil once the attempt budget is exhausted")
    func budgetExhausted() {
        var coordinator = makeCoordinator(maxAttempts: 2)
        coordinator.recordAttemptStarted()
        #expect(coordinator.delayForNextAttempt() != nil)
        coordinator.recordAttemptStarted()
        #expect(coordinator.delayForNextAttempt() == nil)
    }

    @Test("recordConnectionEstablished resets the budget")
    func resetsOnSuccess() {
        var coordinator = makeCoordinator(maxAttempts: 2)
        coordinator.recordAttemptStarted()
        coordinator.recordAttemptStarted()
        #expect(coordinator.delayForNextAttempt() == nil)
        coordinator.recordConnectionEstablished()
        #expect(coordinator.delayForNextAttempt() == .seconds(2) + .seconds(Self.jitter))
    }
    
    @Test("isInReconnectionCycle reflects whether an attempt has been recorded since the last reset")
    func reflectsAttemptState() {
        var coordinator = makeCoordinator()
        #expect(coordinator.isInReconnectionCycle() == false)
        coordinator.recordAttemptStarted()
        #expect(coordinator.isInReconnectionCycle())
        coordinator.recordConnectionEstablished()
        #expect(coordinator.isInReconnectionCycle() == false)
    }
}
