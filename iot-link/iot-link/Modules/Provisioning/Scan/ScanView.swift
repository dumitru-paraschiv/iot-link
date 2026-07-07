//
//  ScanView.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import Foundation

enum ScanViewSteps {
    
    case connected
    case cancelled
}

protocol ScanViewOutput: AnyObject {
    
    var steps: PassthroughSubject<ScanViewSteps, Never> { get }
}

enum ScanViewAction {
    
    case viewDidLoad
    case viewWillAppear
    case viewWillDisappear
    case deviceTapped(id: UUID)
}

protocol ScanViewInput {
    
    func bind(output: ScanViewOutput)
    func send(_ action: ScanViewAction)
}

protocol ScanView: Presentable, ScanViewOutput {
    
    var viewModel: ScanViewInput! { get set }
}
