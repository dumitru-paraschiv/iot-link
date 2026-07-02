//
//  HomeFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine

enum HomeFlowSteps {
    
}

protocol HomeFlow: NavigationFlow {
    
    var steps: PassthroughSubject<HomeFlowSteps, Never> { get }
}

final class DefaultHomeFlow: NavigationFlow, HomeFlow, ModuleFactory {
    
    let steps = PassthroughSubject<HomeFlowSteps, Never>()
    
    override func start() {
        showHomeView(with: HomeModel())
    }
}

private extension DefaultHomeFlow {
    
    func showHomeView(with model: HomeModel) {
        let homeView = makeHomeView(with: model)
        homeView.steps.sink { [weak self] in
            switch $0 {
                
            }
        }
        .store(in: &homeView.stepsBag)
        setRoot(homeView)
    }
}
