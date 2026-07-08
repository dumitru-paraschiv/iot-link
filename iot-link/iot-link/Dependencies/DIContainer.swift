//
//  DIContainer.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Swinject

final class DIContainer {
    
    static let main = DIContainer()
    
    let container: Container
    let resolver: MainResolver
    let assembler: Assembler
    
    private init() {
        container = Container()
        resolver = MainResolver(container)
        assembler = Assembler([
            FlowAssembly(),
            ModuleAssembly(),
            ServiceAssembly()
        ], container: container)
    }
}
