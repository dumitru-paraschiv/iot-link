//
//  AccountService.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Foundation

protocol AccountService: Sendable {
    
    var isOnboarded: Bool { get async }
    
    func completeOnboarding() async
}

actor DefaultAccountService: AccountService {
    
    nonisolated(unsafe) private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    var isOnboarded: Bool {
        userDefaults.get(Bool.self, forKey: .isAppOnboarded).orFalse
    }
    
    func completeOnboarding() {
        userDefaults.set(true, forKey: .isAppOnboarded)
    }
}
