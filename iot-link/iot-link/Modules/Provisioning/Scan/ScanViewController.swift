//
//  ScanViewController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Combine
import SwiftUI

final class ScanViewController: BaseHostingController<ScanViewUI>, ScanView {
    
    let steps = PassthroughSubject<ScanViewSteps, Never>()
    var viewModel: ScanViewInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.send(.viewDidLoad)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.send(.viewWillDisappear)
    }
    
    override func setupNavigation() {
        super.setupNavigation()
        navigationItem.title = "Add Device"
    }
}

struct ScanViewUI: View {
    
    var viewModel: ScanViewModel
    
    var body: some View {
        Group {
            if viewModel.model.devices.isEmpty {
                ProvisioningViewComponents.ScanningEmptyState()
            } else {
                deviceList
            }
        }
    }
    
    private var deviceList: some View {
        List(viewModel.model.devices) { device in
            Button {
                viewModel.send(.deviceTapped(id: device.id))
            } label: {
                ProvisioningViewComponents.DeviceRow(
                    device: device,
                    isConnecting: viewModel.model.connectingDeviceID == device.id
                )
            }
            .disabled(viewModel.model.isConnecting)
        }
    }
}
