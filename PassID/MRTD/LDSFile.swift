//
//  LDSFile.swift
//  PassID
//
//  Created by smlu on 24/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import SwiftyJSON


typealias FID = [UInt8] // represents file id type

@available(iOS 13, *)
public enum LDSFileTag : Int, CaseIterable {
    case efCOM = 0x60
    case efDG1 = 0x61
    case efDG2 = 0x75
    case efDG3 = 0x63
    case efDG4 = 0x76
    case efDG5 = 0x65
    case efDG6 = 0x66
    case efDG7 = 0x67
    case efDG8 = 0x68
    case efDG9 = 0x69
    case efDG10 = 0x6A
    case efDG11 = 0x6B
    case efDG12 = 0x6C
    case efDG13 = 0x6D
    case efDG14 = 0x6E
    case efDG15 = 0x6F
    case efDG16 = 0x70
    case efSOD = 0x77
    
    // Returns LDS file ID
    func fid() -> FID {
        switch(self) {
            case .efCOM: return [0x01,0x1E]
            case .efDG1: return [0x01,0x01]
            case .efDG2: return [0x01,0x02]
            case .efDG3: return [0x01,0x03]
            case .efDG4: return [0x01,0x04]
            case .efDG5: return [0x01,0x05]
            case .efDG6: return [0x01,0x06]
            case .efDG7: return [0x01,0x07]
            case .efDG8: return [0x01,0x08]
            case .efDG9: return [0x01,0x09]
            case .efDG10: return [0x01,0x0A]
            case .efDG11: return [0x01,0x0B]
            case .efDG12: return [0x01,0x0C]
            case .efDG13: return [0x01,0x0D]
            case .efDG14: return [0x01,0x0E]
            case .efDG15: return [0x01,0x0F]
            case .efDG16: return [0x01,0x10]
            case .efSOD: return [0x01,0x1D]
        }
    }
    
    func name() -> String {
        switch(self) {
            case .efCOM: return "EF.COM"
            case .efDG1: return "EF.DG1"
            case .efDG2: return "EF.DG2"
            case .efDG3: return "EF.DG3"
            case .efDG4: return "EF.DG4"
            case .efDG5: return "EF.DG5"
            case .efDG6: return "EF.DG6"
            case .efDG7: return "EF.DG7"
            case .efDG8: return "EF.DG8"
            case .efDG9: return "EF.DG9"
            case .efDG10: return "EF.DG10"
            case .efDG11: return "EF.DG11"
            case .efDG12: return "EF.DG12"
            case .efDG13: return "EF.DG13"
            case .efDG14: return "EF.DG14"
            case .efDG15: return "EF.DG15"
            case .efDG16: return "EF.DG16"
            case .efSOD: return "EF.SOD"
        }
    }
    
    static func fromName(name: String) -> LDSFileTag? {
        switch(name) {
            case "EF.COM": return .efCOM
            case "EF.DG1": return .efDG1
            case "EF.DG2": return .efDG2
            case "EF.DG3": return .efDG3
            case "EF.DG4": return .efDG4
            case "EF.DG5": return .efDG5
            case "EF.DG6": return .efDG6
            case "EF.DG7": return .efDG7
            case "EF.DG8": return .efDG8
            case "EF.DG9": return .efDG9
            case "EF.DG10": return .efDG10
            case "EF.DG11": return .efDG11
            case "EF.DG12": return .efDG12
            case "EF.DG13": return .efDG13
            case "EF.DG14": return .efDG14
            case "EF.DG15": return .efDG15
            case "EF.DG16": return .efDG16
            case "EF.SOD": return .efSOD
        default:
            return nil
        }
    }
}



class LDSFile: TLV {
    var fileTag: LDSFileTag {
        return LDSFileTag(rawValue: Int(tag))!
    }
    
    func asFile<T>() throws -> T where T: LDSFile  {
        return try T(tag: self.tag, value: self.value)
    }
}

extension LDSFile : ProtoObject{
    func toJSON() -> JSON {
        return [
            fileTag.name().removePrefix("EF.").lowercased() :
            encoded.base64EncodedString()
        ]
    }
}


class EfCOM : LDSFile {
    private(set) var version: String = ""
    private(set) var unicodeVersion: String = ""
    private(set) var tags: Set<LDSFileTag> = []
    
    override internal func parse() throws {
        if fileTag != .efCOM {
            throw TLVError.InvalidTag("Cannot parse EfCOM, invalid file tag \(fileTag.name())")
        }
        
        // Parse version number
        let versionTuple = try TLV.decode(value)
        if versionTuple.0.littleEndian != 0x5F01 {
            throw TLVError.InvalidTag("Invalid version tag \(versionTuple.0.littleEndian)")
        }
        version = String(data: versionTuple.1, encoding: .ascii)!
        
        // Parse string version
        let uniVersionTuple = try TLV.decode(value[Int(versionTuple.2)...])
        if uniVersionTuple.0.littleEndian != 0x5F36 {
            throw TLVError.InvalidTag("Invalid unicode version tag \(uniVersionTuple.0.littleEndian)")
        }
        unicodeVersion = String(data: uniVersionTuple.1, encoding: .utf8)!
        
        // Parse tag list
        let filesTlv = try TLV(encodedTLV: value[Int(versionTuple.2 + uniVersionTuple.2)...])
        if filesTlv.tag.littleEndian != 0x5C {
            throw TLVError.InvalidTag("Invalid tag list identifier \(filesTlv.tag.littleEndian)")
        }
        
        for b in filesTlv.value {
            tags.insert(LDSFileTag(rawValue: Int(b))!)
        }
    }
}
