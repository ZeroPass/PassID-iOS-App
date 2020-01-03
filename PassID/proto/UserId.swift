//
//  UserId.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import SwiftyJSON

struct UserId : ProtoObject {

    internal static let serKey = "uid"
    var data: Data
    
    init?(data: Data) {
        if(data.count != RIPEMD160.digestSize) {
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
        guard let b64Uid = json[UserId.serKey].string else {
            return nil
        }
        self.init(base64String: b64Uid)
    }
    
    func toJSON() -> JSON {
        return [
            UserId.serKey : self.data.base64EncodedString()
        ]
    }
    
    static func fromDG15(_ dg15: EfDG15) -> UserId {
        return UserId(data: RIPEMD160.hash(message: dg15.aaPublicKeyBytes()))!
    }
}
