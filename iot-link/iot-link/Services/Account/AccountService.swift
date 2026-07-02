//
//  AccountService.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

protocol AccountService: Sendable {
    
    var isOnboarded: Bool { get async }
    
    func completeOnboarding() async
}

actor DefaultAccountService: AccountService {
    
    var isOnboarded: Bool = false
    
    func completeOnboarding() {
        isOnboarded = true
    }
}
