//
//  Session.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import CryptoKit
import Foundation
import SwiftyJSON


struct SessionMac : ProtoObject {
    internal static let serKey = "mac"
    var data: Data
    
    init(_ mac: ProtoSession.hmac.MAC) {
        self.data = Data(mac)
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
        guard let b64Challenege = json[SessionMac.serKey].string else {
            return nil
        }
        self.init(base64String: b64Challenege)
    }
    
    func toJSON() -> JSON {
        return [
            SessionMac.serKey : self.data.base64EncodedString()
        ]
    }
}


@available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *)
struct ProtoSession {
    typealias hmac = HMAC<SHA256>
    
    let uid: UserId
    let key: SessionKey
    let expiration: Date

    private var nonce: UInt32 = 0

    func getMAC(apiName: String, rawParams: Data) -> SessionMac {
        let msg = getEncodedNonce() + apiName.data(using: .ascii)! + rawParams
        return SessionMac(
            hmac.authenticationCode(for: msg, using: key.asSymmetricKey())
        )
    }

    private mutating func incrementNonce() {
       nonce += 1
    }

    private func getEncodedNonce() -> Data {
        var big = nonce.bigEndian
        return Data(bytes: &big,
                    count: MemoryLayout.size(ofValue: nonce))
    }
}
