//
//  ProvisioningViewComponents.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import SwiftUI

enum ProvisioningViewComponents {
    
    // MARK: CharacterCounter
    
    struct CharacterCounter: View {
        
        let byteCount: Int
        let maxBytes: Int
        let isOverLimit: Bool
        
        var body: some View {
            Text("\(byteCount)/\(maxBytes)")
                .font(.caption2)
                .fontDesign(.rounded)
                .foregroundStyle(isOverLimit ? Color.red : Color.secondary)
                .animation(.smooth, value: isOverLimit)
                .frame(minWidth: .zero, maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    // MARK: CredentialField
    
    struct CredentialField: View {
        
        let title: String
        let placeholder: String
        @Binding var text: String
        let byteCount: Int
        let maxBytes: Int
        let isOverLimit: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: $text)
                    .textContentType(.none)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .frame(height: 32)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 8))
                
                CharacterCounter(byteCount: byteCount, maxBytes: maxBytes, isOverLimit: isOverLimit)
            }
        }
    }
    
    // MARK: CredentialsHeader
    
    struct CredentialsHeader: View {
        
        var body: some View {
            VStack(spacing: 12) {
                Image(systemName: "wifi")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                
                Text("Connect to Wi-Fi")
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                
                Text("Enter your network details to configure the device.")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
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
    
    // MARK: FailureResult
    
    struct FailureResult: View {
        
        let reason: String
        let onRetry: EmptyCallback?
        let onCancel: EmptyCallback?
        
        var body: some View {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)
                
                VStack(spacing: 8) {
                    Text("Provisioning Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                    
                    Text(reason)
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 32) {
                    Button {
                        onRetry?()
                    } label: {
                        Text("Try Again")
                            .font(.headline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .frame(minWidth: .zero, maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .clipShape(.capsule)
                    }
                    
                    Button {
                        onCancel?()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 54)
        }
    }
    
    // MARK: PasswordField
    
    struct PasswordField: View {
        
        @Binding var text: String
        let isRevealed: Bool
        let byteCount: Int
        let maxBytes: Int
        let isOverLimit: Bool
        let onToggleReveal: EmptyCallback?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Group {
                        if isRevealed {
                            TextField("Password", text: $text)
                        } else {
                            SecureField("Password", text: $text)
                        }
                    }
                    .textContentType(.none)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.title3)
                    .frame(height: 32)
                    
                    Button {
                        onToggleReveal?()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 8))
                
                CharacterCounter(byteCount: byteCount, maxBytes: maxBytes, isOverLimit: isOverLimit)
            }
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
    
    // MARK: SubmitButton
    
    struct SubmitButton: View {
        
        let isSubmitting: Bool
        let isEnabled: Bool
        let action: EmptyCallback?
        
        var body: some View {
            Button {
                action?()
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Connect")
                            .font(.headline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                    }
                }
                .frame(minWidth: .zero, maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isEnabled ? Color.accentColor : Color.gray)
                .clipShape(.capsule)
                .animation(.smooth, value: isEnabled)
            }
            .disabled(isEnabled.isFalse)
        }
    }
    
    // MARK: SuccessResult
    
    struct SuccessResult: View {
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                
                Text("Device Added")
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
            }
            .frame(minWidth: .zero, maxWidth: .infinity, minHeight: .zero, maxHeight: .infinity)
        }
    }
}
