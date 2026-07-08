//
//  HomeViewComponents.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 07.07.2026.
//

import SwiftUI

enum HomeViewComponents {
    
    // MARK: ReconnectingBanner
    
    struct ReconnectingBanner: View {
        
        var body: some View {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                    .controlSize(.small)
                
                Text("Reconnecting…")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
            }
            .frame(minWidth: .zero, maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.orange)
            .clipShape(.capsule)
        }
    }
    
    // MARK: DeviceHeader
    
    struct DeviceHeader: View {
        
        let name: String
        let isConnected: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "sensor.tag.radiowaves.forward")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    
                    Text(isConnected ? "Connected" : "Reconnecting…")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(isConnected ? .green : .orange)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: DisconnectButton
    
    struct DisconnectButton: View {
        
        let action: EmptyCallback?
        
        var body: some View {
            Button {
                action?()
            } label: {
                Text("Disconnect")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.red)
                    .frame(minWidth: .zero, maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.capsule)
            }
        }
    }
    
    // MARK: LEDControl
    
    struct LEDControl: View {
        
        let isOn: Bool
        let onToggle: Callback<Bool>?
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                    .font(.title2)
                    .foregroundStyle(isOn ? .yellow : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                
                Text("Status LED")
                    .font(.body)
                    .fontDesign(.rounded)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { onToggle?($0) }
                ))
                .labelsHidden()
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }
    
    // MARK: SetUpWiFiButton
    
    struct SetUpWiFiButton: View {
        
        let action: EmptyCallback?
        
        var body: some View {
            Button {
                action?()
            } label: {
                Label("Set Up Wi-Fi", systemImage: "wifi")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.accentColor)
                    .frame(minWidth: .zero, maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.capsule)
            }
        }
    }
    
    // MARK: TelemetryGauge
    
    struct TelemetryGauge: View {
        
        let title: String
        let systemImage: String
        let value: Double
        let range: ClosedRange<Double>
        let unit: String
        let tint: Color
        
        var body: some View {
            VStack(spacing: 12) {
                Gauge(value: value.clamped(to: range), in: range) {
                    Image(systemName: systemImage)
                } currentValueLabel: {
                    Text(value, format: .number.precision(.fractionLength(1)))
                        .fontDesign(.rounded)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: value))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(tint)
                .animation(.smooth, value: value)
                
                Text("\(title) (\(unit))")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: .zero, maxWidth: .infinity)
        }
    }
}

// MARK: - Helpers

private extension Double {
    
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
