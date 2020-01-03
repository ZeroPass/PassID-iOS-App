//
//  PassIdClient.swift
//  PassID
//
//  Created by smlu on 19/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Alamofire
import Foundation


enum PassIdClientError: Error {
    case missingRequiredLDSFile(LDSFileTag)
    case missingChallengeSigs
    case sessionNotEstablished
    case unsupportedPassport
}


final class PassIdClient {
    
    typealias Retry = Bool
    
    init(url: URL, timeout: TimeInterval = SettingsStore.DEFAULT_TIMEOUT) {
        self.api = PassIdApi(url: url, timeout: timeout)
    }
    
    deinit {
        cancelChallenge()
    }
    
    final class SessionPromise {
        private var challengeCallback: ((_ challenge: ProtoChallenge, _ completion: @escaping (PassportData) throws -> ()) -> Void)? = nil
        private var successCallback: ((_ uid: UserId) -> ())? = nil
        private var errorCallback: ((_ error: ApiError) -> ())? = nil
    }
    
    private let api: PassIdApi
    private var challenge: ProtoChallenge? = nil
    private var session: ProtoSession? = nil
    
    private var connectionErrorCallback: ((_ error: AFError, _ completion: @escaping (Retry) -> Void) -> ())? = nil
    private var dg1RequestCallback: ((_ completion: @escaping (_ sendDG1: Bool) -> Void) -> ())? = nil
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
    func onConnectionError(callback: ((_ error: AFError, _ completion: @escaping (Retry) -> ()) -> Void)?) -> PassIdClient {
        self.connectionErrorCallback = callback
        return self
    }
    
    @discardableResult
    func onDG1Requested(callback: @escaping (_ completion: @escaping (_ sendDG1: Bool) -> Void) -> ()) -> PassIdClient {
        self.dg1RequestCallback = callback
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
                scb.challenge(self.challenge!) { [weak self] data in
                    try self?.requestRegister(cid: (self?.challenge!.id)!, passportData: data) {
                        [weak self] error in
                        self?.challenge = nil
                        if error != nil {
                            scb.error(error!)
                        }
                        else {
                            if self != nil {
                                scb.success(self!.session!.uid)
                            }
                        }
                    }
                }
            }
        }
        
        return scb
    }
    
    func login() -> SessionPromise {
        let scb = SessionPromise()
        requestChallenge{ error in
            if error != nil {
                scb.error(error!)
            }
            else {
                scb.challenge(self.challenge!) { [weak self] data in
                    try self?.requestLogin(cid: (self?.challenge!.id)!, passportData: data) {
                        [weak self] error in
                        self?.challenge = nil
                        if error != nil {
                            scb.error(error!)
                        }
                        else {
                            if self != nil {
                                scb.success(self!.session!.uid)
                            }
                        }
                    }
                }
            }
        }

        return scb
    }
    
    func requestGreeting(_ completion: @escaping (_ greeting: String?, _ error: ApiError?) -> Void) {
        retriableCall({ rh in
            self.api.sayHello(s: self.session!) { r in rh(r) }
        }) { resp in
            guard let greeting = resp.value else {
                completion(nil, resp.error)
                return
            }
            completion(greeting, nil)
        }
    }
}


extension PassIdClient.SessionPromise {

    @discardableResult
    func onChallenge(_ cb: @escaping (_ challenge: ProtoChallenge, _ completion: @escaping (PassportData) throws -> ()) -> Void) -> PassIdClient.SessionPromise {
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
        retriableCall({ [weak self] rh in
            self?.api.getChallenge { r in rh(r) }
        }) { [weak self] resp in
            guard let challenge = resp.value else {
                completion(resp.error)
                return
            }
            self?.challenge = challenge
            completion(nil)
        }
    }
    
    private func requestRegister(cid: CID, passportData data: PassportData, _ completion: @escaping (_ error: ApiError?) -> Void) throws {
        try requiredPassportData(data, requiredFiles: [.efSOD, .efDG1, .efDG15])
        
        retriableCall({ [weak self] rh in
            self?.api.register(cid: cid, passportData: data) { r in rh(r) }
        }) { [weak self] resp in
            guard let session = resp.value else {
                completion(resp.error)
                return
            }
            self?.session = session
            completion(nil)
        }
    }
    
    private func requestLogin(cid: CID, passportData data: PassportData, sendDG1: Bool = false, _ completion: @escaping (_ error: ApiError?) -> Void) throws {
        try requiredPassportData(data, requiredFiles: [.efDG1, .efDG15])
        let uid =  UserId.fromDG15(data.ldsFiles[.efDG15]!)!
        
        retriableCall({ [weak self] rh in
            // TODO safely check dg1 & dg15 is in ldsFiles
            self?.api.login(uid: uid, dg1: sendDG1 ? data.ldsFiles[.efDG1]! : nil, cid: cid, csigs: data.csigs) { r in rh(r) }
        }) { [weak self] resp in
            guard let session = resp.value else {
                switch resp.error {
                case .apiError(let apiError):
                    if apiError.code != 428 {
                        completion(resp.error)
                    }
                    else { // Handle request for DG1 file
                        self?.dg1Requested { sendDG1 in
                            if sendDG1 {
                                try! self?.requestLogin(cid: cid, passportData: data, sendDG1: true, completion)
                            }
                            else {
                                completion(resp.error)
                            }
                        }
                    }
                default:
                    completion(resp.error)
                }
                
                return
            }
            self?.session = session
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
    
    
    private func requiredPassportData(_ data: PassportData, requiredFiles: [LDSFileTag]) throws {
        for tag in requiredFiles {
            if !data.ldsFiles.contains(tag) {
                throw PassIdClientError.missingRequiredLDSFile(tag)
            }
        }
        
        if data.csigs.isEmpty() {
            throw PassIdClientError.missingChallengeSigs
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
    
    private func dg1Requested(_ completion: @escaping (_ sendDG1: Bool) -> Void) {
        if dg1RequestCallback != nil {
            dg1RequestCallback!(completion)
        }
        else {
            completion(false)
        }
    }
}

extension PassIdClient.SessionPromise {
    
    func challenge(_ challenge: ProtoChallenge, _ completion: @escaping (PassportData) throws -> ()) {
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


