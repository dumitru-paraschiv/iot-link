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
