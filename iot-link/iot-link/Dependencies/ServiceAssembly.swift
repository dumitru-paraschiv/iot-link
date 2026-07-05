//
//  ServiceAssembly.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Swinject

final class ServiceAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(AccountService.self) { r in
            DefaultAccountService()
        }
        .inObjectScope(.container)
        
        container.register(BluetoothCentralService.self) { r in
            DefaultBluetoothCentralService()
        }
        .inObjectScope(.container)
    }
}
