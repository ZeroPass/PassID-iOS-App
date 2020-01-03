//
//  Dictionary+.swift
//  PassID
//
//  Created by smlu on 02/01/2020.
//  Copyright © 2020 ZeroPass. All rights reserved.
//

import Foundation


// method: merge
extension Dictionary {
    mutating func merge(_ dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}

// method: contains
extension Dictionary {
    func contains(_ key: Key) -> Bool {
        return self[key] != nil
    }
}


