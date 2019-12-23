//
//  ISO9797Alg3Mac.swift
//  PassID
//
//  Created by smlu on 22/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import CommonCrypto


struct ISO9797Alg3 {
    static func mac(key : [UInt8], msg : [UInt8]) -> [UInt8]{
        
        let size = msg.count / 8
        var y : [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        
        for i in 0 ..< size {
            let tmp = [UInt8](msg[i*8 ..< i*8+8])
            y = DESEncrypt(key: [UInt8](key[0..<8]), message: tmp, iv: y)
        }
        
        let iv : [UInt8] = [0,0,0,0,0,0,0,0]
        let b = DESDecrypt(key: [UInt8](key[8..<16]), message: y, iv: iv, options:UInt32(kCCOptionECBMode))
        let a = DESEncrypt(key: [UInt8](key[0..<8]),  message: b, iv: iv, options:UInt32(kCCOptionECBMode))

        return a
    }
}
