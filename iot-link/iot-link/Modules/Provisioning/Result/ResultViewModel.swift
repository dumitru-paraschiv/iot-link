//
//  ResultViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import Observation

@MainActor
@Observable
final class ResultViewModel {
    
    private(set) var model: ResultModel
    
    private weak var output: ResultViewOutput?
    
    /// How long the success screen lingers before the flow auto-dismisses.
    private let successDismissDelay: Duration = .milliseconds(1500)
    
    init(model: ResultModel) {
        self.model = model
    }
    
    func send(_ action: ResultViewAction) {
        switch action {
        case .viewDidLoad: handleViewDidLoad()
        case .retryTapped: handleRetry()
        case .cancelTapped: output?.steps.send(.cancel)
        }
    }
}

private extension ResultViewModel {
    
    func handleViewDidLoad() {
        guard model.isSuccess else { return }
        
        // Success needs no interaction - let the checkmark land, then finish.
        Task { [weak self, successDismissDelay] in
            try? await Task.sleep(for: successDismissDelay)
            self?.output?.steps.send(.done)
        }
    }
    
    func handleRetry() {
        guard let recovery = model.recovery else { return }
        
        output?.steps.send(.retry(recovery))
    }
}

extension ResultViewModel: ResultViewInput {
    
    func bind(output: any ResultViewOutput) {
        self.output = output
    }
}
