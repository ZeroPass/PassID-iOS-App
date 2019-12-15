//
//  AppDelegate.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import UIKit
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let tePassIdServer: ServerTrustEvaluating?
    
    override init() {
        var ste: ServerTrustEvaluating? = nil
        if let scertPath = Bundle.main.path(forResource: "PassIdServer", ofType: "der") {
            if let scertRaw: NSData = NSData(contentsOfFile: scertPath) {
                if let scert = SecCertificateCreateWithData(kCFAllocatorDefault, scertRaw) {
                    ste = PinnedCertificatesTrustEvaluator(
                        certificates: [scert], // Note: Can also use Bundle.main.af.certificates which loads all cer, der certificates from apps bundle
                        acceptSelfSignedCertificates: true,
                        performDefaultValidation: false,
                        validateHost: false
                    )
                }
            }
        }
        
        self.tePassIdServer = ste
        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

