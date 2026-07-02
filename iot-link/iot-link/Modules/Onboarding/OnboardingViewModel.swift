//
//  OnboardingViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    
    private(set) var model: OnboardingModel
    
    private weak var output: OnboardingViewOutput?
    private let accountService: AccountService
    
    init(accountService: AccountService,
         model: OnboardingModel) {
        self.accountService = accountService
        self.model = model
    }
    
    func send(_ action: OnboardingViewAction) {
        switch action {
        case .viewDidLoad: break
        case .completeOnboardingTapped: handleCompleteOnboardingTapped()
        }
    }
}

private extension OnboardingViewModel {
    
    func handleCompleteOnboardingTapped() {
        Task { @MainActor in
            await accountService.completeOnboarding()
            if await accountService.isOnboarded {
                output?.steps.send(.finished)
            }
        }
    }
}

extension OnboardingViewModel: OnboardingViewInput {
    
    func bind(output: any OnboardingViewOutput) {
        self.output = output
    }
}
