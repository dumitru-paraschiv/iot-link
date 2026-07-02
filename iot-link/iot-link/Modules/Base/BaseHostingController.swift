//
//  BaseHostingController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import SwiftUI

class BaseHostingController<T: View>: UIHostingController<T> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
    }
    
    func setupNavigation() {
        navigationController?.navigationBar.tintColor = UIColor.label
    }
    
    func setupUI() {
        view.backgroundColor = .systemBackground
    }
}
