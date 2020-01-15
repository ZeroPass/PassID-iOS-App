//
//  PassIdApi.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Alamofire
import SwiftUI
import SwiftyJSON



typealias ApiRequestID = JsonRpcRequest.ID

public enum PassIdApiError : Error {
    case parseError(String)
    case raw(Int, String)
    
    public var message: String {
        switch self {
        case .parseError:
            return "Response parse Error"
        case .raw(_, let msg):
            return msg
        }
    }
    
    public var code: Int {
        switch self {
        case .parseError:
            return 0
        case .raw(let code, _):
            return code
        }
    }
}

public enum ApiError : Error {
    case apiError(PassIdApiError)
    case rpcError(JsonRpcError)
    case connectionError(AFError)
}

struct ApiResponse<Success> {
    public let id: ApiRequestID?
    public let result: Result<Success, ApiError>

    public var value: Success? {
        guard case let .success(value) = result else { return nil }
        return value
    }

    public var error: ApiError? {
        guard case let .failure(error) = result else { return nil }
        return error
    }
    
    init(id: ApiRequestID?, result: Result<Success, ApiError>) {
        self.id = id
        self.result = result
    }
}


class PassIdApi {
    
    var timeout: TimeInterval {
        get {
            return self.rpc.defaultTimeout
        }
        set {
            self.rpc.defaultTimeout = newValue
        }
    }
    
    var url: URL {
        get{
            return self.rpc.url
        }
        set {
            self.rpc.url = newValue
        }
    }
    
    private let rpc: JRPClient
    private let log: Log
    
    init(url: URL, timeout: TimeInterval = SettingsStore.DEFAULT_TIMEOUT) {
        self.log = Log(category: "passid.api")
        let app  = UIApplication.shared.delegate as! AppDelegate
        self.rpc = JRPClient(url: url, defaultTimeout: timeout, ste: app.tePassIdServer)
    }
    

