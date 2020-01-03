//
//  ChallengeSigs.swift
//  PassID
//
//  Created by smlu on 25/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import SwiftyJSON


struct ChallengeSigs {

    internal static let serKey = "csigs"
    var sigs: [Data]

    init () {
        sigs = []
    }
    
    init(sigs: [Data]) {
        self.sigs = sigs
    }
    
    init?(json: JSON) {
        guard let b64Sigs = json[ChallengeSigs.serKey].array else {
            return nil
        }
        
        sigs = [Data]()
        for b64s in b64Sigs {
            sigs.append(Data(base64Encoded: b64s.string!)!)
        }
    }
    
    func isEmpty() -> Bool {
        return sigs.isEmpty
    }
    
    func toJSON() -> JSON {
        var b64Sigs = [String]()
        for s in sigs {
            b64Sigs.append(s.base64EncodedString())
        }
        return [ ChallengeSigs.serKey : b64Sigs ]
    }
    
    mutating func append(_ sig: Data) {
        self.sigs.append(sig)
    }
}
