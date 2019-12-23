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
    
    deinit {
        cancelChallenge()
    }
    
    final class SessionPromise {
        private var challengeCallback: ((_ challenge: ProtoChallenge, _ completion: @escaping (/*PassportData*/) -> ()) -> Void)? = nil
        private var successCallback: ((_ uid: UserId) -> ())? = nil
        private var errorCallback: ((_ error: ApiError) -> ())? = nil
    }
    
    private let api: PassIdApi
    private var challenge: ProtoChallenge? = nil
    private var connectionErrorCallback: ((_ error: AFError, _ completion: @escaping (Retry) -> Void) -> Void)? = nil
    private var session: ProtoSession? = nil
}

extension PassIdClient {
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
}

extension PassIdClient {
    
    @discardableResult
    func onConnectionError(callback: ((_ error: AFError, _ completion: @escaping (Retry) -> Void) -> Void)?) -> PassIdClient {
        self.connectionErrorCallback = callback
        return self
    }
    
    func cancelChallenge() {
        if self.challenge != nil {
            self.api.cancelChallenge(challenge: self.challenge!)
        }
    }
    
    func register() -> SessionPromise {
        let scb = SessionPromise()
        requestChallenge{ error in
            if error != nil {
                scb.error(error!)
            }
            else {
                scb.challenge(self.challenge!) { /*data in */
                    /*
                     self.requestRegister(data.dg15, data.sod, self.challenge!.id, data.csigs, data.dg14) {
                        resp in
                        if resp.error != nil {
                            scb.error(resp.error!)
                        }
                        else {
                            self.session = resp.value!
                            scb.success(self.session.uid)
                        }
                     }
                     */
                }
            }
        }
        
        return scb
    }
}

extension PassIdClient.SessionPromise {

    @discardableResult
    func onChallenge(_ cb: @escaping (_ challenge: ProtoChallenge, _ completion: @escaping (/*PassportData*/) -> ()) -> Void) -> PassIdClient.SessionPromise {
        self.challengeCallback = cb
        return self
    }
    
    @discardableResult
    func onSuccess(_ cb: @escaping (_ uid: UserId) -> ()) -> PassIdClient.SessionPromise {
        self.successCallback = cb
        return self
    }
    
    @discardableResult
    func onError(_ cb: @escaping (_ error: ApiError) -> ()) -> PassIdClient.SessionPromise {
        self.errorCallback = cb
        return self
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

extension PassIdClient.SessionPromise {
    
    func challenge(_ challenge: ProtoChallenge, _ completion: @escaping (/*PassportData*/) -> ()) {
        if challengeCallback != nil {
            challengeCallback!(challenge, completion)
        }
    }
    
    func success(_ uid: UserId) {
        if successCallback != nil {
            successCallback!(uid)
        }
    }

    func error(_ error: ApiError) {
        if errorCallback != nil {
            errorCallback!(error)
        }
    }
}


