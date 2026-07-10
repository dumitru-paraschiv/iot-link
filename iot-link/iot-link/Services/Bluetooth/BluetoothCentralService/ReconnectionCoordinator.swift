//
//  ReconnectionCoordinator.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 10.07.2026.
//

import Foundation

/// Tracks the reconnection attempt budget against an injected `ReconnectionPolicy`.
///
/// Pure, synchronous state — no `Task` or CoreBluetooth call is made here. The owning
/// actor is responsible for all scheduling; this type only answers "what's the next delay"
/// and advances/resets the counter, so it stays testable without mocking BLE.
nonisolated struct ReconnectionCoordinator: Sendable {
    
    private var attempt = 0
    private let policy: ReconnectionPolicy
    
    init(policy: ReconnectionPolicy = ReconnectionPolicy()) {
        self.policy = policy
    }
    
    /// The delay before the next attempt, or `nil` if the attempt budget is exhausted.
    /// Does not mutate `attempt` — call `recordAttemptStarted()` once the attempt is
    /// actually made.
    func delayForNextAttempt() -> Duration? {
        guard policy.allowsAttempt(attempt) else { return nil }
        return policy.delay(forAttempt: attempt)
    }
    
    /// Advances the attempt counter. Call once per actual `connect(_:)` call.
    mutating func recordAttemptStarted() {
        attempt += 1
    }
    
    /// Resets the attempt budget. Called on a fully established connection, and by the
    /// actor's own fresh-connect / terminal-disconnect paths.
    mutating func recordConnectionEstablished() {
        attempt = 0
    }
    
    /// Whether we are currently in a reconnection cycle (i.e., at least one reconnection
    /// attempt has been recorded since the last successful connection).
    func isInReconnectionCycle() -> Bool {
        attempt > 0
    }
}
