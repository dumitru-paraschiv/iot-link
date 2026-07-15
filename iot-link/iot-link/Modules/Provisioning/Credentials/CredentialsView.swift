//
//  CredentialsView.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine

enum CredentialsViewSteps {
    
    case provisioned(ProvisioningStatus)
    case failed
    case cancelled
}

protocol CredentialsViewOutput: AnyObject {
    
    var steps: PassthroughSubject<CredentialsViewSteps, Never> { get }
}

enum CredentialsViewAction {
    
    case viewWillAppear
    case viewWillDisappear
    case ssidChanged(String)
    case passwordChanged(String)
    case togglePasswordReveal
    case submitTapped
    case cancelTapped
}

protocol CredentialsViewInput {
    
    func bind(output: CredentialsViewOutput)
    func send(_ action: CredentialsViewAction)
}

protocol CredentialsView: Presentable, CredentialsViewOutput {
    
    var viewModel: CredentialsViewInput! { get set }
}
