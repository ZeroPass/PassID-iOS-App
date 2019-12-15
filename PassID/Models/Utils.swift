//
//  Utils.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation


struct Utils {
    static func isValidUrl(_ url: String, forceAddressAndPort: Bool = true) -> Bool {
        var urlRegEx = "^https?\\:\\/\\/([0-9a-zA-Z\\-\\.]+)"
        if !forceAddressAndPort { urlRegEx += "?" } // don't force address after http(s)://
        urlRegEx += "(\\:([0-9]{1,5})"
        if !forceAddressAndPort { urlRegEx += "?" } // don't force port number after ':'
        urlRegEx += ")?(\\/\\S*)?"

        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: url)
        return result
    }
}
