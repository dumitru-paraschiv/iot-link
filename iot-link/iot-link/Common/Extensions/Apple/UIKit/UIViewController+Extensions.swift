//
//  UIViewController+Extensions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

public extension UIViewController {
    
    var presentedViewControllers: [UIViewController] {
        presentedViewController.map({ $0.presentedViewControllers.prepending($0) }).orEmpty
    }
    
    var presenter: UIViewController {
        presentedViewControllers.last ?? self
    }
}
