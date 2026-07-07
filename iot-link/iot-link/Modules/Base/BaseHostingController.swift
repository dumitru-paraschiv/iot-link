//
//  BaseHostingController.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import SwiftUI

class BaseHostingController<T: View>: UIHostingController<T> {
    
    /// Whether this screen wants the navigation bar hidden. Applied on every appearance so
    /// each screen declares its own bar state rather than inheriting whatever the previous
    /// screen left behind. Override per screen; defaults to visible.
    var prefersNavigationBarHidden: Bool { false }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let hidden = prefersNavigationBarHidden
        
        // Sync the bar visibility change to the push/pop transition so the title doesn't
        // animate a frame out of step with the sliding view. Inside the coordinator block
        // the change must be non-animated - the coordinator supplies the animation, and a
        // nested `animated: true` would double-animate and cause the title to jump.
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.navigationController?.setNavigationBarHidden(hidden, animated: false)
            })
        } else {
            navigationController?.setNavigationBarHidden(hidden, animated: animated)
        }
    }
    
    func setupNavigation() {
        navigationController?.navigationBar.tintColor = UIColor.label
    }
    
    func setupUI() {
        view.backgroundColor = .systemBackground
    }
}
