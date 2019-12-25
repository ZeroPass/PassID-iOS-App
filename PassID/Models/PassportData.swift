//
//  PassportData.swift
//  PassID
//
//  Created by smlu on 25/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation

struct PassportData {
    let ldsFiles: [LDSFileTag : LDSFile]
    let csigs: ChallengeSigs
}
