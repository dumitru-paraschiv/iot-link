//
//  Presentable.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import UIKit

@MainActor
protocol Presentable: AnyObject {
    
    func toPresent() -> UIViewController
}

// MARK: - Steps Bag Association

private nonisolated(unsafe) var stepsBagAssociation = UInt8()

/// Wrapper class to hold Set<AnyCancellable> for associated objects
/// This avoids casting issues with Swift value types in Objective-C runtime
private final class CancellableBag {
    
    var cancellables = Set<AnyCancellable>()
}

extension Presentable {
    
    /// Storage for Combine subscriptions tied to this presentable's lifecycle
    /// Automatically cleaned up when the view controller is deallocated
    var stepsBag: Set<AnyCancellable> {
        get {
            let viewController = toPresent()
            if let wrapper = objc_getAssociatedObject(viewController, &stepsBagAssociation) as? CancellableBag {
                return wrapper.cancellables
            }
            let wrapper = CancellableBag()
            objc_setAssociatedObject(viewController, &stepsBagAssociation, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return wrapper.cancellables
        }
        set {
            let viewController = toPresent()
            if let wrapper = objc_getAssociatedObject(viewController, &stepsBagAssociation) as? CancellableBag {
                wrapper.cancellables = newValue
            } else {
                let wrapper = CancellableBag()
                wrapper.cancellables = newValue
                objc_setAssociatedObject(viewController, &stepsBagAssociation, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

// MARK: - UIViewController Conformance

extension UIViewController: Presentable {
    
    func toPresent() -> UIViewController {
        self
    }
}

// MARK: - Convenience Methods

extension Presentable {
    
    /// Store a cancellable in this presentable's steps bag
    /// The subscription will be automatically cancelled when the view controller is deallocated
    func store(_ cancellable: AnyCancellable) {
        var bag = stepsBag
        bag.insert(cancellable)
        stepsBag = bag
    }
}

#if DEBUG
// MARK: - Debugging Support

extension Presentable {
    
    /// Print the number of active subscriptions for this presentable
    func traceStepsBagInfo() {
        let count = stepsBag.count
        let type = String(describing: type(of: toPresent()))
        trace("📦 \(type) has \(count) active subscription(s)")
    }
}
#endif
