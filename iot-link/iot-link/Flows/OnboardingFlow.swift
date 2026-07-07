//
//  OnboardingFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine

enum OnboardingFlowSteps {
    
    case finished
}

protocol OnboardingFlow: NavigationFlow {
    
    var steps: PassthroughSubject<OnboardingFlowSteps, Never> { get }
}

final class DefaultOnboardingFlow: NavigationFlow, OnboardingFlow, ModuleFactory {
    
    let steps = PassthroughSubject<OnboardingFlowSteps, Never>()
    
    override func start() {
        showOnboardingView(with: OnboardingModel())
    }
}

private extension DefaultOnboardingFlow {
    
    func showOnboardingView(with model: OnboardingModel) {
        let view = makeOnboardingView(with: model)
        view.steps.sink { [weak self] in
            switch $0 {
            case .finished: self?.steps.send(.finished)
            }
        }
        .store(in: &view.stepsBag)
        setRoot(view)
    }
}
