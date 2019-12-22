//
//  ProtoObject.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import SwiftyJSON


protocol ProtoObject {
    static var serKey: String { get }
    var data: Data { get }
    
    init?(data: Data)
    init?(json: JSON)
    func toJSON() -> JSON
}
