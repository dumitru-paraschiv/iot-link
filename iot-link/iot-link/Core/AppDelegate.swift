//
//  AppDelegate.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var services = [AppService]()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: UIApplication.LaunchOptions?) -> Bool {
        var result = false
        for service in services {
            if service.application?(application, didFinishLaunchingWithOptions: launchOptions) ?? false {
                result = true
            }
        }
        return result
    }
    
    // MARK: - UISceneSession Lifecycle
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
