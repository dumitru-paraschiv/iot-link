//
//  SettingsViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    
    private(set) var model: SettingsModel
    
    private weak var output: SettingsViewOutput?
    private let bluetoothService: BluetoothCentralService
    private var cancellables = Set<AnyCancellable>()
    
    init(bluetoothService: BluetoothCentralService,
         model: SettingsModel) {
        self.bluetoothService = bluetoothService
        self.model = model
    }
    
    func send(_ action: SettingsViewAction) {
        switch action {
        case .viewDidLoad: handleViewDidLoad()
        case .addDeviceTapped: output?.steps.send(.addDeviceTapped)
        }
    }
}

private extension SettingsViewModel {
    
    func handleViewDidLoad() {
        observeConnectedDevice()
    }
    
    func observeConnectedDevice() {
        bluetoothService.connectedDevicePublisher
            .receive(on: DispatchQueue.main)
            .map(\.isSome)
            .sink { [weak self] isDeviceConnected in
                self?.model.accept(isDeviceConnected: isDeviceConnected)
            }
            .store(in: &cancellables)
    }
}

extension SettingsViewModel: SettingsViewInput {
    
    func bind(output: any SettingsViewOutput) {
        self.output = output
    }
}
