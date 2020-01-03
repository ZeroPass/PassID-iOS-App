//
//  Array+.swift
//  PassID
//
//  Created by smlu on 03/01/2020.
//  Copyright © 2020 ZeroPass. All rights reserved.
//

import Foundation


extension Array where Element == UInt8  {
    func hex() -> String {
        return Utils.dataToHex(Data(self))
    }
}