    /* API: passID.ping */
    @discardableResult
    func ping(ping: UInt32, completion: @escaping (ApiResponse<UInt32>)->Void) -> ApiRequestID {
        log.debug("Calling api method: passID.ping(ping: %u)", ping)
        return rpc.call(method: PassIdApi.getApiMethod("ping"), params: ["ping" : ping]) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                let pong = json["pong"].uInt32
                self.log.debug("Api call passID.ping returned pong=%u", ping)
                return pong
            })
        }
    }
    
    /* API: passID.getChallenge */
    @discardableResult
    func getChallenge(completion: @escaping (ApiResponse<ProtoChallenge>)->Void) -> ApiRequestID {
        log.debug("Calling api method: passID.getChallenge()")
        return rpc.call(method: PassIdApi.getApiMethod("getChallenge")) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                let c = ProtoChallenge(json: json)
                if c != nil {
                    self.log.debug("Api call passID.getChallenge returned:")
                    self.log.debug("  challenge: %@", c!.data.hex())
                    self.log.debug("  cid: %@", c!.id.data.hex())
                }
                return c
            })
        }
    }
    
    /* API: passID.cancelChallenge */
    // Notifies server to discard previously requested challenge
    func cancelChallenge(challenge: ProtoChallenge) {
        log.debug("Calling api method: passID.cancelChallenge(")
        self.log.debug("  challenge: %@ )", challenge.data.hex())
        rpc.notify(method: PassIdApi.getApiMethod("cancelChallenge"), params: challenge.toJSON())
    }

    /* API: passID.getChallenge */
    @discardableResult
    func register(dg15: EfDG15, sod: EfSOD, cid: CID, csigs: ChallengeSigs, dg14: EfDG14?, completion: @escaping (ApiResponse<ProtoSession>)->Void) -> ApiRequestID {
        log.debug("Calling api method: passID.register()")
        self.log.debug("  dg15:  %@", dg15.encoded.hex())
        self.log.debug("  sod:   %@", sod.encoded.hex())
        self.log.debug("  cid:   %@", cid.data.hex())
        self.log.debug("  csigs: %@", csigs.sigs.map { String($0.hex())})
        self.log.debug("  dg14:  %@", dg14?.encoded.hex() ?? "<nil>")

        var params = try! dg15.toJSON() + sod + cid + csigs
        if dg14 != nil {
            try! params += dg14!
        }

        return rpc.call(method: PassIdApi.getApiMethod("register"), params: params) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                let s = ProtoSession(json: json)
                if s != nil {
                    self.log.debug("Api call passID.register returned proto session:")
                    self.log.debug("  uid: %@", s!.uid.data.hex())
                    self.log.debug("  key: %@", s!.key.data.hex())
                    self.log.debug("  session expires: %u", s!.expiration.timeIntervalSince1970)
                }
                return s
            })
        }
    }

    @discardableResult
    func login(uid: UserId, dg1: LDSFile? = nil, cid: CID, csigs: ChallengeSigs, completion: @escaping (ApiResponse<ProtoSession>)->Void) -> ApiRequestID {
        log.debug("Calling api method: passID.login()")
        self.log.debug("  uid:   %@", uid.data.hex())
        self.log.debug("  dg1:   %@", dg1?.encoded.hex() ?? "<nil>")
        self.log.debug("  cid:   %@", cid.data.hex())
        self.log.debug("  csigs: %@", csigs.sigs.map { String($0.hex())})

        var params = try! uid.toJSON() + cid + csigs
        if dg1 != nil {
            try! params += dg1!
        }

        return rpc.call(method: PassIdApi.getApiMethod("login"), params: params) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                let s = ProtoSession(json: json, uid: uid)
                if s != nil {
                    self.log.debug("Api call passID.login returned proto session:")
                    self.log.debug("  key: %@", s!.key.data.hex())
                    self.log.debug("  session expires: %u", s!.expiration.timeIntervalSince1970)
                }
                return s
            })
        }
    }
    
    @discardableResult
    func sayHello(s: ProtoSession, completion: @escaping (ApiResponse<String>)->Void) -> ApiRequestID {
        log.debug("Calling api method: passID.sayHello()")
        let mac = s.getMAC(apiName: "sayHello", rawParams: s.uid.data)
        let params = try! s.uid.toJSON() + mac
        
        self.log.debug("  uid:   %@", s.uid.data.hex())
        self.log.debug("  mac:   %@", mac.data.hex())
        
        return rpc.call(method: PassIdApi.getApiMethod("sayHello"), params: JSON(params)) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                let greeting = json["msg"].string
                if greeting != nil {
                    self.log.debug("Api call passID.sayHello returned greeting: %@", greeting!)
                }
                return greeting
            })
        }
    }
    
    
    static private func getApiMethod(_ name: String) -> String {
        return "passID." + name
    }
    
    func handleResponse<Value>(_ response: Result<JRPCResult, JRPCError>, _ completion: (ApiResponse<Value>)->Void, valueConstructor: (_ json: JSON) -> Value?) {
        var reqId: ApiRequestID? = nil
        var result: Result<Value, ApiError>? = nil
         
        switch response {
            case .success(let rpcResult): do {
                reqId = rpcResult.id
                if let value = valueConstructor(rpcResult.data) {
                    result = .success(value)
                }
                else {
                    log.error("Failed to parse Api call response!")
                    log.error("  Response data: %@", rpcResult.data.rawString() ?? "<nil>")
                    result = .failure(.apiError(.parseError(
                        "Could not parse rpc response data."
                    )))
                }
            }
            case .failure(let error): do {
                switch error {
                    case .rpcError(let rpcError):
                        if rpcError.code > -32000  {
                            log.error("Api call returned error with code: %d and msg: %@", rpcError.code, rpcError.message)
                            result = .failure(.apiError(.raw(rpcError.code, rpcError.message)))
                        }
                        else {
                            log.error("Api error: %@", rpcError.localizedDescription)
                            result = .failure(.rpcError(rpcError))
                        }
                    case .connectionError(let aferror):
                        log.error("Connection error: %@", aferror.localizedDescription)
                        result = .failure(.connectionError(aferror))
                }
            }
        }
        
        // Call completion callback with api response
        completion(ApiResponse(id: reqId, result: result!))
    }
}
