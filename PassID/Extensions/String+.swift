//
//  String+.swift
//  PassID
//
//  Created by smlu on 03/01/2020.
//  Copyright © 2020 ZeroPass. All rights reserved.
//

import Foundation


extension String {
    func removePrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func rstrip(_ stripChars: CharacterSet = .whitespacesAndNewlines)-> String {
        var s = self
        while s.last?.unicodeScalars.contains(where: { stripChars.contains($0)}) ?? false {
            s = String(s.dropLast())
        }
        return String(s)
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
