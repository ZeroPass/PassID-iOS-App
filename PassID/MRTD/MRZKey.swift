//
//  MRZKey.swift
//  PassID
//
//  Created by smlu on 24/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation


public struct MRZKey: Codable {
    private let mrtdNum: String
    private let dob: String
    private let doe: String
    
    init(mrtdNumber: String, dateOfBirth: Date, dateOfExpiry: Date) {
        self.mrtdNum = mrtdNumber
        self.dob     = MRZ.dateToString(dateOfBirth)
        self.doe     = MRZ.dateToString(dateOfExpiry)
    }
    
    func mrtdNumber() -> String {
        return mrtdNum
    }
    
    func dateOfBirth() -> Date {
        let df = DateFormatter()
        df.dateFormat = MRZ.dateFormat
        return df.date(from: dob)!
    }
    
    func dateOfExpiry() -> Date {
        let df = DateFormatter()
        df.dateFormat = MRZ.dateFormat
        return df.date(from: doe)!
    }
    
    func bacKeySeed() -> [UInt8] {
        let csn = MRZ.calculateChecksum(mrtdNum)
        let csb = MRZ.calculateChecksum(dob)
        let cse = MRZ.calculateChecksum(doe)
        
        let kmrz = "\(mrtdNum)\(csn)\(dob)\(csb)\(doe)\(cse)"
        let hash = sha1([UInt8](kmrz.data(using:.utf8)!))
        let subHash = Array(hash[0 ..< BAC.keyLen])
        return Array(subHash)
    }
}
