//
//  ResultViewController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import SwiftUI

final class ResultViewController: BaseHostingController<ResultViewUI>, ResultView {
    
    let steps = PassthroughSubject<ResultViewSteps, Never>()
    var viewModel: ResultViewInput!
    
    override var prefersNavigationBarHidden: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.send(.viewDidLoad)
    }
}

struct ResultViewUI: View {
    
    var viewModel: ResultViewModel
    
    var body: some View {
        switch viewModel.model.outcome {
        case .success:
            ProvisioningViewComponents.SuccessResult()
        case let .failure(reason, _):
            ProvisioningViewComponents.FailureResult(
                reason: reason,
                onRetry: { viewModel.send(.retryTapped) },
                onCancel: { viewModel.send(.cancelTapped) }
            )
        }
    }
}
