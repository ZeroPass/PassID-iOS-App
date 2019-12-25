//
//  TLV.swift
//  PassID
//
//  Created by smlu on 21/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation

@available(iOS 13, *)
public enum TLVError: Error {
    case InvalidTag
    case InvalidEncodedTag
    case InvalidLength
    case InvalidEncodedLength

    var value: String {
        switch self {
        case .InvalidTag: return "InvalidTag"
        case .InvalidEncodedTag: return "InvalidEncodedTag"
        case .InvalidLength: return "InvalidLength"
        case .InvalidEncodedLength: return "InvalidEncodedLength"
        }
    }
}


open class TLV {
    
    let tag: UInt
    let value: Data
    init(tag: UInt, value: Data) {
        // TODO: check tag and value can be encoded and
        //       if not, throw
        self.tag   = tag
        self.value = value
    }
}

extension TLV {
    
    convenience init(encodedTLV: Data) throws {
        try self.init(encodedTLV: encodedTLV.bytes)
    }
    
    convenience init(encodedTLV: ArraySlice<UInt8>) throws {
        try self.init(encodedTLV: Array(encodedTLV))
    }
    
    convenience init(encodedTLV: [UInt8]) throws {
        let tvPair = try TLV.decode(encodedTLV)
        self.init(tag: tvPair.0, value: tvPair.1)
    }
    
    var encoded: Data {
        return try! TLV.encode(tag: tag, value: value)
    }
}


extension TLV {
    
    // Returns decoded tag, value and number of bytes encoded TLV took.
    static func decode(_ encodedTLV: Data) throws -> (UInt, Data, UInt) {
        return try decode(encodedTLV.bytes)
    }
    
    // Returns decoded tag, value and number of bytes encoded TLV took.
    static func decode(_ encodedTLV: ArraySlice<UInt8>) throws -> (UInt, Data, UInt) {
        return try decode(Array(encodedTLV))
    }
    
    // Returns decoded tag, value and number of bytes encoded TLV took.
    static func decode(_ encodedTLV: [UInt8]) throws -> (UInt, Data, UInt) {
        let tlPair = try decodeTagAndLength(encodedTLV)
        let data = encodedTLV[ Int(tlPair.2)..<(Int(tlPair.1) + Int(tlPair.2)) ]
        return (tlPair.0, Data(data), tlPair.1 + tlPair.2)
    }
    
    // Returns encoded TLV from tag and data.
    static func encode(tag: UInt, value: Data) throws -> Data {
        let tl = try encodeTag(tag) + encodeLength(UInt(value.count))
        return tl + value
    }
    
    // Returns decoded tag, length and number of bytes encoded tag and length took.
    static func decodeTagAndLength(_ encodedTagLength : Data) throws -> (UInt, UInt, UInt) {
        return try decodeTagAndLength(encodedTagLength.bytes)
    }
    
    // Returns decoded tag, length and number of bytes encoded tag and length took.
    static func decodeTagAndLength(_ encodedTagLength : ArraySlice<UInt8>) throws -> (UInt, UInt, UInt) {
        return try decodeTagAndLength(Array(encodedTagLength))
    }
    
    // Returns decoded tag, length and number of bytes encoded tag and length took.
    static func decodeTagAndLength(_ encodedTagLength : [UInt8]) throws -> (UInt, UInt, UInt)  {
        let tagPair = try decodeTag(encodedTagLength)
        let lengthPair = try decodeLength(encodedTagLength[Int(tagPair.1)...])
        return (tagPair.0, lengthPair.0, tagPair.1 + lengthPair.1)
    }
    
    // Returns decoded tag and number of bytes encoded tag took.
    static func decodeTag(_ encodedTag: Data) throws -> (UInt, UInt) {
        return try decodeTag(encodedTag.bytes)
    }
    
