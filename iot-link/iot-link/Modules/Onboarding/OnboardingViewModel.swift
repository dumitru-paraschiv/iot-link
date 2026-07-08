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
    
    var model: OnboardingModel
    
    private weak var output: OnboardingViewOutput?
    private let accountService: AccountService
    
    init(accountService: AccountService,
         model: OnboardingModel) {
        self.accountService = accountService
        self.model = model
    }
    
    func send(_ action: OnboardingViewAction) {
        switch action {
        case .completeOnboardingTapped: handleCompleteOnboardingTapped()
        case .nextPageTapped: handleNextPageTapped()
        case let .set(currentPageIndex): model.set(currentPageIndex: currentPageIndex)
        case .viewDidLoad: break
        }
    }
}

private extension OnboardingViewModel {
    
    func handleNextPageTapped() {
        if model.isLastPage {
            handleCompleteOnboardingTapped()
        } else {
            let nextPageIndex = model.currentPageIndex + 1
            model.set(currentPageIndex: nextPageIndex)
        }
    }
    
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
