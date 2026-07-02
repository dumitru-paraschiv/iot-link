//
//  OnboardingViewController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import SwiftUI

final class OnboardingViewController: BaseHostingController<OnboardingViewUI>, OnboardingView {
    
    let steps = PassthroughSubject<OnboardingViewSteps, Never>()
    var viewModel: OnboardingViewInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.send(.viewDidLoad)
    }
}

struct OnboardingViewUI: View {
    
    var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to the App!")
                .font(.largeTitle)
            
            Button("Complete Onboarding") {
                viewModel.send(.completeOnboardingTapped)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}
