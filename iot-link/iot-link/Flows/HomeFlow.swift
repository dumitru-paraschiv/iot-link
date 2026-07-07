//
//  HomeFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import UIKit

enum HomeFlowSteps {
    
}

protocol HomeFlow: NavigationFlow {
    
    var steps: PassthroughSubject<HomeFlowSteps, Never> { get }
}

final class DefaultHomeFlow: NavigationFlow, HomeFlow, ModuleFactory, FlowFactory {
    
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
            case .addDeviceTapped: self?.showProvisioningFlow()
            }
        }
        .store(in: &homeView.stepsBag)
        setRoot(homeView)
    }
    
    func showProvisioningFlow() {
        let provisioningNavigationController = UINavigationController()
        provisioningNavigationController.title = "ProvisioningNavigationController"
        let provisioningFlow = makeProvisioningFlow(navigationController: provisioningNavigationController)
        provisioningFlow.steps.sink { [weak self, weak provisioningFlow] in
            switch $0 {
            case let .finished(provisioned): provisioningFlow.flatMap { self?.dismiss($0) }
            }
        }
        .store(in: &provisioningFlow.stepsBag)
        present(provisioningFlow)
    }
}
