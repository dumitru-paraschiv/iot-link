//
//  ReconnectionPolicyTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("ReconnectionPolicy back-off")
struct ReconnectionPolicyTests {

    /// Jitter pinned to a fixed value makes the curve fully deterministic.
    private static let jitter = 0.25

    private let policy = ReconnectionPolicy(
        baseDelay: .seconds(2),
        maxAttempts: 5,
        jitter: { Self.jitter }
    )

    @Test("follows baseDelay × 2ⁿ plus jitter", arguments: [
        (0, 2), (1, 4), (2, 8), (3, 16), (4, 32)
    ])
    func delayCurve(attempt: Int, scaledSeconds: Int) {
        let expected = Duration.seconds(scaledSeconds) + .seconds(Self.jitter)
        #expect(policy.delay(forAttempt: attempt) == expected)
    }

    @Test("clamps negative attempt indices to the first attempt")
    func negativeAttempt() {
        #expect(policy.delay(forAttempt: -3) == policy.delay(forAttempt: 0))
    }

    @Test("permits attempts strictly under the budget")
    func budgetBoundary() {
        #expect(policy.allowsAttempt(0))
        #expect(policy.allowsAttempt(4))     // maxAttempts − 1: last allowed
        #expect(!policy.allowsAttempt(5))    // maxAttempts: refused
    }
}
