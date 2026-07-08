//
//  HomeView.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine

enum HomeViewSteps {
    
    case addDeviceTapped
    case setUpWiFiTapped
}

protocol HomeViewOutput: AnyObject {
    
    var steps: PassthroughSubject<HomeViewSteps, Never> { get }
}

enum HomeViewAction {
    
    case viewDidLoad
    case addDeviceTapped
    case setUpWiFiTapped
    case ledToggled(Bool)
    case disconnectTapped
}

protocol HomeViewInput {
    
    func bind(output: HomeViewOutput)
    func send(_ action: HomeViewAction)
}

protocol HomeView: Presentable, HomeViewOutput {
    
    var viewModel: HomeViewInput! { get set }
}
