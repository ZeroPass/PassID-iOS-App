//
//  ResponseAPDU.swift
//  PassID
//
//  Created by smlu on 22/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation

@available(iOS 13, *)
public struct ResponseAPDU {
    
    public var data : [UInt8]
    public var sw1 : UInt8
    public var sw2 : UInt8

    public init(data: [UInt8], sw1: UInt8, sw2: UInt8) {
        self.data = data
        self.sw1 = sw1
        self.sw2 = sw2
    }
}
