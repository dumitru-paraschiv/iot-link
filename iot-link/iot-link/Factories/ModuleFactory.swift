//
//  ModuleFactory.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Foundation

protocol ModuleFactory {
    
    func makeOnboardingView(with model: OnboardingModel) -> OnboardingView
    func makeHomeView(with model: HomeModel) -> HomeView
    func makeScanView(with model: ScanModel) -> ScanView
    func makeSettingsView(with model: SettingsModel) -> SettingsView
}

extension ModuleFactory where Self: AnyFactory {
    
    func makeOnboardingView(with model: OnboardingModel) -> OnboardingView {
        r.resolve(with: model)
    }
    
    func makeHomeView(with model: HomeModel) -> HomeView {
        r.resolve(with: model)
    }
    
    func makeScanView(with model: ScanModel) -> ScanView {
        r.resolve(with: model)
    }
    
    func makeSettingsView(with model: SettingsModel) -> SettingsView {
        r.resolve(with: model)
    }
}

final class DefaultModuleFactory: BaseFactory, ModuleFactory {}
