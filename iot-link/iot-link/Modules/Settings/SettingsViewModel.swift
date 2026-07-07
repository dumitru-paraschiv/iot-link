//
//  SettingsViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    
    private(set) var model: SettingsModel
    
    private weak var output: SettingsViewOutput?
    
    init(model: SettingsModel) {
        self.model = model
    }
    
    func send(_ action: SettingsViewAction) {
        switch action {
        case .viewDidLoad: break
        case .addDeviceTapped: output?.steps.send(.addDeviceTapped)
        }
    }
}

extension SettingsViewModel: SettingsViewInput {
    
    func bind(output: any SettingsViewOutput) {
        self.output = output
    }
}
