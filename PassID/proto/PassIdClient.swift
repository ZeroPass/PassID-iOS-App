//
//  PassIdClient.swift
//  PassID
//
//  Created by smlu on 19/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Alamofire
import Foundation

final class PassIdClient {
    
    typealias Retry = Bool
    
    init(url: URL, timeout: TimeInterval = SettingsStore.DEFAULT_TIMEOUT) {
        self.api = PassIdApi(url: url, timeout: timeout)
    }
    
    var uid: UserId? {
        get{
            return session?.uid
        }
    }
    
    var timeout: TimeInterval {
        get {
            return self.api.timeout
        }
        set {
            self.api.timeout = newValue
        }
    }
    
    var url: URL {
        get{
            return self.api.url
        }
        set {
            self.api.url = newValue
        }
    }
    
    private let api: PassIdApi
    private var challenge: ProtoChallenge? = nil
    private var connectionErrorCallback: ((_ error: AFError, _ completion: @escaping (Retry) -> Void) -> Void)? = nil
    private var session: ProtoSession? = nil

    private func cancelChallenge() {
        if self.challenge != nil {
            self.api.cancelChallenge(challenge: self.challenge!)
        }
    }
}

extension PassIdClient {
    func onConnectionError(callback: ((_ error: AFError, _ completion: @escaping (Retry) -> Void) -> Void)?) -> PassIdClient {
        let copy = self
        copy.connectionErrorCallback = callback
        return copy
    }
}


extension PassIdClient {

    private func requestChallenge(_ completion: @escaping (_ error: ApiError?) -> Void) {
        retriableCall({ rh in
            self.api.getChallenge { r in rh(r) }
        }) { resp in
            guard let challenge = resp.value else {
                completion(resp.error)
                return
            }
            self.challenge = challenge
            completion(nil)
        }
    }
        
    private func retriableCall<T>(_ call: @escaping (_ response: @escaping (ApiResponse<T>) -> Void)->Void, _ completion: @escaping (ApiResponse<T>)->Void) {
        call { resp in
            if case let .connectionError(error) = resp.error {
                self.connectionFailed(error) { retry in
                    if retry {
                        self.retriableCall(call, completion)
                    }
                    else {
                        completion(resp)
                    }
                }
            }
            else {
                completion(resp)
            }
        }
    }
    
    private func connectionFailed(_ error: AFError, _ completion: @escaping (Retry) -> Void) {
        if connectionErrorCallback != nil {
            connectionErrorCallback!(error, completion)
        }
        else {
            completion(false)
        }
    }
}
