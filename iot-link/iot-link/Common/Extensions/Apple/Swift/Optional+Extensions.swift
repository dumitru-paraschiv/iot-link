//
//  Optional+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

public extension Optional {
    
    @inline(__always)
    var isNone: Bool {
        self == nil
    }
    
    @inline(__always)
    var isSome: Bool {
        self != nil
    }
}

public extension Optional where Wrapped: ExpressibleByBooleanLiteral {
    
    @inline(__always)
    var orFalse: Wrapped {
        self ?? false
    }
}

public extension Optional where Wrapped: ExpressibleByArrayLiteral {
    
    @inline(__always)
    var orEmpty: Wrapped {
        self ?? []
    }
}
