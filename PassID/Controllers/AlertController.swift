//
//  AlertController.swift
//  PassID
//
//  Created by smlu on 25/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import UIKit


class AlertController: UIAlertController {

    private var cbsWillDisappear: [((UIAlertController) -> Void)] = []
    private var cbsDidDisappear: [((UIAlertController) -> Void)] = []

    override func viewWillDisappear(_ animated: Bool) {
        for cb in cbsWillDisappear {
            cb(self)
        }
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for cb in cbsDidDisappear {
            cb(self)
        }
    }
    
    func onWillDisappear(_ cb: @escaping (UIAlertController) -> Void) {
        cbsWillDisappear.append(cb)
    }
    
    func onDidDisappear(_ cb: @escaping (UIAlertController) -> Void) {
        cbsDidDisappear.append(cb)
    }
}
