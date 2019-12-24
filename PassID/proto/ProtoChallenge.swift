//
//  ProtoChallenge.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import SwiftyJSON

struct CID : ProtoObject {
    internal static let serKey = "cid"
    var data: Data
    
    init?(data: Data) {
        if(data.count != 4) {
            return nil
        }
        self.data = data
    }

    init?(json: JSON) {
        guard let rawCID = Data.fromHex(json[CID.serKey].string) else {
            return nil
        }
        self.init(data: rawCID)
    }
    
    func toJSON() -> JSON {
        return [
            CID.serKey : self.data.hex()
        ]
    }
    
    func toUInt32() -> UInt32 {
        let i32array = self.data.withUnsafeBytes { $0.load(as: UInt32.self) }
        return i32array
    }
}


struct ProtoChallenge : ProtoObject {

    internal static let serKey = "challenge"
    var data: Data
    
    var id: CID {
        get {
            return CID(data: self.data[0..<4])!
        }
    }
    
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
        guard let b64Challenege = json[ProtoChallenge.serKey].string else {
            return nil
        }
        self.init(base64String: b64Challenege)
    }
    
    func toJSON() -> JSON {
        return [
            ProtoChallenge.serKey : self.data.base64EncodedString()
        ]
    }
}
