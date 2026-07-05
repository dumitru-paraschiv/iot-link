//
//  UserDefaults+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 05.07.2026.
//

import Foundation

extension UserDefaults {
    
    enum Key: String {
        
        case isAppOnboarded
    }
    
    nonisolated func get<T>(forKey key: Key) -> T? {
        let object = object(forKey: key.rawValue) as? T
        trace("<\(key.rawValue)> = <\(object.flatMap(String.init(describing:)) ?? "nil")>", function: "get")
        return object
    }
    
    nonisolated func get<T>(_ type: T.Type, forKey key: Key) -> T? {
        let object = object(forKey: key.rawValue) as? T
        trace("<\(key.rawValue)> = <\(object.flatMap(String.init(describing:)) ?? "nil")>", function: "get")
        return object
    }
    
    nonisolated func set<T>(_ object: T?, forKey key: Key) {
        trace("<\(key.rawValue)> = <\(object.flatMap(String.init(describing:)) ?? "nil")>", function: "set")
        set(object, forKey: key.rawValue)
    }
    
    nonisolated func remove(forKey key: Key) {
        trace("<\(key.rawValue)> = <nil>", function: "remove")
        removeObject(forKey: key.rawValue)
    }
}
