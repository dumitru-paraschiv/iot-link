//
//  CredentialsModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

struct CredentialsModel {
    
    private(set) var ssid: String
    private(set) var password: String
    private(set) var isPasswordRevealed: Bool
    private(set) var isSubmitting: Bool
    
    init(ssid: String = "",
         password: String = "",
         isPasswordRevealed: Bool = false,
         isSubmitting: Bool = false) {
        self.ssid = ssid
        self.password = password
        self.isPasswordRevealed = isPasswordRevealed
        self.isSubmitting = isSubmitting
    }
}

// MARK: Extensions

extension CredentialsModel {
    
    /// Byte bounds per `docs/GATT_SPEC.md`, surfaced for the field character counters.
    var maxSSIDLength: Int { WiFiCredentials.maxSSIDLength }
    var maxPasswordLength: Int { WiFiCredentials.maxPasswordLength }
    
    var credentials: WiFiCredentials {
        WiFiCredentials(ssid: ssid, password: password)
    }
    
    /// The form can be submitted only when both fields are within spec bounds and not
    /// already provisioning. Serialization is the single source of truth for validity.
    var canSubmit: Bool {
        isSubmitting.isFalse && credentials.serialize().isSome
    }
    
    var ssidByteCount: Int {
        ssid.utf8.count
    }
    
    var passwordByteCount: Int {
        password.utf8.count
    }
    
    var isSSIDOverLimit: Bool {
        ssidByteCount > maxSSIDLength
    }
    
    var isPasswordOverLimit: Bool {
        passwordByteCount > maxPasswordLength
    }
}

extension CredentialsModel {
    
    mutating func accept(ssid: String) {
        self.ssid = ssid
    }
    
    mutating func accept(password: String) {
        self.password = password
    }
    
    mutating func accept(isPasswordRevealed: Bool) {
        self.isPasswordRevealed = isPasswordRevealed
    }
    
    mutating func accept(isSubmitting: Bool) {
        self.isSubmitting = isSubmitting
    }
}
