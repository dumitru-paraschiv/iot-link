//
//  BaseFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

@MainActor
class BaseFlow<Controller: UIViewController>: Flow, AnyFactory {
    
    var childFlows = [Flow]()
    weak var parentFlow: Flow?
    let r: MainResolver
    
    private(set) var controller: Controller
    
    private var presentationDelegates = [ObjectIdentifier: PresentationControllerDelegate]()
    private var dismissCompletions = [ObjectIdentifier: EmptyCallback]()
    
    init(r: MainResolver, controller: Controller) {
        self.r = r
        self.controller = controller
    }
    
    // MARK: - Presentable
    
    func toPresent() -> UIViewController {
        controller
    }
    
    // MARK: - Flow
    
    var firstViewController: UIViewController? {
        nil
    }
    
    var lastViewController: UIViewController? {
        nil
    }
    
    func start() {
        // Default implementation does nothing
        // Subclasses should override to provide custom behavior
    }
    
    func present(_ presentable: Presentable,
                 embeddingNavigationFlow: NavigationFlow? = nil,
                 animated: Bool = true,
                 completion: EmptyCallback? = nil,
                 dismissCompletion: EmptyCallback? = nil) {
        embeddingNavigationFlow?.setRoot(presentable)
        
        let resolvedPresentable = embeddingNavigationFlow ?? presentable
        let viewController = resolvedPresentable.toPresent()
        
        if let flow = resolvedPresentable as? Flow {
            let dismissCompletion = { [weak self, weak flow] in
                flow.flatMap { self?.removeChild($0) }
                dismissCompletion?()
            }
            addChild(flow)
            saveDismissCompletion(viewController, dismissCompletion)
        } else {
            saveDismissCompletion(viewController, dismissCompletion)
        }
        
        // Setup delegate BEFORE presenting to ensure it's ready
        setupPresentationDelegate(for: viewController)
        
        controller.presenter.present(viewController, animated: animated) { [weak self] in
            // Ensure delegate is still set after presentation completes
            // (needed when animated: false, as the timing can be unpredictable)
            self?.setupPresentationDelegate(for: viewController)
            completion?()
        }
    }
    
    func dismiss(_ presentable: Presentable,
                 animated: Bool = true,
                 completion: EmptyCallback? = nil) {
        let presented = presentable.toPresent()
        
        guard presented.presentingViewController.isSome else {
            if let flow = presentable as? Flow {
                removeChild(flow)
            }
            runDismissCompletion(presented)
            completion?()
            return
        }
        
        guard presented.isBeingDismissed.isFalse else {
            completion?()
            return
        }
        
        if let flow = presentable as? Flow {
            removeChild(flow)
        }
        
        presented.dismiss(animated: animated) { [weak self] in
            self?.runDismissCompletion(presented)
            completion?()
        }
    }
    
    // MARK: - Lifecycle
}

// MARK: - Presentation Tracking

private struct AssociatedKeys {
    
    static nonisolated(unsafe) var deallocationTracker: UInt8 = 0
}

private extension BaseFlow {
    
    func setupPresentationDelegate(for viewController: UIViewController) {
        guard let presentationController = viewController.presentationController else { return }
        
        let identifier = ObjectIdentifier(viewController)
        
        if let existingDelegate = presentationDelegates[identifier] {
            presentationController.delegate = existingDelegate
            return
        }
        
        let delegate = DefaultPresentationControllerDelegate()
        delegate.didDismiss = { [weak self, weak viewController] in
            guard let viewController else { return }
            
            self?.runDismissCompletion(viewController)
        }
        
        presentationDelegates[identifier] = delegate
        presentationController.delegate = delegate
    }
    
    func runDismissCompletion(_ viewController: UIViewController) {
        let identifier = ObjectIdentifier(viewController)
        dismissCompletions.removeValue(forKey: identifier)?()
        presentationDelegates.removeValue(forKey: identifier)
    }
    
    func saveDismissCompletion(_ viewController: UIViewController, _ completion: EmptyCallback?) {
        guard let completion else { return }
        
        let identifier = ObjectIdentifier(viewController)
        dismissCompletions[identifier] = completion
        
        let tracker = DeallocationTracker { [weak self] in
            Task { @MainActor in
                self?.dismissCompletions.removeValue(forKey: identifier)?()
            }
        }
        
        objc_setAssociatedObject(viewController,
                                 &AssociatedKeys.deallocationTracker,
                                 tracker,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
