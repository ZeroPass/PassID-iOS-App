//
//  SessionKey.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import CryptoKit
import Foundation
import SwiftyJSON


struct SessionKey : ProtoObject {

    internal static let serKey = "session_key"
    var data: Data
    
    init?(data: Data) {
        if(data.count != 32) {
            return nil
        }
        self.data = data
    }
    
    init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        self.init(data: data)
    }
    
    init?(json: JSON) {
        guard let b64SessionKey = json[SessionKey.serKey].string else {
            return nil
        }
        self.init(base64String: b64SessionKey)
    }
    
    func toJSON() -> JSON {
        return [
            SessionKey.serKey : self.data.base64EncodedString()
        ]
    }
}

extension SessionKey {
    func asSymmetricKey() -> SymmetricKey {
        return SymmetricKey(data: data)
    }
}
