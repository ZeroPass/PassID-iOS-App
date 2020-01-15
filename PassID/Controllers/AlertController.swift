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
    
    func setTitleStyle(font: UIFont?, color: UIColor? = nil) {
           guard let title = self.title else { return }
           let attributeString = NSMutableAttributedString(string: title)
           if let titleFont = font {
               attributeString.addAttributes([NSAttributedString.Key.font : titleFont],
                                             range: NSMakeRange(0, title.utf8.count))
           }
           
           if let titleColor = color {
               attributeString.addAttributes([NSAttributedString.Key.foregroundColor : titleColor],
                                             range: NSMakeRange(0, title.utf8.count))
           }
           self.setValue(attributeString, forKey: "attributedTitle")
       }
       
       func setMessageStyle(font: UIFont?, color: UIColor? = nil) {
           guard let message = self.message else { return }
           let attributeString = NSMutableAttributedString(string: message)
           if let messageFont = font {
               attributeString.addAttributes([NSAttributedString.Key.font : messageFont],
                                             range: NSMakeRange(0, message.utf8.count))
           }
           
           if let messageColorColor = color {
               attributeString.addAttributes([NSAttributedString.Key.foregroundColor : messageColorColor],
                                             range: NSMakeRange(0, message.utf8.count))
           }
           self.setValue(attributeString, forKey: "attributedMessage")
       }
}
