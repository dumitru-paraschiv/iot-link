//
//  WindowFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

@MainActor
class WindowFlow: Flow, AnyFactory {
    
    var childFlows = [Flow]()
    weak var parentFlow: Flow?
    let window: UIWindow
    let r: MainResolver
    
    init(r: MainResolver, window: UIWindow) {
        self.r = r
        self.window = window
    }
    
    var firstViewController: UIViewController? { window.rootViewController }
    var lastViewController: UIViewController? { window.rootViewController }
    
    func toPresent() -> UIViewController {
        fatalError("WindowFlow is the absolute root and cannot be presented.")
    }
    
    func start() {
        // Default implementation does nothing
        // Subclasses should override to provide custom behavior
    }
    
    func setRoot(_ flow: Flow, animated: Bool = true) {
        removeAllChildren()
        addChild(flow)
        
        let viewController = flow.toPresent()
        
        // Elegant cross-dissolve transition between app states
        if animated && window.rootViewController.isSome {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.window.rootViewController = viewController
            }, completion: nil)
        } else {
            window.rootViewController = viewController
        }
        
        if window.isKeyWindow.isFalse {
            window.makeKeyAndVisible()
        }
    }
}
