//
//  JSON+.swift
//  PassID
//
//  Created by smlu on 03/01/2020.
//  Copyright © 2020 ZeroPass. All rights reserved.
//

import Foundation
import SwiftyJSON


extension JSON {
    static func + (_ lhs: JSON, _ rhs: ProtoObject) throws -> JSON {
        var lhs = lhs
        try lhs.merge(with: rhs.toJSON())
        return lhs
    }
    
    static func + (_ lhs: JSON, _ rhs: JSON) throws -> JSON {
        var lhs = lhs
        try lhs.merge(with: rhs)
        return lhs
    }
    
    static func += (_ lhs: inout JSON, _ rhs: ProtoObject) throws {
        lhs = try lhs.merged(with: rhs.toJSON())
    }
}
