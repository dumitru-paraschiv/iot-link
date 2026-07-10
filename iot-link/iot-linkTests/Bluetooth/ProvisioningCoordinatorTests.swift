//
//  ProvisioningCoordinatorTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("ProvisioningCoordinator handshake")
struct ProvisioningCoordinatorTests {

    @Test("finish without begin is a no-op")
    func finishWithoutBeginIsNoOp() {
        var coordinator = ProvisioningCoordinator()
        #expect(coordinator.isInFlight == false)
        let resumed = coordinator.finish(with: .success(.success))
        #expect(resumed == false)
    }

    @Test("begin then finish resumes the continuation with the given result")
    func resumesWithResult() async throws {
        var coordinator = ProvisioningCoordinator()
        let status = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<iot_link.ProvisioningStatus, Error>) in
            coordinator.begin(continuation)
            #expect(coordinator.isInFlight)
            let resumed = coordinator.finish(with: .success(.success))
            #expect(resumed)
        }
        #expect(status == .success)
        #expect(coordinator.isInFlight == false)
    }

    @Test("a spurious second finish is a no-op")
    func secondFinishIsNoOp() async throws {
        var coordinator = ProvisioningCoordinator()
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<iot_link.ProvisioningStatus, Error>) in
            coordinator.begin(continuation)
            _ = coordinator.finish(with: .success(.success))
            let secondResume = coordinator.finish(with: .success(.invalidPayload))
            #expect(secondResume == false)
        }
    }

    @Test("propagates a failure result")
    func propagatesFailure() async {
        var coordinator = ProvisioningCoordinator()
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<iot_link.ProvisioningStatus, Error>) in
                coordinator.begin(continuation)
                _ = coordinator.finish(with: .failure(iot_link.ProvisioningError.timedOut))
            }
            Issue.record("expected ProvisioningError.timedOut to be thrown")
        } catch let error as iot_link.ProvisioningError {
            #expect(error == .timedOut)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
