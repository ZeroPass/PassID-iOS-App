//
//  CryptoUtils.swift
//  PassID
//
//  Created by smlu on 22/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import CryptoKit

func randomBytes(_ count: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    if status == errSecSuccess { // Always test the status.
        print(bytes)
        // Prints something different every time you run.
    }
    return bytes
}

@available(iOS 13, *)
func sha1(_ data: [UInt8]) -> [UInt8] {
    var sha1 = Insecure.SHA1()
    sha1.update(data: data)
    return Array(sha1.finalize())
}
