//
//  HomeViewController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Combine
import SwiftUI

final class HomeViewController: BaseHostingController<HomeViewUI>, HomeView {
    
    let steps = PassthroughSubject<HomeViewSteps, Never>()
    var viewModel: HomeViewInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.send(.viewDidLoad)
    }
    
    override func setupNavigation() {
        super.setupNavigation()
        navigationItem.title = "Home"
    }
}

struct HomeViewUI: View {
    
    var viewModel: HomeViewModel
    
    var body: some View {
        VStack {
            
        }
    }
}
