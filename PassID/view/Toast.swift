//
//  Toast.swift
//  PassID
//
//  Created by smlu on 6/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct Toast
{
    static let LONG_DELAY: TimeInterval  = 3.5
    static let SHORT_DELAY: TimeInterval = 2.0
    
    static func show(message: String, delay: TimeInterval = SHORT_DELAY) {
        guard let window: UIWindow = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow }).first
        else {
            return
        }
        
        let toast = UITextView(frame:CGRect(
            x: window.frame.size.width / 2,
            y: window.frame.size.height - 150,
            width: window.frame.size.width * 7/8,
            height: 50
        ))

        // Text & text style
        toast.text                = message
        toast.textAlignment       = .center
        toast.textColor           = UIColor.white
        toast.textContainerInset  = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        toast.font                = UIFont(name: (toast.font?.fontName)!, size: 17)
        
        // Background
        toast.alpha               = 0.0
        toast.backgroundColor     = UIColor.gray.withAlphaComponent(0.8)
        
        // Shadow
        toast.clipsToBounds       =  false
        toast.layer.shadowColor   = UIColor.placeholderText.cgColor
        toast.layer.shadowOffset  = CGSize(width: 3, height: 3)
        toast.layer.shadowOpacity = 0.7
        
        // Fix text y position within frame to center position
        var topCorrect = (toast.bounds.size.height - toast.contentSize.height * toast.zoomScale) / 2.0
        topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect )
        toast.contentOffset.y = -topCorrect
        
        // Fit frame size to text size
        toast.sizeToFit()
        
        // Set toast x position to the center of window and y position to the bottom
        toast.center.x = window.frame.size.width / 2
        toast.center.y = window.frame.size.height - 125
        
        // Set toast frame corner radius
        toast.layer.cornerRadius  = toast.frame.size.height / 2.3
        
        // Animate toast appearance (fade in / fade out)
        UIView.animate(withDuration: 0.65, delay: 0.0, options: .curveEaseIn, animations: {
            toast.alpha = 1.0
        }, completion: {(isCompleted) in
            UIView.animate(withDuration: 0.65, delay: delay, options: .curveEaseOut, animations: {
                toast.alpha = 0.0
            }, completion: {(isCompleted) in
                toast.removeFromSuperview()
            })
        })
        
        // Show toast
        window.addSubview(toast)
    }
}
