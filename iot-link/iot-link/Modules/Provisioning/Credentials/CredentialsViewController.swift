//
//  CredentialsViewController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import SwiftUI

final class CredentialsViewController: BaseHostingController<CredentialsViewUI>, CredentialsView {
    
    let steps = PassthroughSubject<CredentialsViewSteps, Never>()
    var viewModel: CredentialsViewInput!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.send(.viewWillAppear)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.send(.viewWillDisappear)
    }
    
    override func setupNavigation() {
        super.setupNavigation()
        navigationItem.title = "Wi-Fi Setup"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(handleCancelTapped)
        )
    }
    
    @objc private func handleCancelTapped() {
        viewModel.send(.cancelTapped)
    }
}

struct CredentialsViewUI: View {
    
    var viewModel: CredentialsViewModel
    
    private var ssidBinding: Binding<String> {
        Binding(
            get: { viewModel.model.ssid },
            set: { viewModel.send(.ssidChanged($0)) }
        )
    }
    
    private var passwordBinding: Binding<String> {
        Binding(
            get: { viewModel.model.password },
            set: { viewModel.send(.passwordChanged($0)) }
        )
    }
    
    var body: some View {
        VStack(spacing: 32) {
            ProvisioningViewComponents.CredentialsHeader()
            
            VStack(spacing: 4) {
                ProvisioningViewComponents.CredentialField(
                    title: "Network Name",
                    placeholder: "SSID",
                    text: ssidBinding,
                    byteCount: viewModel.model.ssidByteCount,
                    maxBytes: viewModel.model.maxSSIDLength,
                    isOverLimit: viewModel.model.isSSIDOverLimit
                )
                
                ProvisioningViewComponents.PasswordField(
                    text: passwordBinding,
                    isRevealed: viewModel.model.isPasswordRevealed,
                    byteCount: viewModel.model.passwordByteCount,
                    maxBytes: viewModel.model.maxPasswordLength,
                    isOverLimit: viewModel.model.isPasswordOverLimit,
                    onToggleReveal: { viewModel.send(.togglePasswordReveal) }
                )
            }
            
            ProvisioningViewComponents.SubmitButton(
                isSubmitting: viewModel.model.isSubmitting,
                isEnabled: viewModel.model.canSubmit,
                action: { viewModel.send(.submitTapped) }
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}
