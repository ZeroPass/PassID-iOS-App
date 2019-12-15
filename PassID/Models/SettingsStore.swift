//
//  SettingsStore.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import Combine


final class SettingsStore: ObservableObject {
    
    static let DEFAULT_URL: URL              = URL(string: "http://127.0.0.1")!
    static let DEFAULT_TIMEOUT: TimeInterval = 5.0 // 5 secs
    
    
    private enum Keys {
        static let timeout = "timeout"
        static let url     = "url"
    }

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    let objectWillChange = PassthroughSubject<Void, Never>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.timeout: SettingsStore.DEFAULT_TIMEOUT,
            Keys.url: SettingsStore.DEFAULT_URL
        ])

        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .subscribe(objectWillChange)
    }

    var timeout: TimeInterval {
        set { defaults.set(newValue, forKey: Keys.timeout) }
        get { defaults.double(forKey: Keys.timeout) }
    }
    
    var url: URL {
        set { defaults.set(newValue, forKey: Keys.url) }
        get { defaults.url(forKey: Keys.url) ?? SettingsStore.DEFAULT_URL }
    }
}
