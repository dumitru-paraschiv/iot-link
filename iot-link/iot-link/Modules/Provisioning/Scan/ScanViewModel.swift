//
//  ScanViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import Foundation
import Observation

@MainActor
@Observable
final class ScanViewModel {
    
    private(set) var model: ScanModel
    
    private weak var output: ScanViewOutput?
    private let bluetoothService: BluetoothCentralService
    private var cancellables = Set<AnyCancellable>()
    
    init(bluetoothService: BluetoothCentralService,
         model: ScanModel) {
        self.bluetoothService = bluetoothService
        self.model = model
    }
    
    func send(_ action: ScanViewAction) {
        switch action {
        case .viewDidLoad: handleViewDidLoad()
        case .viewWillDisappear: handleViewWillDisappear()
        case let .deviceTapped(id): handleDeviceTapped(id: id)
        }
    }
}

private extension ScanViewModel {
    
    func observePeripherals() {
        bluetoothService.discoveredPeripheralsPublisher
            .receive(on: DispatchQueue.main)
            .map(ScanModel.builder.makeDevices)
            .sink { [weak self] devices in
                self?.model.accept(devices: devices)
            }
            .store(in: &cancellables)
    }
    
    func observeState() {
        bluetoothService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
}

private extension ScanViewModel {
    
    func handleViewDidLoad() {
        observePeripherals()
        observeState()
        Task { await bluetoothService.startScanning() }
    }
    
    func handleViewWillDisappear() {
        Task { await bluetoothService.stopScanning() }
    }
    
    func handleDeviceTapped(id: UUID) {
        guard model.isConnecting.isFalse else { return }
        
        model.accept(connectingDeviceID: id)
        Task { await bluetoothService.connect(to: id) }
    }
    
    func handleStateChange(_ state: BluetoothState) {
        switch state {
        case .connected:
            output?.steps.send(.connected)
        case .disconnected, .idle:
            // A drop during connection returns us to the scanning list.
            if model.isConnecting {
                model.accept(connectingDeviceID: nil)
            }
        default:
            break
        }
    }
}

extension ScanViewModel: ScanViewInput {
    
    func bind(output: any ScanViewOutput) {
        self.output = output
    }
}
