//
//  OnboardingModel.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

struct OnboardingModel {
    
    private(set) var currentPageIndex: Int
    private(set) var pages: [Page]
    
    init(currentPageIndex: Int = 0,
         pages: [Page] = Self.builder.makeDefaultPages()) {
        self.currentPageIndex = currentPageIndex
        self.pages = pages
    }
    
    struct Page: Identifiable {
        
        let id: Int
        let imageName: String
        let title: String
        let description: String
    }
}

// MARK: - Extensions

extension OnboardingModel {
    
    static let builder = OnboardingModelBuilder.self
    
    var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }
}

extension OnboardingModel {
    
    mutating func set(currentPageIndex: Int) {
        self.currentPageIndex = currentPageIndex
    }
}

// MARK: - Builder

enum OnboardingModelBuilder {
    
    static func makeDefaultPages() -> [OnboardingModel.Page] {
        [
            OnboardingModel.Page(
                id: 0,
                imageName: "antenna.radiowaves.left.and.right",
                title: "Connect via Bluetooth",
                description: "Discover and pair with nearby smart devices using Bluetooth Low Energy."
            ),
            OnboardingModel.Page(
                id: 1,
                imageName: "wifi",
                title: "Provision Your Device",
                description: "Send your Wi-Fi credentials securely to configure your device's internet connection."
            ),
            OnboardingModel.Page(
                id: 2,
                imageName: "chart.line.uptrend.xyaxis",
                title: "Monitor & Control",
                description: "View live sensor data and control your hardware directly from the dashboard."
            )
        ]
    }
}
