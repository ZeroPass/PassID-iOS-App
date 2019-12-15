//
//  JRPClient.swift
//  PassID
//
//  Created by smlu on 4/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON


public enum JRPCError : Error{
    case rpcError(JsonRpcError)
    case connectionError(AFError)
}

public struct JRPCResult {
    let id: JsonRpcRequest.ID?
    let data: JSON
}

class JRPClient {
    
    var defaultTimeout: TimeInterval
    var userAgent: String? = nil
    var origin: String? = nil
    
    private var url: URL
    private var session: Session
    
    init(url: URL, defaultTimeout: TimeInterval = SettingsStore.DEFAULT_TIMEOUT, ste: ServerTrustEvaluating? = nil) {
        self.url = url
        self.defaultTimeout = defaultTimeout
        self.session = JRPClient.makeSession(url: url, ste: ste)
    }
    
    func setUrl(_ url: URL) {
        self.url = url
        if let tm = self.session.serverTrustManager {
            if let ste = tm.evaluators.first?.value {
                self.session = self.makeSession(ste: ste)
            }
        }
    }
    
    func call(method: String, params: JSON, completion: @escaping (Result<JRPCResult, JRPCError>)->Void) {
        self.call(method: method, params: params, timeout: self.defaultTimeout, completion: completion)
    }
    
    func call(method: String, params: JSON, timeout: TimeInterval, completion: @escaping (Result<JRPCResult, JRPCError>)->Void) {
        let jrpcReq = JsonRpcRequest(id: .string(UUID().uuidString), method: method, params: params).toJSON()
        
        var req = URLRequest(url: self.url, timeoutInterval: timeout)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = self.makeHttpHeader()
        req.httpBody = try? jrpcReq.rawData()

        self.session.request(req).responseJSON{ response in
            _ = self.session // Capture session in case self is destroyed before this closure is called.
            switch response.result {
            case .success(let value):
                let rpcResponse = JsonRpcResponse(json: JSON(value))
                if (rpcResponse.error != nil) {
                    completion(.failure(JRPCError.rpcError(rpcResponse.error!)))
                }
                else {
                    completion(.success(JRPCResult(id: rpcResponse.id, data: rpcResponse.result!)))
                }
            case .failure(let error):
                completion(.failure(JRPCError.connectionError(error)))
            }
        }
    }
    

    private func makeSession(ste: ServerTrustEvaluating?) -> Session {
        return JRPClient.makeSession(url: self.url, ste: ste)
    }
    
    private static func makeSession(url: URL, ste: ServerTrustEvaluating?) -> Session {
        let host = url.host
        if host != nil && ste != nil {
            let tm = ServerTrustManager(evaluators: [host! : ste!])
            return Session(serverTrustManager: tm)
        }
        return Session.default
    }
    
    private func makeHttpHeader() -> [String : String] {
        var header = [
             "Accept" : "application/json",
             "Content-type" : "application/json"
        ]
        
        if (self.userAgent != nil) {
            header["User-Agent"] = self.userAgent
        }
        
        if (self.origin != nil) {
            header["Origin"] = self.origin
        }
        
        return header
    }
}
