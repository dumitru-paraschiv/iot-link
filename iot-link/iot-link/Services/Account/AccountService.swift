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
    
    var isOnboarded: Bool {
        UserDefaults.standard.get(Bool.self, forKey: .isAppOnboarded).orFalse
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: .isAppOnboarded)
    }
}
