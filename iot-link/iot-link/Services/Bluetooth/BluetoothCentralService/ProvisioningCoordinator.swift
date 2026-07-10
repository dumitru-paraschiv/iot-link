//
//  ProvisioningCoordinator.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 10.07.2026.
//

import Foundation

/// Owns the provisioning handshake's continuation, guaranteeing it resumes exactly once.
///
/// A late status notification can race an already-fired timeout (or vice versa); both call
/// `finish(with:)`, and only the first actually resumes anything. Pure, synchronous state —
/// the owning actor is responsible for the write, the timeout `Task`, and interpreting the
/// notification byte.
nonisolated struct ProvisioningCoordinator: Sendable {
    
    private var continuation: CheckedContinuation<ProvisioningStatus, Error>?
    
    /// Whether a handshake is currently awaiting a result.
    var isInFlight: Bool {
        continuation != nil
    }
    
    /// Registers the continuation to resume when the handshake concludes.
    mutating func begin(_ continuation: CheckedContinuation<ProvisioningStatus, Error>) {
        self.continuation = continuation
    }
    
    /// Resumes the in-flight continuation exactly once.
    ///
    /// - Returns: `true` if a continuation was resumed, `false` on a spurious call (e.g. a
    ///   late notification racing an already-fired timeout) — a no-op, not an error.
    @discardableResult
    mutating func finish(with result: Result<ProvisioningStatus, Error>) -> Bool {
        guard let continuation else { return false }
        self.continuation = nil
        continuation.resume(with: result)
        return true
    }
}
