//
//  FlowAssembly.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Swinject

final class FlowAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(AppFlow.self) { r, window in
            let flow = DefaultAppFlow(
                r: MainResolver(r),
                window: window,
                accountService: MainResolver(r).resolve()
            )
            #if DEBUG
            trackDeallocation(for: flow)
            #endif
            return flow
        }
        .inObjectScope(.weak)
        
        container.register(OnboardingFlow.self) { r, navigationController in
            let flow = DefaultOnboardingFlow(r: MainResolver(r), controller: navigationController)
            #if DEBUG
            trackDeallocation(for: flow)
            #endif
            return flow
        }
        
        container.register(MainFlow.self) { r, tabBarController in
            let flow = DefaultMainFlow(r: MainResolver(r), controller: tabBarController)
            #if DEBUG
            trackDeallocation(for: flow)
            #endif
            return flow
        }
        
        container.register(HomeFlow.self) { r, navigationController in
            let flow = DefaultHomeFlow(r: MainResolver(r), controller: navigationController)
            #if DEBUG
            trackDeallocation(for: flow)
            #endif
            return flow
        }
        
        container.register(SettingsFlow.self) { r, navigationController in
            let flow = DefaultSettingsFlow(r: MainResolver(r), controller: navigationController)
            #if DEBUG
            trackDeallocation(for: flow)
            #endif
            return flow
        }
    }
}
