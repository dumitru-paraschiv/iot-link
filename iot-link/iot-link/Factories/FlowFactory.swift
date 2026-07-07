//
//  FlowFactory.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

protocol FlowFactory {
    
    func makeOnboardingFlow(navigationController: UINavigationController) -> OnboardingFlow
    func makeMainFlow(tabBarController: UITabBarController) -> MainFlow
    func makeHomeFlow(navigationController: UINavigationController) -> HomeFlow
    func makeProvisioningFlow(navigationController: UINavigationController,
                              startMode: ProvisioningStartMode) -> ProvisioningFlow
    func makeSettingsFlow(navigationController: UINavigationController) -> SettingsFlow
}

extension FlowFactory where Self: AnyFactory {
    
    func makeOnboardingFlow(navigationController: UINavigationController) -> OnboardingFlow {
        r.resolve(with: navigationController)
    }
    
    func makeMainFlow(tabBarController: UITabBarController) -> MainFlow {
        r.resolve(with: tabBarController)
    }
    
    func makeHomeFlow(navigationController: UINavigationController) -> HomeFlow {
        r.resolve(with: navigationController)
    }
    
    func makeProvisioningFlow(navigationController: UINavigationController,
                              startMode: ProvisioningStartMode) -> ProvisioningFlow {
        r.resolve(with: navigationController, startMode)
    }
    
    func makeSettingsFlow(navigationController: UINavigationController) -> SettingsFlow {
        r.resolve(with: navigationController)
    }
}

final class DefaultFlowFactory: BaseFactory, FlowFactory {}
