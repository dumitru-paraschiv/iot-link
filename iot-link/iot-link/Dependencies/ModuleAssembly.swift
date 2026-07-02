//
//  ModuleAssembly.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Swinject

final class ModuleAssembly: Assembly {
    
    func assemble(container: Container) {
        
        container.register(OnboardingView.self) { r, model in
            let viewModel = OnboardingViewModel(
                accountService: MainResolver(r).resolve(),
                model: model
            )
            let viewUI = OnboardingViewUI(viewModel: viewModel)
            let view = OnboardingViewController(rootView: viewUI)
            
            #if DEBUG
            trackDeallocation(for: viewModel)
            trackDeallocation(for: view)
            #endif
            
            viewModel.bind(output: view)
            view.viewModel = viewModel
            return view
        }
        
        container.register(HomeView.self) { r, model in
            let viewModel = HomeViewModel(model: model)
            let viewUI = HomeViewUI(viewModel: viewModel)
            let view = HomeViewController(rootView: viewUI)
            
            #if DEBUG
            trackDeallocation(for: viewModel)
            trackDeallocation(for: view)
            #endif
            
            viewModel.bind(output: view)
            view.viewModel = viewModel
            return view
        }
        
        container.register(SettingsView.self) { r, model in
            let viewModel = SettingsViewModel(model: model)
            let viewUI = SettingsViewUI(viewModel: viewModel)
            let view = SettingsViewController(rootView: viewUI)
            
            #if DEBUG
            trackDeallocation(for: viewModel)
            trackDeallocation(for: view)
            #endif
            
            viewModel.bind(output: view)
            view.viewModel = viewModel
            return view
        }
    }
}
