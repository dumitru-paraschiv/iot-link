//
//  HomeViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import Observation

@MainActor
@Observable
final class HomeViewModel {
    
    private(set) var model: HomeModel
    
    private weak var output: HomeViewOutput?
    
    init(model: HomeModel) {
        self.model = model
    }
    
    func send(_ action: HomeViewAction) {
        switch action {
        case .viewDidLoad: break
        case .addDeviceTapped: output?.steps.send(.addDeviceTapped)
        }
    }
}

extension HomeViewModel: HomeViewInput {
    
    func bind(output: any HomeViewOutput) {
        self.output = output
    }
}
