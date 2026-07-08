//
//  NavigationControllerDelegate.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

protocol NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    
    var didShowViewController: Callback<UIViewController>? { get set }
}

final class DefaultNavigationControllerDelegate: NSObject, NavigationControllerDelegate {
    
    var didShowViewController: Callback<UIViewController>?
    
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        didShowViewController?(viewController)
    }
}
