//
//  MRZKey.swift
//  PassID
//
//  Created by smlu on 24/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation


public struct MRZKey {
    private let mrtdNumber: String
    private let dob: String
    private let doe: String
    
    init(mrtdNumber: String, dateOfBirth: Date, dateOfExpiry: Date) {
        self.mrtdNumber = mrtdNumber
        
        let df = DateFormatter()
        df.dateFormat = "yyMMdd"
        self.dob = df.string(from: dateOfBirth)
        self.doe = df.string(from: dateOfExpiry)
    }
    
    func bacKeySeed() -> [UInt8] {
        let csn = calculateChecksum(mrtdNumber)
        let csb = calculateChecksum(dob)
        let cse = calculateChecksum(doe)
        
        let kmrz = "\(mrtdNumber)\(csn)\(dob)\(csb)\(doe)\(cse)"
        let hash = sha1([UInt8](kmrz.data(using:.utf8)!))
        let subHash = Array(hash[0..<BAC.keyLen])
        return Array(subHash)
    }
    
    private func calculateChecksum( _ checkString : String ) -> Int {
        let characterDict  = ["0" : "0", "1" : "1", "2" : "2", "3" : "3", "4" : "4", "5" : "5", "6" : "6", "7" : "7", "8" : "8", "9" : "9", "<" : "0", " " : "0", "A" : "10", "B" : "11", "C" : "12", "D" : "13", "E" : "14", "F" : "15", "G" : "16", "H" : "17", "I" : "18", "J" : "19", "K" : "20", "L" : "21", "M" : "22", "N" : "23", "O" : "24", "P" : "25", "Q" : "26", "R" : "27", "S" : "28","T" : "29", "U" : "30", "V" : "31", "W" : "32", "X" : "33", "Y" : "34", "Z" : "35"]
        
        var sum = 0
        var m = 0
        let multipliers : [Int] = [7, 3, 1]
        for c in checkString {
            guard let lookup = characterDict["\(c)"],
                let number = Int(lookup) else { return 0 }
            let product = number * multipliers[m]
            sum += product
            m = (m + 1) % 3
        }
        
        return (sum % 10)
    }
}
