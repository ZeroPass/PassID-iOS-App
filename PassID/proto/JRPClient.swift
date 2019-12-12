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
    var url: URL
    var defaultTimeout: TimeInterval
    var userAgent: String? = nil
    var origin: String? = nil
    
    init(url: URL, defaultTimeout: TimeInterval = SettingsStore.DEFAULT_TIMEOUT) {
        self.url = url
        self.defaultTimeout = defaultTimeout
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

        AF.request(req).responseJSON{ response in
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
