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
    
    init(url: URL, timeout: TimeInterval = SettingsStore.DEFAULT_TIMEOUT) {
        let app  = UIApplication.shared.delegate as! AppDelegate
        self.rpc = JRPClient(url: url, defaultTimeout: timeout, ste: app.tePassIdServer)
    }
    

    /* API: passID.ping */
    @discardableResult
    func ping(ping: UInt32, completion: @escaping (ApiResponse<UInt32>)->Void) -> ApiRequestID {
        return rpc.call(method: PassIdApi.getApiMethod("ping"), params: ["ping" : ping]) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                return json["pong"].uInt32
            })
        }
    }
    
    /* API: passID.getChallenge */
    @discardableResult
    func getChallenge(completion: @escaping (ApiResponse<ProtoChallenge>)->Void) -> ApiRequestID {
        return rpc.call(method: PassIdApi.getApiMethod("getChallenge")) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                return ProtoChallenge(json: json)
            })
        }
    }
    
    /* API: passID.cancelChallenge */
    // Notifies server to discard previously requested challenge
    func cancelChallenge(challenge: ProtoChallenge) {
        rpc.notify(method: PassIdApi.getApiMethod("cancelChallenge"), params: challenge.toJSON())
    }
    
    
    static private func getApiMethod(_ name: String) -> String {
        return "passID." + name
    }
    
    /* API: passID.getChallenge */
    @discardableResult
    func register(cid: CID, passportData: PassportData, completion: @escaping (ApiResponse<ProtoSession>)->Void) -> ApiRequestID {
        guard let dg15 = passportData.ldsFiles[.efDG15] else {
            return .number(-1)
        }
        
        guard let sod = passportData.ldsFiles[.efSOD] else {
            return .number(-1)
        }
        
        guard let dg14 = passportData.ldsFiles[.efDG14] else {
            return .number(-1)
        }
        
        var params = ["dg15" : JSON(dg15.encoded.base64EncodedString())]
        params.merge(["sod" : JSON(sod.encoded.base64EncodedString())])
        params.merge(cid.toJSON().dictionary!)
        params.merge(passportData.csigs.toJSON().dictionary!)
        params.merge(["dg14" : JSON(dg14.encoded.base64EncodedString())])

        return rpc.call(method: PassIdApi.getApiMethod("register"), params: JSON(params)) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                return ProtoSession(json: json)
            })
        }
    }
    
    @discardableResult
    func login(uid: UserId, dg1: LDSFile? = nil, cid: CID, csigs: ChallengeSigs, completion: @escaping (ApiResponse<ProtoSession>)->Void) -> ApiRequestID {
        var params = uid.toJSON().dictionary!
        params.merge(cid.toJSON().dictionary!)
        params.merge(csigs.toJSON().dictionary!)
        
        if dg1 != nil {
            params.merge(["dg1" : JSON(dg1!.encoded.base64EncodedString())])
        }

        return rpc.call(method: PassIdApi.getApiMethod("login"), params: JSON(params)) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                guard let key = SessionKey(json: json) else {
                    return nil
                }
                
                guard let expires = json["expires"].int else {
                    return nil
                }
                return ProtoSession(uid: uid, key: key, expiration: Date(timeIntervalSince1970: TimeInterval(expires)))
            })
        }
    }
    
    @discardableResult
    func sayHello(s: ProtoSession, completion: @escaping (ApiResponse<String>)->Void) -> ApiRequestID {
        let mac = s.getMAC(apiName: "sayHello", rawParams: s.uid.data)
        var params = s.uid.toJSON().dictionary!
        params.merge(mac.toJSON().dictionary!)

        return rpc.call(method: PassIdApi.getApiMethod("sayHello"), params: JSON(params)) { response in
            self.handleResponse(response, completion, valueConstructor: { json in
                return json["msg"].string!
            })
        }
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
                    result = .failure(.apiError(.parseError(
                        "Could not parse rpc response data. rpcResult.data=\(rpcResult.data)"
                    )))
                }
            }
            case .failure(let error): do {
                switch error {
                    case .rpcError(let rpcError):
                        if rpcError.code > -32000  {
                            result = .failure(.apiError(.raw(rpcError.code, rpcError.message)))
                        }
                        else {
                            result = .failure(.rpcError(rpcError))
                        }
                    case .connectionError(let aferror):
                        result = .failure(.connectionError(aferror))
                }
            }
        }
        
        // Call completion callback with api response
        completion(ApiResponse(id: reqId, result: result!))
    }
}
