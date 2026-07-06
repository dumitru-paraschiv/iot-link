//
//  Collection+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

public extension Collection {
    
    @inline(__always)
    nonisolated var isNotEmpty: Bool {
        !isEmpty
    }
}
