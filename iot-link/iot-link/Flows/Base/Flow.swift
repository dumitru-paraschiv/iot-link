//
//  Flow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

@MainActor
protocol Flow: AnyObject, Presentable {
    
    var childFlows: [Flow] { get set }
    var parentFlow: Flow? { get set }
    var firstViewController: UIViewController? { get }
    var lastViewController: UIViewController? { get }
    
    func start()
    func addChild(_ flow: Flow)
    func removeChild(_ flow: Flow)
    func removeAllChildren()
    func finish()
}

// MARK: - Default Implementations

extension Flow {
    
    func addChild(_ flow: Flow) {
        childFlows.append(flow)
        flow.parentFlow = self
        flow.start()
    }
    
    func removeChild(_ flow: Flow) {
        childFlows.removeAll { $0 === flow }
    }
    
    func removeAllChildren() {
        childFlows.forEach { $0.finish() }
        childFlows.removeAll()
    }
    
    func finish() {
        removeAllChildren()
        parentFlow?.removeChild(self)
    }
}
