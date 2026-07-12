//
//  CredentialsViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import Foundation
import Observation

@MainActor
@Observable
final class CredentialsViewModel {
    
    private(set) var model: CredentialsModel
    
    private weak var output: CredentialsViewOutput?
    private let bluetoothService: BluetoothCentralService
    private var cancellables = Set<AnyCancellable>()
    
    init(bluetoothService: BluetoothCentralService,
         model: CredentialsModel) {
        self.bluetoothService = bluetoothService
        self.model = model
    }
    
    func send(_ action: CredentialsViewAction) {
        switch action {
        case .viewWillAppear: handleViewWillAppear()
        case .viewWillDisappear: handleViewWillDisappear()
        case let .ssidChanged(ssid): model.accept(ssid: ssid)
        case let .passwordChanged(password): model.accept(password: password)
        case .togglePasswordReveal: model.accept(isPasswordRevealed: model.isPasswordRevealed.isFalse)
        case .submitTapped: handleSubmit()
        case .cancelTapped: output?.steps.send(.cancelled)
        }
    }
}

private extension CredentialsViewModel {
    
    func observeState() {
        bluetoothService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
}

private extension CredentialsViewModel {
    
    func handleViewWillAppear() {
        observeState()
    }
    
    func handleViewWillDisappear() {
        // Stop observing while this screen isn't on top so we don't misread an intentional
        // disconnect (e.g. the scan screen tearing down the link when the user pops back)
        // as a device drop. Observation resumes on the next appearance, including retry.
        cancellables.removeAll()
    }
    
    func handleStateChange(_ state: BluetoothState) {
        // A drop while the user is filling in the form (not mid-provision) leaves them on
        // a dead link. Surface it as a failure. An in-flight provision is already handled
        // by its own continuation failing, so skip while submitting to avoid a double step.
        if state == .disconnected, model.isSubmitting.isFalse {
            output?.steps.send(.failed)
        }
    }
    
    func handleSubmit() {
        guard model.canSubmit else { return }
        
        model.accept(isSubmitting: true)
        let credentials = model.credentials
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let status = try await bluetoothService.provision(credentials)
                model.accept(isSubmitting: false)
                output?.steps.send(.provisioned(status))
            } catch {
                model.accept(isSubmitting: false)
                output?.steps.send(.failed)
            }
        }
    }
}

extension CredentialsViewModel: CredentialsViewInput {
    
    func bind(output: any CredentialsViewOutput) {
        self.output = output
    }
}
