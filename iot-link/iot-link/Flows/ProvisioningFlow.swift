//
//  ProvisioningFlow.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import UIKit

enum ProvisioningFlowSteps {
    
    /// The flow is complete and should be dismissed by its presenter.
    /// `provisioned` is true when a device was successfully added.
    case finished(provisioned: Bool)
}

protocol ProvisioningFlow: NavigationFlow {
    
    var steps: PassthroughSubject<ProvisioningFlowSteps, Never> { get }
}

final class DefaultProvisioningFlow: NavigationFlow, ProvisioningFlow, ModuleFactory {
    
    let steps = PassthroughSubject<ProvisioningFlowSteps, Never>()
    
    private let bluetoothService: BluetoothCentralService
    
    init(r: MainResolver, controller: UINavigationController, bluetoothService: BluetoothCentralService) {
        self.bluetoothService = bluetoothService
        super.init(r: r, controller: controller)
    }
    
    override func start() {
        showScanView(with: ScanModel())
    }
}

private extension DefaultProvisioningFlow {
    
    func showScanView(with model: ScanModel) {
        let view = makeScanView(with: model)
        view.steps.sink { [weak self] in
            switch $0 {
            case .connected: self?.showCredentials()
            case .cancelled: self?.cancel()
            }
        }
        .store(in: &view.stepsBag)
        setRoot(view)
    }
    
    /// Placeholder until the credential form arrives in the next commit. For now,
    /// reaching the connected state is the end of this commit's flow.
    func showCredentials() {
        // C3: push the Wi-Fi credentials module here.
    }
    
    /// User abandoned provisioning — tear down the BLE connection and finish.
    func cancel() {
        Task { await bluetoothService.disconnect() }
        steps.send(.finished(provisioned: false))
    }
}
