//
//  Bool+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

public extension Bool {
    
    @inline(__always)
    nonisolated var isFalse: Bool {
        !self
    }
}
