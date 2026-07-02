//
//  OnboardingView.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine

enum OnboardingViewSteps {
    
    case finished
}

protocol OnboardingViewOutput: AnyObject {
    
    var steps: PassthroughSubject<OnboardingViewSteps, Never> { get }
}

enum OnboardingViewAction {
    
    case completeOnboardingTapped
    case viewDidLoad
}

protocol OnboardingViewInput {
    
    func bind(output: OnboardingViewOutput)
    func send(_ action: OnboardingViewAction)
}

protocol OnboardingView: Presentable, OnboardingViewOutput {
    
    var viewModel: OnboardingViewInput! { get set }
}
