//
//  SettingsFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import UIKit

enum SettingsFlowSteps {
    
}

protocol SettingsFlow: NavigationFlow {
    
    var steps: PassthroughSubject<SettingsFlowSteps, Never> { get }
}

final class DefaultSettingsFlow: NavigationFlow, SettingsFlow, ModuleFactory, FlowFactory {
    
    let steps = PassthroughSubject<SettingsFlowSteps, Never>()
    
    override func start() {
        showSettingsView(with: SettingsModel())
    }
}

private extension DefaultSettingsFlow {
    
    func showProvisioningFlow() {
        let provisioningNavigationController = UINavigationController()
        provisioningNavigationController.title = "ProvisioningNavigationController"
        let provisioningFlow = makeProvisioningFlow(
            navigationController: provisioningNavigationController,
            startMode: .scan
        )
        provisioningFlow.steps.sink { [weak self, weak provisioningFlow] in
            switch $0 {
            case .finished: provisioningFlow.flatMap { self?.dismiss($0) }
            }
        }
        .store(in: &provisioningFlow.stepsBag)
        present(provisioningFlow)
    }
    
    func showSettingsView(with model: SettingsModel) {
        let settingsView = makeSettingsView(with: model)
        settingsView.steps.sink { [weak self] in
            switch $0 {
            case .addDeviceTapped: self?.showProvisioningFlow()
            }
        }
        .store(in: &settingsView.stepsBag)
        setRoot(settingsView)
    }
}
