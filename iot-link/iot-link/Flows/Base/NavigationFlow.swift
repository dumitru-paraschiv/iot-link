//
//  NavigationFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import UIKit

class NavigationFlow: BaseFlow<UINavigationController> {
    
    private var navigationDelegate: NavigationControllerDelegate?
    private var popCompletions = [ObjectIdentifier: EmptyCallback]()
    
    override var firstViewController: UIViewController? {
        controller.viewControllers.first
    }
    
    override var lastViewController: UIViewController? {
        controller.viewControllers.last
    }
    
    override init(r: MainResolver, controller: UINavigationController) {
        super.init(r: r, controller: controller)
        setupNavigationDelegate(controller: controller)
    }
    
    func setRoot(_ presentable: Presentable,
                 showTopBar: Bool = true) {
        controller.viewControllers.forEach {
            runPopCompletion($0)
        }
        controller.setNavigationBarHidden(showTopBar.isFalse, animated: false)
        controller.setViewControllers([presentable.toPresent()], animated: false)
    }
    
    func push(_ presentable: Presentable,
              animated: Bool = true,
              hideBottomBar: Bool = false,
              popCompletion: EmptyCallback? = nil) {
        let flow = presentable as? Flow
        let popCompletion = { [weak self, weak flow] in
            flow.flatMap { self?.removeChild($0) }
            popCompletion?()
        }
        if let flow {
            let oldViewControllers = controller.viewControllers
            addChild(flow)
            let newViewControllers = controller.viewControllers
            
            if let firstNewViewController = newViewControllers.first(where: { oldViewControllers.notContains($0) }) {
                savePopCompletion(firstNewViewController, popCompletion)
            }
        } else {
            let viewController = presentable.toPresent()
            viewController.hidesBottomBarWhenPushed = hideBottomBar
            savePopCompletion(viewController, popCompletion)
            controller.pushViewController(viewController, animated: animated)
        }
    }
    
    func pop(animated: Bool = true) {
        controller.popViewController(animated: animated).flatMap {
            runPopCompletion($0)
        }
    }
    
    func popToRoot(animated: Bool = true) {
        controller.popToRootViewController(animated: animated)?.forEach {
            runPopCompletion($0)
        }
    }
}

// MARK: - Navigation Tracking

private extension NavigationFlow {
    
    func setupNavigationDelegate(controller: UINavigationController) {
        if controller.delegate.isNone {
            navigationDelegate = DefaultNavigationControllerDelegate()
            navigationDelegate?.didShowViewController = { [weak self] in
                self?.didShowViewController($0)
            }
            controller.delegate = navigationDelegate
        } else if let delegate = controller.delegate as? NavigationControllerDelegate {
            let delegateDidShowViewController = delegate.didShowViewController
            delegate.didShowViewController = { [weak self] in
                self?.didShowViewController($0)
                delegateDidShowViewController?($0)
            }
        }
    }
    
    func didShowViewController(_ viewController: UIViewController) {
        let currentIdentifiers = Set(controller.viewControllers.map { ObjectIdentifier($0) })
        let droppedIdentifiers = popCompletions.keys.filter { currentIdentifiers.notContains($0) }
        
        for identifier in droppedIdentifiers {
            popCompletions.removeValue(forKey: identifier)?()
        }
    }
    
    func runPopCompletion(_ viewController: UIViewController) {
        popCompletions.removeValue(forKey: ObjectIdentifier(viewController))?()
    }
    
    func savePopCompletion(_ viewController: UIViewController, _ popCompletion: @escaping EmptyCallback) {
        popCompletions[ObjectIdentifier(viewController)] = popCompletion
    }
}
