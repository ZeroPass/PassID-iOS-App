//
//  Data+.swift
//  PassID
//
//  Created by smlu on 03/01/2020.
//  Copyright © 2020 ZeroPass. All rights reserved.
//

import Foundation


extension Data {
    
    var bytes: [UInt8] {
        return [UInt8](self)
    }
    
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hex(options: HexEncodingOptions = []) -> String {
        return Utils.dataToHex(self, upperCase: options.contains(.upperCase))
    }
    
    static func fromHex(_ hexEncodedString: String?) -> Data? {
        guard let hex = hexEncodedString else {
            return nil
        }
        return Utils.hexToData(hex)
    }
    
    mutating func append(_ byte: UInt8) {
        var byte = byte
        self.append(UnsafeBufferPointer(start: &byte, count: 1))
    }
    
    mutating func append(_ n: Int) {
        var n = n
        self.append(UnsafeBufferPointer(start: &n, count: 1))
    }
    
    mutating func append(_ n: UInt) {
        var n = n
        self.append(UnsafeBufferPointer(start: &n, count: 1))
    }
}
