//
//  AlertView.swift
//  PassID
//
//  Created by smlu on 22/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


extension View {
    func showAlert(_ alert: UIAlertController, animated: Bool = true) {
        if let controller = topMostViewController() {
            controller.present(alert, animated: animated)
        }
    }
    
    private func topMostViewController() -> UIViewController? {
        guard let rootController = UIApplication.keyWindow?.rootViewController else {
            return nil
        }
        return topMostViewController(for: rootController)
    }

    private func topMostViewController(for controller: UIViewController) -> UIViewController {
        if let presentedController = controller.presentedViewController {
            return topMostViewController(for: presentedController)
        }
        else if let navigationController = controller as? UINavigationController {
            guard let topController = navigationController.topViewController else {
                return navigationController
            }
            return topMostViewController(for: topController)
        }
        else if let tabController = controller as? UITabBarController {
            guard let topController = tabController.selectedViewController else {
                return tabController
            }
            return topMostViewController(for: topController)
        }
        return controller
    }
}
