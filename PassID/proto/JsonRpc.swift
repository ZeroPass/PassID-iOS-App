//
//  JsonRpc.swift
//  PassID
//
//  Created by smlu on 04/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//


import SwiftyJSON


// Implementation of JSON-RPC 2.0 structures (JsonRpcRequest, JsonRpcResponse, JsonRpcError).
// Batching of requests and responses is not supported.

public enum JsonRpcError: Error {
    case parseError
    case invalidRequest
    case methodNotFound
    case invalidParams
    case internalError
    case invalidResponse
    case serverError
    case raw(Int, String, JSON? = nil)
}

extension JsonRpcError {
    
    public var message: String {
        switch self {
        case .parseError:
            return "Parse Error"
        case .invalidRequest:
            return "Invalid Request"
        case .methodNotFound:
            return "Method Not Found"
        case .invalidParams:
            return "Invalid Params"
        case .internalError:
            return "Internal error"
        case .invalidResponse:
            return "Invalid Response"
        case .serverError:
            return "Server error"
        case .raw(_, let msg, _):
            return msg
        }
    }
    
    public var code: Int {
        switch self {
        case .parseError:
            return -32700
        case .invalidRequest:
            return -32600
        case .methodNotFound:
            return -32601
        case .invalidParams:
            return -32602
        case .internalError:
            return -32603
        case .invalidResponse: // Not in the spec
            return -32300
        case .serverError:
            return -32000
        case .raw(let code, _, _):
            return code
        }
    }
    
    public var data: JSON? {
        switch self {
        case .raw(_, _, let data):
            return data
        default:
            return nil
        }
    }
    
    public init?(value: Int) {
        switch value {
        case JsonRpcError.parseError.code:
            self = .parseError
        case JsonRpcError.invalidRequest.code:
            self = .invalidRequest
        case JsonRpcError.methodNotFound.code:
            self = .methodNotFound
        case JsonRpcError.invalidParams.code:
            self = .invalidParams
        case JsonRpcError.internalError.code:
            self = .internalError
        default:
            if (-32099)...(-32000) ~= value {
                self = .serverError
            }
            return nil
        }
    }
}


// Represents JSON RPC v2.0 request
public class JsonRpcRequest {
    public enum ID {
        case number(Int)
        case string(String)
        
        public var number: Int? {
            switch self {
            case .number(let val):
                return val
            default:
                return nil
            }
        }
        
        public var string: String? {
            switch self {
            case .string(let val):
                return val
            default:
                return nil
            }
        }
    }
    

    public static let version = "2.0"
    public let id: ID?
    public let method: String
    public let params: JSON?
    
    public init(id: ID? = nil, method: String, params: JSON?){
        self.id = id
        self.method = method
        self.params = params
    }
}


extension JsonRpcRequest {
    public func toJSON() -> JSON {
        var json: JSON = ["jsonrpc": JsonRpcRequest.version]
        
        if let id = id?.number {
            json["id"].int = id
        } else if let id = id?.string {
            json["id"].string = id
        }
        else {
            json["id"] = .null
        }
        
        json["method"].string = method
        if let params = params {
            json["params"].object = params
        }
        
        return json
    }
}


// Represents JSON RPC v2.0 response
public struct JsonRpcResponse {
    public static let version = "2.0"
    public let id: JsonRpcRequest.ID?
    public let result: JSON?
    public let error: JsonRpcError?
    
    public init(id: JsonRpcRequest.ID? = nil, result: JSON? = nil){
        self.id = id
        self.result = result
        self.error = nil
    }
    
    public init(id: JsonRpcRequest.ID? = nil, error: JsonRpcError? = nil){
        self.id = id
        self.result = nil
        self.error = error
    }
}


extension JsonRpcResponse {
    public init(json: JSON){
        self = JsonRpcResponse.parseFromJson(json)
    }
    
    public static func parseFromJson(_ json: JSON) -> JsonRpcResponse {
        var id: JsonRpcRequest.ID?
        if let _id = json["id"].string {
            id = .string(_id)
        }
        else if let _id = json["id"].int {
            id = .number(_id)
        }
        
        guard let versionString = json["jsonrpc"].string else {
            return JsonRpcResponse(id: id, error: .invalidResponse)
        }
        
        if versionString != JsonRpcResponse.version {
            return JsonRpcResponse(id: id, error: .invalidResponse)
        }
        
        if json["error"].exists() {
            guard let errCode = json["error"]["code"].int, let errMsg = json["error"]["message"].string  else {
                return JsonRpcResponse(id: id, error: JsonRpcError.parseError)
            }
            let errData = json["error"]["data"]
            return JsonRpcResponse(id: id, error: JsonRpcError.raw(errCode, errMsg, errData.exists() ? errData : nil))
        }
        
        return JsonRpcResponse(id: id, result: json["result"].exists() ?  json["result"] : nil)
    }
}
