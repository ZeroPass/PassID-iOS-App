//
//  Log.swift
//  PassID
//
//  Created by smlu on 15/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import Foundation
import os.log
import _SwiftOSOverlayShims


@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
public enum LogLevel : Int {
    case verbose = 0
    case debug   = 1
    case info    = 2
    case warning = 3
    case error   = 4
    
    func toOSLogType() -> OSLogType {
        var logType: OSLogType
        switch self {
            case .verbose:
            logType = .default
            case .debug:
            logType = .debug
            case .info:
            logType = .info
            case .warning:
            logType = .error
            case .error:
            logType = .fault
        }

        return logType
    }
}


@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
class Log {
    public static var level: LogLevel = .debug
    
    public let category: String
    init(category: String) {
        self.category = category
    }
    
    
    func log(_ level: LogLevel, _ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            Log.log(level, category: self.category, msg, $0)
        }
    }
    
    func verbose(_ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            Log.log(.verbose, category: self.category, msg, $0)
        }
    }
    
    func debug(_ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            Log.log(.debug, category: self.category, msg, $0)
        }
    }
    
    func info(_ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            Log.log(.info, category: self.category, msg, $0)
        }
    }
    
    func warning(_ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            Log.log(.warning, category: self.category, msg, $0)
        }
    }
    
    func error(_ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            Log.log(.error, category: self.category, msg, $0)
        }
    }
    
    static func log(_ level: LogLevel, category: String? = nil, _ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            log(level, category: category, msg, $0)
        }
    }
    
    static func verbose(category: String? = nil, _ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            log(.verbose, category: category, msg, $0)
        }
    }
    
    static func debug(category: String? = nil, _ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            log(.debug, category: category, msg, $0)
        }
    }
    
    static func info(category: String? = nil, _ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            log(.info, category: category, msg, $0)
        }
    }
    
    static func warning(category: String? = nil, _ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            log(.warning, category: category, msg, $0)
        }
    }
    
    static func error(category: String? = nil, _ msg : StaticString, _ args: CVarArg...) {
        withVaList(args) {
            log(.error, category: category, msg, $0)
        }
    }
    
    private static func log(_ level: LogLevel, category: String? = nil, _ msg : StaticString, _ args: CVaListPointer) {
        if self.level.rawValue <= level.rawValue {
            let log = { category == nil ?
                OSLog.default :
                OSLog(subsystem: Bundle.main.bundleIdentifier!, category: category!)
            }()
                
            let type = level.toOSLogType()
            //os_log(msg, log: log, type: type, args) // can't call it with CVaListPointer for params
            osLog(msg, log: log, type: type, args)
        }
    }
    
    private static func osLog(_ msg : StaticString, dso: UnsafeRawPointer = #dsohandle, log: OSLog, type: OSLogType, _ args: CVaListPointer) {
        // Due to CVarArg limitation which cannot be passed through multiple functions,
        // this function implements os_log function that accepts CVaListPointer type for arguments instead of CVarArg.
        // code was taken from: https://github.com/apple/swift/blob/6e7051eb1e38e743a514555d09256d12d3fec750/stdlib/public/Darwin/os/os_log.swift#L49-L63
        guard log.isEnabled(type: type) else { return }
        let ra = _swift_os_log_return_address()
        msg.withUTF8Buffer { (buf: UnsafeBufferPointer<UInt8>) in
            // Since dladdr is in libc, it is safe to unsafeBitCast
            // the cstring argument type.
            buf.baseAddress!.withMemoryRebound(
                to: CChar.self, capacity: buf.count
            ) { str in
                _swift_os_log(dso, ra, log, type, str, args)
            }
        }
    }
}
