//
//  App.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

@main
final class App: AppDelegate {
    
    private let resolver: MainResolver
    
    override init() {
        resolver = MainResolver(DIContainer.main.container)
        super.init()
        services = [
            
        ]
    }
}
