//
//  ProvisioningViewComponents.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import SwiftUI

enum ProvisioningViewComponents {
    
    // MARK: DeviceRow
    
    struct DeviceRow: View {
        
        let device: ScanModel.Device
        let isConnecting: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                SignalIndicator(strength: device.signal)
                
                Text(device.name)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isConnecting {
                    ProgressView()
                }
            }
            .contentShape(.rect)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: ScanningEmptyState
    
    struct ScanningEmptyState: View {
        
        var body: some View {
            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                
                VStack(spacing: 8) {
                    Text("Searching for devices…")
                        .font(.headline)
                        .fontDesign(.rounded)
                    
                    Text("Make sure your device is powered on and nearby.")
                        .font(.subheadline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(48)
            .frame(minWidth: .zero, maxWidth: .infinity, minHeight: .zero, maxHeight: .infinity)
        }
    }
    
    // MARK: SignalIndicator
    
    struct SignalIndicator: View {
        
        let strength: ScanModel.Device.SignalStrength
        
        var body: some View {
            Image(systemName: "wifi", variableValue: variableValue)
                .font(.body)
                .foregroundStyle(Color.accentColor)
        }
        
        /// Drives the `wifi` symbol's variable-value rendering: higher values fill more
        /// of its signal arcs.
        private var variableValue: Double {
            switch strength {
            case .strong: 1.0
            case .medium: 0.66
            case .weak: 0.33
            }
        }
    }
}
