//
//  TabBarControllerDelegate.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

protocol TabBarControllerDelegate: NSObject, UITabBarControllerDelegate {
    
    var didDoubleTapTab: Callback<Int>? { get set }
}

final class DefaultTabBarControllerDelegate: NSObject, TabBarControllerDelegate {
    
    var didDoubleTapTab: Callback<Int>?
    
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController === viewController {
            if let index = tabBarController.viewControllers?.firstIndex(of: viewController) {
                didDoubleTapTab?(index)
            }
        }
        return true
    }
}
