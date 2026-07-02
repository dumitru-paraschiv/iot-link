//
//  AnyFactory.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

protocol AnyFactory {
    
    var r: MainResolver { get }
}

class BaseFactory: AnyFactory {
    
    let r: MainResolver
    
    init(r: MainResolver) {
        self.r = r
    }
}
