//
//  ResultView.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine

enum ResultViewSteps {
    
    /// A device was provisioned - finish the flow (keeping the connection).
    case done
    /// The user wants to retry after a failure; the recovery target says where to resume.
    case retry(ResultModel.Recovery)
    /// The user abandoned provisioning after a failure.
    case cancel
}

protocol ResultViewOutput: AnyObject {
    
    var steps: PassthroughSubject<ResultViewSteps, Never> { get }
}

enum ResultViewAction {
    
    case viewDidLoad
    case retryTapped
    case cancelTapped
}

protocol ResultViewInput {
    
    func bind(output: ResultViewOutput)
    func send(_ action: ResultViewAction)
}

protocol ResultView: Presentable, ResultViewOutput {
    
    var viewModel: ResultViewInput! { get set }
}
