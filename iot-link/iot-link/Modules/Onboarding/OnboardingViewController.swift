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
    
    override var prefersNavigationBarHidden: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.send(.viewDidLoad)
    }
}

struct OnboardingViewUI: View {
    
    var viewModel: OnboardingViewModel
    
    private var currentPageIndexBinding: Binding<Int> {
        Binding(
            get: { viewModel.model.currentPageIndex },
            set: { viewModel.send(.set(currentPageIndex: $0)) }
        )
    }
    
    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: currentPageIndexBinding) {
                ForEach(viewModel.model.pages) { page in
                    OnboardingViewComponents.PageCard(page: page)
                        .frame(minHeight: .zero, maxHeight: .infinity)
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: viewModel.model.currentPageIndex)
            
            OnboardingViewComponents.PageIndicator(
                pages: viewModel.model.pages,
                currentPageIndex: viewModel.model.currentPageIndex
            )
            
            OnboardingViewComponents.ActionButton(
                isLastPage: viewModel.model.isLastPage,
                tapAction: { viewModel.send(.nextPageTapped) }
            )
            .padding(.horizontal, 48)
        }
        .padding(.bottom, 64)
        .overlay(alignment: .topTrailing) {
            OnboardingViewComponents.DismissButton(
                tapAction: { viewModel.send(.completeOnboardingTapped) }
            )
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
    }
}
