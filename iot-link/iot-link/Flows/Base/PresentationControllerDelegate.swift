//
//  PresentationControllerDelegate.swift
//  CanvasBridge
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import UIKit

protocol PresentationControllerDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
    
    var didDismiss: EmptyCallback? { get set }
}

final class DefaultPresentationControllerDelegate: NSObject, PresentationControllerDelegate {
    
    var didDismiss: EmptyCallback?
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismiss?()
    }
}
