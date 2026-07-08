//
//  String+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

public extension String {
    
    @inline(__always)
    static var space: String { " " }
    
    @inline(__always)
    var wrappedIntoBrackets: String { "[\(self)]" }
}

import Foundation

public extension String {
    
    @inline(__always)
    var nsString: NSString {
        self as NSString
    }
}
