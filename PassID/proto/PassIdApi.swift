//
//  PassIdApi.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftyJSON

typealias ApiRequestID = JsonRpcRequest.ID

public enum PassIdApiError : Error {
    case parseError(String)
    case raw(Int, String)
}

public enum ApiError : Error {
    case apiError(PassIdApiError)
    case rpcError(JsonRpcError)
    case connectionError(JRPCError)
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
    
    func handleResponse<Value>(_ response: Result<JRPCResult, JRPCError>, _ completion: (ApiResponse<Value>)->Void, valueConstructor: (_ json: JSON) -> Value?) {
        var reqId: ApiRequestID? = nil
        var result: Result<Value, ApiError>? = nil
         
        switch response {
            case .success(let rpcResult):
                reqId = rpcResult.id
                if let value = valueConstructor(rpcResult.data) {
                    result = .success(value)
                }
                else {
                    result = .failure(.apiError(.parseError(
                        "Could not parse rpc response data. rpcResult.data=\(rpcResult.data)"
                    )))
                }
            case .failure(let error):
                switch error {
                    case .rpcError(let rpcError):
                        if rpcError.code > -32000  {
                            result = .failure(.apiError(.raw(rpcError.code, rpcError.message)))
                        }
                        else {
                            result = .failure(.rpcError(rpcError))
                        }
                    default:
                        result = .failure(.connectionError(error))
                }
        }
        
        // Call completion callback with api response
        completion(ApiResponse(id: reqId, result: result!))
    }
}
