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

/// Where the provisioning flow begins.
enum ProvisioningStartMode {
    
    /// Full journey from device discovery (the "Add Device" entry).
    case scan
    /// Skip discovery and configure Wi-Fi for the already-connected device (the dashboard
    /// "Set Up Wi-Fi" entry). Cancelling here keeps the connection.
    case credentials
}

protocol ProvisioningFlow: NavigationFlow {
    
    var steps: PassthroughSubject<ProvisioningFlowSteps, Never> { get }
    
    /// Called by the presenter when the sheet is dismissed via the interactive swipe
    /// gesture rather than one of the flow's own finish paths (Cancel button, success, or
    /// an unreachable-failure finish). A no-op if the flow already finished through one of
    /// those paths.
    func handleInteractiveDismiss()
}

final class DefaultProvisioningFlow: NavigationFlow, ProvisioningFlow, ModuleFactory {
    
    let steps = PassthroughSubject<ProvisioningFlowSteps, Never>()
    
    private let bluetoothService: BluetoothCentralService
    private let startMode: ProvisioningStartMode
    private var hasFinished = false
    
    init(r: MainResolver,
         controller: UINavigationController,
         bluetoothService: BluetoothCentralService,
         startMode: ProvisioningStartMode) {
        self.bluetoothService = bluetoothService
        self.startMode = startMode
        super.init(r: r, controller: controller)
    }
    
    override func start() {
        switch startMode {
        case .scan: showScanView(with: ScanModel())
        case .credentials: showCredentialsView(with: CredentialsModel(), asRoot: true)
        }
    }
    
    func handleInteractiveDismiss() {
        cancel()
    }
}

private extension DefaultProvisioningFlow {
    
    func showCredentialsView(with model: CredentialsModel, asRoot: Bool = false) {
        let view = makeCredentialsView(with: model)
        view.steps.sink { [weak self] in
            switch $0 {
            case let .provisioned(status):
                let outcome = ResultModel.builder.makeOutcome(from: status)
                self?.showResultView(with: ResultModel(outcome: outcome))
            case .failed:
                let outcome = ResultModel.builder.makeUnreachableFailureOutcome()
                self?.showResultView(with: ResultModel(outcome: outcome))
            case .cancelled:
                self?.cancel()
            }
        }
        .store(in: &view.stepsBag)
        
        if asRoot {
            setRoot(view)
        } else {
            push(view)
        }
    }
    
    func showResultView(with model: ResultModel) {
        let view = makeResultView(with: model)
        view.steps.sink { [weak self] in
            switch $0 {
            case .done: self?.finish(provisioned: true)
            case let .retry(recovery): self?.retry(recovery)
            case .cancel: self?.cancel()
            }
        }
        .store(in: &view.stepsBag)
        push(view)
    }
    
    func showScanView(with model: ScanModel) {
        let view = makeScanView(with: model)
        view.steps.sink { [weak self] in
            switch $0 {
            case .connected: self?.showCredentialsView(with: CredentialsModel())
            case .cancelled: self?.cancel()
            }
        }
        .store(in: &view.stepsBag)
        setRoot(view)
    }
}

private extension DefaultProvisioningFlow {
    
    /// User abandoned provisioning — via an explicit Cancel action or an interactive
    /// swipe-dismiss (see `handleInteractiveDismiss()`). In `.scan` mode this tears down
    /// the BLE connection (they were still choosing a device or setting it up); in
    /// `.credentials` mode the device is already connected and in use by the dashboard, so
    /// the connection is kept. Guarded by `hasFinished` so a swipe-dismiss that follows an
    /// already-finished flow (Cancel button, success, or unreachable-failure finish) is a
    /// no-op instead of double-tearing-down.
    func cancel() {
        guard hasFinished.isFalse else { return }
        if startMode == .scan {
            Task { await bluetoothService.disconnect() }
        }
        finish(provisioned: false)
    }
    
    func finish(provisioned: Bool) {
        hasFinished = true
        steps.send(.finished(provisioned: provisioned))
    }
    
    /// Resumes after a failure at the point that is actually recoverable: the credentials
    /// form if the device is still connected, or the scan list if it must be found again.
    /// In `.credentials` mode there is no scan list, so an unreachable failure finishes the
    /// flow instead (the dashboard's connection-state observation takes over).
    func retry(_ recovery: ResultModel.Recovery) {
        switch recovery {
        case .reenterCredentials: pop()
        case .rescan where startMode == .scan: popToRoot()
        case .rescan: finish(provisioned: false)
        }
    }
}
