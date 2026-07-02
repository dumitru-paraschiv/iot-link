//
//  SettingsView.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine

enum SettingsViewSteps {
    
}

protocol SettingsViewOutput: AnyObject {
    
    var steps: PassthroughSubject<SettingsViewSteps, Never> { get }
}

enum SettingsViewAction {
    
    case viewDidLoad
}

protocol SettingsViewInput {
    
    func bind(output: SettingsViewOutput)
    func send(_ action: SettingsViewAction)
}

protocol SettingsView: Presentable, SettingsViewOutput {
    
    var viewModel: SettingsViewInput! { get set }
}
