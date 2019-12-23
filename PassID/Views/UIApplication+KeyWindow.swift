//
//  UIApplication+KeyWindow.swift
//  PassID
//
//  Created by smlu on 21/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI

extension UIApplication {
    static var keyWindow: UIWindow? {
        // Get first active global window
        return UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow }).first
    }
}
