//
//  ResultModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

struct ResultModel {
    
    let outcome: Outcome
    
    init(outcome: Outcome) {
        self.outcome = outcome
    }
    
    enum Outcome: Equatable {
        
        case success
        case failure(reason: String, recovery: Recovery)
    }
    
    /// Where "Try Again" should return, based on whether the device is still reachable.
    enum Recovery: Equatable {
        
        /// The device rejected the credentials but is still connected - retry at the form.
        case reenterCredentials
        /// The device is gone (timeout / disconnect) - retry by re-scanning.
        case rescan
    }
}

// MARK: Extensions

extension ResultModel {
    
    static let builder = ResultModelBuilder.self
    
    var isSuccess: Bool {
        outcome == .success
    }
    
    /// The recovery target for a failure outcome; `nil` on success.
    var recovery: Recovery? {
        switch outcome {
        case .success: nil
        case let .failure(_, recovery): recovery
        }
    }
}

// MARK: Builder

enum ResultModelBuilder {
    
    /// Maps a decoded peripheral status to a user-facing outcome. A status means the device
    /// answered, so credential failures are recoverable at the form.
    static func makeOutcome(from status: ProvisioningStatus) -> ResultModel.Outcome {
        switch status {
        case .success: .success
        case .invalidPayload: .failure(
            reason: "The network details were rejected. Please check and try again.",
            recovery: .reenterCredentials
        )
        case .authFailure: .failure(
            reason: "The device could not authenticate with the network.",
            recovery: .reenterCredentials
        )
        case .wifiTimeout: .failure(
            reason: "The device timed out connecting to the network.",
            recovery: .reenterCredentials
        )
        }
    }
    
    /// Outcome for a provisioning attempt that never produced a peripheral status (write
    /// timeout, link failure, disconnect). The device is unreachable, so recovery means
    /// re-scanning rather than re-entering credentials against a dead link.
    static func makeUnreachableFailureOutcome() -> ResultModel.Outcome {
        .failure(reason: "Couldn't reach the device. Move closer and try again.",
                 recovery: .rescan)
    }
}
