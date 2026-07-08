//
//  SettingsViewController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import SwiftUI

final class SettingsViewController: BaseHostingController<SettingsViewUI>, SettingsView {
    
    let steps = PassthroughSubject<SettingsViewSteps, Never>()
    var viewModel: SettingsViewInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.send(.viewDidLoad)
    }
    
    override func setupNavigation() {
        super.setupNavigation()
        navigationItem.title = "Settings"
    }
}

struct SettingsViewUI: View {
    
    var viewModel: SettingsViewModel
    
    var body: some View {
        List {
            Section {
                Button {
                    viewModel.send(.addDeviceTapped)
                } label: {
                    Label(viewModel.model.addDeviceTitle, systemImage: "plus.circle")
                        .fontDesign(.rounded)
                }
            }
        }
    }
}
