//
//  MRZ.swift
//  PassID
//
//  Created by smlu on 07/01/2020.
//  Copyright © 2020 ZeroPass. All rights reserved.
//

import Foundation


enum MRZVersion {
    case td1
    case td2
    case td3
}

struct MRZ {
    static let dateFormat: String = "yyMMdd"
    
    var country: String = ""
    var dateOfBirth: Date = Date()
    var dateOfExpiry: Date = Date()
    var documentCode: String = ""
    var documentNumber: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var nationality: String = ""
    var optionalData: String = ""
    var optionalData2: String = ""
    var sex: String = ""
    var version: MRZVersion = .td1
    
    static func dateToString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = MRZ.dateFormat
        return df.string(from: date)
    }
    
    static func calculateChecksum( _ checkString : String ) -> Int {
        let characterDict  = [
            "0" :  "0",  "1" :  "1",
            "2" :  "2",  "3" :  "3",
            "4" :  "4",  "5" :  "5",
            "6" :  "6",  "7" :  "7",
            "8" :  "8",  "9" :  "9",
            "<" :  "0",  " " :  "0",
            "A" : "10",  "B" : "11",
            "C" : "12",  "D" : "13",
            "E" : "14",  "F" : "15",
            "G" : "16",  "H" : "17",
            "I" : "18",  "J" : "19",
            "K" : "20",  "L" : "21",
            "M" : "22",  "N" : "23",
            "O" : "24",  "P" : "25",
            "Q" : "26",  "R" : "27",
            "S" : "28",  "T" : "29",
            "U" : "30",  "V" : "31",
            "W" : "32",  "X" : "33",
            "Y" : "34",  "Z" : "35"
        ]
        
        var sum = 0
        var m   = 0
        let multipliers: [Int] = [7, 3, 1]
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


struct MRZParseError : Error {
    let what: String
    
    init(_ errorMsg: String = "") {
        what = errorMsg
    }
}

extension MRZ {
    init(encoded: Data) throws {
        try parse(encoded)
    }
    
    private mutating func parse(_ data: Data) throws {
        var istream = InputStream(data: data)
        istream.open()
        if data.count == 90 {
            version = .td1
            try parseTD1(&istream)
        }
        else if data.count == 72 {
            version = .td2
            try parseTD2(&istream)
        }
        else if data.count == 88 {
            version = .td3
            try parseTD3(&istream)
        }
        else {
            throw MRZParseError("Invalid MRZ data")
        }
    }
    
    private mutating func parseTD1(_ istream: inout InputStream) throws {
        documentCode   = try MRZ.read(&istream, 2)
        country        = try MRZ.read(&istream, 3)
        documentNumber = try MRZ.read(&istream, 9)
        let cdDocNum   = try MRZ.readWithPad(&istream, 1)
        optionalData   = try MRZ.read(&istream, 15)
        dateOfBirth    = try MRZ.readDate(&istream)
        
        try MRZ.assertChecksum(MRZ.dateToString(dateOfBirth), try MRZ.readInt(&istream, 1),
            "Data of Birth check digit mismatch"
        )
        
        sex            = try MRZ.read(&istream, 1)
        dateOfExpiry   = try MRZ.readDate(&istream)
        
        try MRZ.assertChecksum(MRZ.dateToString(dateOfExpiry), try MRZ.readInt(&istream, 1),
            "Data of Expiry check digit mismatch"
        )
        
        nationality    = try MRZ.read(&istream, 3)
        optionalData2  = try MRZ.read(&istream, 11)
        let cdComposit = try MRZ.readInt(&istream, 1)
        self.setNames(try MRZ.readNameIdentifiers(&istream, 30))

        if cdDocNum == "<" && optionalData.count > 2 {
            documentNumber += optionalData[0..<optionalData.count - 1]
            try MRZ.assertChecksum(documentNumber, Int(String(optionalData.last!))!,
                "Document Number check digit mismatch"
            )
            optionalData = optionalData2
            optionalData2 = ""
        }
    }
    
    private mutating func parseTD2(_ istream: inout InputStream) throws {
        documentCode   = try MRZ.read(&istream, 2)
        country        = try MRZ.read(&istream, 3)
        self.setNames(try MRZ.readNameIdentifiers(&istream, 31))
        
        documentNumber = try MRZ.read(&istream, 9)
        try MRZ.assertChecksum(documentNumber, try MRZ.readInt(&istream, 1),
            "Document Number check digit mismatch"
        )
        
        nationality    = try MRZ.read(&istream, 3)
        dateOfBirth    = try MRZ.readDate(&istream)
        try MRZ.assertChecksum(MRZ.dateToString(dateOfBirth), try MRZ.readInt(&istream, 1),
            "Data of Birth check digit mismatch"
        )
        
        sex            = try MRZ.read(&istream, 1)
        dateOfExpiry   = try MRZ.readDate(&istream)
        try MRZ.assertChecksum(MRZ.dateToString(dateOfExpiry), try MRZ.readInt(&istream, 1),
            "Data of Expiry check digit mismatch"
        )
        
        optionalData   = try MRZ.read(&istream, 7)
        let cdComposit = try MRZ.readInt(&istream, 1)
    }
    
    private mutating func parseTD3(_ istream: inout InputStream) throws {
        documentCode   = try MRZ.read(&istream, 2)
        country        = try MRZ.read(&istream, 3)
        self.setNames(try MRZ.readNameIdentifiers(&istream, 39))

        documentNumber = try MRZ.read(&istream, 9)
        try MRZ.assertChecksum(documentNumber, try MRZ.readInt(&istream, 1),
           "Document Number check digit mismatch"
        )

        nationality    = try MRZ.read(&istream, 3)
        dateOfBirth    = try MRZ.readDate(&istream)
        try MRZ.assertChecksum(MRZ.dateToString(dateOfBirth), try MRZ.readInt(&istream, 1),
           "Data of Birth check digit mismatch"
        )

        sex            = try MRZ.read(&istream, 1)
        dateOfExpiry   = try MRZ.readDate(&istream)
        try MRZ.assertChecksum(MRZ.dateToString(dateOfExpiry), try MRZ.readInt(&istream, 1),
           "Data of Expiry check digit mismatch"
        )

        optionalData   = try MRZ.read(&istream, 14)
        try MRZ.assertChecksum(optionalData, try MRZ.readInt(&istream, 1),
           "Optional data check digit mismatch"
        )
        
        let cdComposit = try MRZ.readInt(&istream, 1)
    }
    
    private mutating func setNames(_ nameIds: [String]) {
        if nameIds.count > 0 {
            lastName = nameIds[0]
        }
        if nameIds.count > 1 {
            firstName = nameIds[1...].joined(separator: " ")
        }
    }
    
    private static func read(_ istream: inout InputStream, _ maxLength: Int) throws -> String {
        return try readWithPad(&istream, maxLength).rstrip(CharacterSet(charactersIn: "<"))
    }
    
    private static func readDate(_ istream: inout InputStream) throws -> Date {
        let df = DateFormatter()
        df.dateFormat = MRZ.dateFormat
        return df.date(from: try read(&istream, 6))!
    }
    
    private static func readInt(_ istream: inout InputStream, _ maxLength: Int) throws -> Int {
        return try Int(read(&istream, maxLength))!
    }
    
    private static func readNameIdentifiers(_ istream: inout InputStream, _ maxLength: Int) throws -> [String] {
        let nameField = try read(&istream, maxLength)
        var ids = nameField.components(separatedBy: "<<")
        for i in 0 ..< ids.count {
            ids[i] = ids[i].replacingOccurrences(of: "<", with: " ")
        }
        return ids
    }
    
    private static func readWithPad(_ istream: inout InputStream, _ maxLength: Int) throws -> String {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxLength + 1)
        defer {
            buffer.deallocate()
        }

        if istream.read(buffer, maxLength: maxLength) != maxLength {
            throw istream.streamError!
        }
        
        buffer[maxLength] = 0
        return String(cString: buffer)
    }
    
    private static func assertChecksum(_ value: String, _ csum: Int, _ errorMsg: String) throws {
        if calculateChecksum(value) != csum {
            throw MRZParseError(errorMsg)
        }
    }
}
