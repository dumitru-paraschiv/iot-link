//
//  DeallocationTracker.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Foundation

final class DeallocationTracker {
    
    private let onDeinit: @Sendable () -> Void
    
    init(onDeinit: @escaping @Sendable () -> Void) {
        self.onDeinit = onDeinit
    }
    
    deinit {
        onDeinit()
    }
}

#if DEBUG
private struct LifecycleTrackerKeys {
    
    static nonisolated(unsafe) var deallocationKey: UInt8 = 0
}

public func trackDeallocation(for object: AnyObject) {
    let typeName = String(describing: type(of: object))
    let tracker = DeallocationTracker {
        trace("ℹ \(typeName) deallocated")
    }
    objc_setAssociatedObject(object, 
                             &LifecycleTrackerKeys.deallocationKey, 
                             tracker, 
                             .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}
#endif
