//
//  MainFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import UIKit

enum MainFlowSteps {
    
}

protocol MainFlow: TabBarFlow {
    
    var steps: PassthroughSubject<MainFlowSteps, Never> { get }
}

final class DefaultMainFlow: TabBarFlow, MainFlow, FlowFactory {
    
    let steps = PassthroughSubject<MainFlowSteps, Never>()
    
    override func start() {
        let homeNavigationController = UINavigationController()
        homeNavigationController.title = "HomeNavigationController"
        let homeFlow = makeHomeFlow(navigationController: homeNavigationController)
        let homeTabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        homeFlow.toPresent().tabBarItem = homeTabBarItem
        homeFlow.steps.sink { [weak self] in
            switch $0 {
                
            }
        }
        .store(in: &homeFlow.stepsBag)
        
        let settingsNavigationController = UINavigationController()
        settingsNavigationController.title = "SettingsNavigationController"
        let settingsFlow = makeSettingsFlow(navigationController: settingsNavigationController)
        let settingsTabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 1)
        settingsFlow.toPresent().tabBarItem = settingsTabBarItem
        settingsFlow.steps.sink { [weak self] in
            switch $0 {
            
            }
        }
        .store(in: &settingsFlow.stepsBag)
        
        set(tabs: [homeFlow, settingsFlow])
    }
}
