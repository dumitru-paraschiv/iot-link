//
//  SettingsFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine

enum SettingsFlowSteps {
    
}

protocol SettingsFlow: NavigationFlow {
    
    var steps: PassthroughSubject<SettingsFlowSteps, Never> { get }
}

final class DefaultSettingsFlow: NavigationFlow, SettingsFlow, ModuleFactory {
    
    let steps = PassthroughSubject<SettingsFlowSteps, Never>()
    
    override func start() {
        showSettingsView(with: SettingsModel())
    }
}

private extension DefaultSettingsFlow {
    
    func showSettingsView(with model: SettingsModel) {
        let settingsView = makeSettingsView(with: model)
        settingsView.steps.sink { [weak self] in
            switch $0 {
            
            }
        }
        .store(in: &settingsView.stepsBag)
        setRoot(settingsView)
    }
}
