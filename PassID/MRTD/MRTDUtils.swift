//
//  MRTDUtils.swift
//  PassID
//
//  Created by smlu on 22/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation


public func pad(_ data : [UInt8]) -> [UInt8] {
    let size = 8
    let padBlock : [UInt8] = [0x80, 0, 0, 0, 0, 0, 0, 0]
    let left = size - (data.count % size)
    return (data + [UInt8](padBlock[0 ..< left]))
}

public func unpad( _ paddedData : [UInt8]) -> [UInt8] {
    var i = paddedData.count-1
    while paddedData[i] == 0x00 {
        i -= 1
    }
    
    if paddedData[i] == 0x80 {
        return [UInt8](paddedData[0..<i])
    } else {
        // no padding
        return paddedData
    }
}

public func intToBin(_ data : Int, pad : Int = 2) -> [UInt8] {
    if pad == 2 {
        let hex = String(format:"%02x", data)
        return hexRepToBin(hex)
    } else {
        let hex = String(format:"%04x", data)
        return hexRepToBin(hex)

    }
}

/// 'AABB' --> \xaa\xbb'"""
public func hexRepToBin(_ val : String) -> [UInt8] {
    var output : [UInt8] = []
    var x = 0
    while x < val.count {
        if x+2 <= val.count {
            output.append( UInt8(val[x..<x + 2], radix:16)! )
        } else {
            output.append( UInt8(val[x..<x + 1], radix:16)! )

        }
        x += 2
    }
    return output
}

public func binToHexRep( _ val : [UInt8] ) -> String {
    var string = ""
    for x in val {
        string += String(format:"%02x", x )
    }
    return string.uppercased()
}

public func binToHexRep( _ val : UInt8 ) -> String {
    let string = String(format:"%02x", val ).uppercased()
    return string
}

public func binToHex( _ val: UInt8 ) -> Int {
    let hexRep = String(format:"%02X", val)
    return Int(hexRep, radix:16)!
}

public func binToHex( _ val: [UInt8] ) -> UInt64 {
    let hexVal = UInt64(binToHexRep(val), radix:16)!
    return hexVal
}

public func binToHex( _ val: ArraySlice<UInt8> ) -> UInt64 {
    return binToHex( [UInt8](val) )
}


public func hexToBin( _ val : UInt64 ) -> [UInt8] {
    let hexRep = String(format:"%lx", val)
    return hexRepToBin( hexRep)
}

public func binToInt( _ val: ArraySlice<UInt8> ) -> Int {
    let hexVal = binToInt( [UInt8](val) )
    return hexVal
}

public func binToInt( _ val: [UInt8] ) -> Int {
    let hexVal = Int(binToHexRep(val), radix:16)!
    return hexVal
}

