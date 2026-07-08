//
//  TabBarFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

class TabBarFlow: BaseFlow<UITabBarController> {
    
    private var tabFlows = [Flow]()
    private var tabBarDelegate: TabBarControllerDelegate?
    
    override init(r: MainResolver, controller: UITabBarController) {
        super.init(r: r, controller: controller)
        setupTabBarDelegate(controller: controller)
    }
    
    func set(tabs: [Flow]) {
        tabFlows.forEach { removeChild($0) }
        tabFlows.removeAll()
        
        tabs.forEach {
            addChild($0)
            tabFlows.append($0)
        }
        
        let viewControllers = tabs.map { $0.toPresent() }
        controller.setViewControllers(viewControllers, animated: false)
    }
    
    func selectTab(at index: Int) {
        guard index >= 0 && index < tabFlows.count else { return }
        controller.selectedIndex = index
    }
}

// MARK: - TabBar Tracking & Interactions

private extension TabBarFlow {
    
    func setupTabBarDelegate(controller: UITabBarController) {
        if controller.delegate == nil {
            tabBarDelegate = DefaultTabBarControllerDelegate()
            tabBarDelegate?.didDoubleTapTab = { [weak self] index in
                self?.handleDoubleTap(at: index)
            }
            controller.delegate = tabBarDelegate
        } else if let delegate = controller.delegate as? TabBarControllerDelegate {
            let existingDidDoubleTap = delegate.didDoubleTapTab
            delegate.didDoubleTapTab = { [weak self] index in
                self?.handleDoubleTap(at: index)
                existingDidDoubleTap?(index)
            }
            tabBarDelegate = delegate
        }
    }
    
    func handleDoubleTap(at index: Int) {
        guard index >= 0 && index < tabFlows.count else { return }
        
        if let navigationFlow = tabFlows[index] as? NavigationFlow {
            navigationFlow.popToRoot(animated: true)
        }
    }
}
