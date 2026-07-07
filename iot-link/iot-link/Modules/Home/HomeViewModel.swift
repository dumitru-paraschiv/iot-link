//
//  HomeViewModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    
    private(set) var model: HomeModel
    
    private weak var output: HomeViewOutput?
    private let bluetoothService: BluetoothCentralService
    private var cancellables = Set<AnyCancellable>()
    
    init(bluetoothService: BluetoothCentralService,
         model: HomeModel) {
        self.bluetoothService = bluetoothService
        self.model = model
    }
    
    func send(_ action: HomeViewAction) {
        switch action {
        case .viewDidLoad: handleViewDidLoad()
        case .addDeviceTapped: output?.steps.send(.addDeviceTapped)
        case .setUpWiFiTapped: output?.steps.send(.setUpWiFiTapped)
        case let .ledToggled(on): handleLEDToggled(on)
        case .disconnectTapped: handleDisconnectTapped()
        }
    }
}

private extension HomeViewModel {
    
    func observeState() {
        bluetoothService.statePublisher
            .receive(on: DispatchQueue.main)
            .compactMap(HomeModel.builder.makePhase)
            .sink { [weak self] phase in
                self?.model.accept(phase: phase)
            }
            .store(in: &cancellables)
    }
    
    func observeConnectedDevice() {
        bluetoothService.connectedDevicePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                self?.model.accept(device: device)
            }
            .store(in: &cancellables)
    }
    
    func observeTelemetry() {
        bluetoothService.telemetryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] telemetry in
                self?.model.accept(telemetry: telemetry)
            }
            .store(in: &cancellables)
    }
    
    func observeLEDState() {
        bluetoothService.ledStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ledState in
                self?.model.accept(ledState: ledState)
            }
            .store(in: &cancellables)
    }
}

private extension HomeViewModel {
    
    func handleViewDidLoad() {
        observeState()
        observeConnectedDevice()
        observeTelemetry()
        observeLEDState()
    }
    
    func handleLEDToggled(_ on: Bool) {
        // Optimistic: reflect the tap instantly. The device notifies the resulting state,
        // which reconciles `ledState` via observeLEDState (same value on the happy path,
        // self-correcting if the write is dropped).
        model.accept(ledState: on ? .on : .off)
        Task { await bluetoothService.setLED(on) }
    }
    
    func handleDisconnectTapped() {
        Task { await bluetoothService.disconnect() }
    }
}

extension HomeViewModel: HomeViewInput {
    
    func bind(output: any HomeViewOutput) {
        self.output = output
    }
}
