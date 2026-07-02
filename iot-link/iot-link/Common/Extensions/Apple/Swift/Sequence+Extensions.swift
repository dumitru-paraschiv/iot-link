//
//  Sequence+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

public extension Sequence {
    
    func unique(_ comparator: (Element, Element) -> Bool) -> [Element] {
        reduce([]) { result, element in
            result.contains { comparator($0, element) } ? result : result + [element]
        }
    }
    
    func unique<Key: Equatable>(by keyPath: (Element) -> Key) -> [Element] {
        unique { keyPath($0) == keyPath($1) }
    }
}

public extension Sequence where Element: Equatable {
    
    @inline(__always)
    func notContains(_ element: Element) -> Bool {
        !contains(element)
    }
}
