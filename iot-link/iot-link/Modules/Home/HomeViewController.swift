//
//  HomeViewController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import SwiftUI

final class HomeViewController: BaseHostingController<HomeViewUI>, HomeView {
    
    let steps = PassthroughSubject<HomeViewSteps, Never>()
    var viewModel: HomeViewInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.send(.viewDidLoad)
    }
    
    override func setupNavigation() {
        super.setupNavigation()
        navigationItem.title = "Home"
    }
}

struct HomeViewUI: View {
    
    var viewModel: HomeViewModel
    
    var body: some View {
        switch viewModel.model.phase {
        case .empty:
            emptyState
        case .dashboard:
            dashboard(isConnected: true)
        case .connectionLost:
            dashboard(isConnected: false)
        }
    }
}

// MARK: - Empty State

private extension HomeViewUI {
    
    var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
            
            VStack(spacing: 8) {
                Text("No Device Connected")
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                
                Text("Add a smart device to start monitoring live telemetry and controls.")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button {
                viewModel.send(.addDeviceTapped)
            } label: {
                Label("Add Device", systemImage: "plus")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .frame(minWidth: .zero, maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(.capsule)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 64)
    }
}

// MARK: - Dashboard

private extension HomeViewUI {
    
    func dashboard(isConnected: Bool) -> some View {
        VStack(spacing: 24) {
            HomeViewComponents.DeviceHeader(
                name: viewModel.model.device?.name ?? "Smart Device",
                isConnected: isConnected
            )
            
            if isConnected.isFalse {
                HomeViewComponents.ConnectionLostBanner()
            }
            
            HStack(spacing: 16) {
                HomeViewComponents.TelemetryGauge(
                    title: "Temperature",
                    systemImage: "thermometer.medium",
                    value: viewModel.model.telemetry?.temperature ?? 0,
                    range: -20 ... 40,
                    unit: "°C",
                    tint: .orange
                )
                
                HomeViewComponents.TelemetryGauge(
                    title: "Humidity",
                    systemImage: "humidity",
                    value: viewModel.model.telemetry?.humidity ?? 0,
                    range: 0 ... 100,
                    unit: "%",
                    tint: .blue
                )
            }
            
            HomeViewComponents.LEDControl(
                isOn: viewModel.model.isLEDOn,
                onToggle: { viewModel.send(.ledToggled($0)) }
            )
            .disabled(isConnected.isFalse)
            
            Spacer()
            
            if isConnected {
                HomeViewComponents.SetUpWiFiButton(
                    action: { viewModel.send(.setUpWiFiTapped) }
                )
            }
            
            HomeViewComponents.DisconnectButton(
                action: { viewModel.send(.disconnectTapped) }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 64)
        .opacity(isConnected ? 1 : 0.6)
        .animation(.smooth, value: viewModel.model.phase)
    }
}
