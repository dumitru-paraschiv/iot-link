//
//  AppFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import UIKit

protocol AppFlow: WindowFlow {
    
}

final class DefaultAppFlow: WindowFlow, AppFlow, FlowFactory, ModuleFactory {
    
    private let accountService: AccountService
    
    init(r: MainResolver, window: UIWindow, accountService: AccountService) {
        self.accountService = accountService
        super.init(r: r, window: window)
    }
    
    override func start() {
        Task { @MainActor in
            guard await accountService.isOnboarded else {
                showOnboarding()
                return
            }
            
            showMainFlow()
        }
    }
}

private extension DefaultAppFlow {
    
    func showOnboarding() {
        let onboardingNavigationController = UINavigationController()
        onboardingNavigationController.title = "OnboardingNavigationController"
        let onboardingFlow = makeOnboardingFlow(navigationController: onboardingNavigationController)
        onboardingFlow.steps.sink { [weak self] in
            switch $0 {
            case .finished: self?.showMainFlow()
            }
        }
        .store(in: &onboardingFlow.stepsBag)
        setRoot(onboardingFlow)
    }
    
    func showMainFlow() {
        let mainTabBarController = UITabBarController()
        mainTabBarController.title = "MainTabBarController"
        let mainflow = makeMainFlow(tabBarController: mainTabBarController)
        mainflow.steps.sink { [weak self] in
            switch $0 {
                
            }
        }
        .store(in: &mainflow.stepsBag)
        setRoot(mainflow)
    }
}
