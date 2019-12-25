//
//  Utils.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation


struct Utils {
    static private let hexDigitsUpper = Array("0123456789ABCDEF".utf16)
    static private let hexDigitsLower = Array("0123456789abcdef".utf16)
    
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
    
    static func isValidPassportNumber(_ passportNumber: String, forceMinSize: Bool = true) -> Bool {
        let pbnumRegx = "[A-Z0-9<]" + (forceMinSize ? "{9}" : "{1,9}")
        let urlTest = NSPredicate(format:"SELF MATCHES %@", pbnumRegx)
        let result = urlTest.evaluate(with: passportNumber)
        return result
    }
    
    static func dataToHex(_ data: Data, upperCase: Bool = false) -> String {
        let hexDigits = upperCase ? Utils.hexDigitsUpper : Utils.hexDigitsLower
        var chars: [unichar] = []
        chars.reserveCapacity(2 * data.count)
        
        for byte in data {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        
        return String(utf16CodeUnits: chars, count: chars.count)
    }
    
    static func hexToData(_ hexStr: String) -> Data? {
        var data = Data(capacity: hexStr.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hexStr, range: NSRange(hexStr.startIndex..., in: hexStr)) { match, _, _ in
            let byteString = (hexStr as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }

        guard data.count > 0 else { return nil }
        return data
    }
    
    
    static func log(_ n: Int, _ base: Int) -> Int {
        var result: Int = 0
        var n = n
        while n > 0 {
            n = n / base
            result += 1
        }
        return result
    }
}

extension Array where Element == UInt8  {
    func hex() -> String {
        return Utils.dataToHex(Data(self))
    }
}

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