    // Returns decoded tag and number of bytes encoded tag took.
    static func decodeTag(_ encodedTag:  ArraySlice<UInt8>) throws -> (UInt, UInt) {
        return try decodeTag(Array(encodedTag))
    }
    
    // Returns decoded tag and number of bytes encoded tag took.
    static func decodeTag(_ encodedTag : [UInt8]) throws -> (UInt, UInt)  {
        if encodedTag.isEmpty {
            throw TLVError.InvalidEncodedTag
        }
        
        var tag:UInt    = 0
        var b:UInt8     = encodedTag[0]
        var offset:Int  = 1
        
        switch b & 0x1F {
            case 0x1F:
                if offset >= encodedTag.count {
                    throw TLVError.InvalidEncodedTag
                }
                
                tag = UInt(b) /* We store the first byte including LHS nibble */
                b = encodedTag[offset]
                offset += 1

                while (b & 0x80) == 0x80 {
                    if offset >= encodedTag.count {
                        throw TLVError.InvalidEncodedTag
                    }

                    tag <<= 8;
                    tag |= UInt(b & 0x7F)
                    b = encodedTag[offset]
                    offset += 1
                }

                tag <<= 8
                tag |= UInt(b & 0x7F) // Byte with MSB set is last byte of tag.
            default:
                tag = UInt(b)
        }

        return (tag, UInt(offset))
    }
    
    static func encodeTag(_ tag: UInt) -> Data {
        let byteCount = Utils.log(Int(tag), 256)
        var encodedTag = Data(capacity: byteCount)
        for i in 0..<byteCount {
            let pos = 8 * (byteCount - i - 1);
            encodedTag.append(UInt8(tag & (0xFF << pos)) >> pos);
        }
        encodedTag[0] |= 0x40
        return encodedTag
    }
  
    /* Returns decoded length and number of bytes encoded length took. */
    static func decodeLength( _ encodedLength: Data) throws -> (UInt, UInt) {
        return try decodeLength(encodedLength.bytes)
    }
    
    /* Returns decoded length and number of bytes encoded length took. */
    static func decodeLength( _ encodedLength: ArraySlice<UInt8> ) throws -> (UInt, UInt) {
        return try decodeLength(Array(encodedLength))
    }

    // Returns decoded length and number of bytes encoded length took.
    // Max length to decode = 0xFFFFFF
    static func decodeLength(_ encodedLength : [UInt8]) throws -> (UInt, UInt)  {
        var length: UInt    = UInt(encodedLength[0] & 0xff)
        var byteCount: UInt = 1
        if((length & 0x80) == 0x80) { // long form
            byteCount = length & 0x7f
            if byteCount > 3 {
                throw TLVError.InvalidEncodedLength
            }

            length = 0;
            byteCount = 1 + byteCount
            if byteCount > encodedLength.count {
                throw TLVError.InvalidEncodedLength
            }

            for i in 1..<byteCount {
                length = length * 0x100 + UInt(encodedLength[Int(i)] & 0xff)
            }
        }

        return (length, byteCount)
    }

    // Returns encoded length
    // Length must not be negative
    static func encodeLength(_ length: Int) throws -> Data{
        if length < 0 {
            throw TLVError.InvalidLength
        }
        return try encodeLength(UInt(length))
    }

    // Returns encoded length
    // Max length to encode = 0xFFFFFF
    static func encodeLength(_ length: UInt) throws -> Data{
        var encodedLength = Data(capacity: 4)
        if length < 0x80 {
            /* short form */
            encodedLength.append(UInt8(length))
        }
        else { // long form
            let byteCount = Utils.log(Int(length), 256)
            if byteCount > 3 {
                throw TLVError.InvalidLength
            }

            encodedLength.append(UInt8(byteCount | 0x80))
            for i in 0..<byteCount {
                let pos = 8 * (byteCount - i - 1)
                encodedLength.append(UInt8((length & (0xFF << pos)) >> pos))
            }
        }
        return encodedLength
    }
}
