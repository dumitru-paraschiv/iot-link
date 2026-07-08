//
//  Array+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

public extension Array {
    
    func prepending(_ element: Element) -> Self {
        [element] + self
    }
}

public extension Array where Element: StringProtocol {
    
    func joined(_ separator: String) -> String {
        joined(separator: separator)
    }
}
