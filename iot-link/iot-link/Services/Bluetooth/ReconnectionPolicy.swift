//
//  ReconnectionPolicy.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 07.07.2026.
//

import Foundation

/// Exponential back-off schedule for reconnection attempts.
///
/// `Delay(n) = baseDelay × 2ⁿ + jitter`, where `n` is the zero-based attempt index. The
/// jitter is a small randomized offset that prevents multiple clients from reconnecting in
/// lock-step. It is injectable so unit tests can pin it to a fixed value, and `baseDelay`
/// defaults small enough to test the curve quickly.
nonisolated struct ReconnectionPolicy: Sendable {
    
    /// Delay of the first attempt (attempt index 0), before jitter.
    let baseDelay: Duration
    
    /// How many reconnection attempts to make before giving up.
    let maxAttempts: Int
    
    /// Produces the jitter (in seconds) added to each computed delay. Injected for
    /// deterministic tests; defaults to a random value in `0...0.5`.
    private let jitter: @Sendable () -> Double
    
    init(baseDelay: Duration = .seconds(2),
         maxAttempts: Int = 5,
         jitter: @escaping @Sendable () -> Double = { Double.random(in: 0 ... 0.5) }) {
        self.baseDelay = baseDelay
        self.maxAttempts = maxAttempts
        self.jitter = jitter
    }
    
    /// The back-off delay for a zero-based `attempt` index: `baseDelay × 2^attempt` plus
    /// jitter. Negative attempts are treated as `0`.
    func delay(forAttempt attempt: Int) -> Duration {
        let exponent = Swift.max(0, attempt)
        let scaled = baseDelay * Int(pow(2.0, Double(exponent)))
        return scaled + .seconds(jitter())
    }
    
    /// Whether another attempt is permitted for the given zero-based `attempt` index.
    func allowsAttempt(_ attempt: Int) -> Bool {
        attempt < maxAttempts
    }
}
