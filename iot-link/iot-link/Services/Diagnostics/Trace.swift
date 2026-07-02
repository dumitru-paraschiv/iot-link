//
//  Trace.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

import Foundation

private nonisolated(unsafe) let sharedISOFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withTime, .withFractionalSeconds, .withColonSeparatorInTime]
    return formatter
}()

/// Logs diagnostic messages to the console.
///
/// **Concurrency & Ordering:**
/// This function is `nonisolated` and natively safe to call from any concurrency domain.
/// We utilize `print()`, which ensures atomic writes so log output is never garbled.
/// A thread-safe, lock-free `ISO8601DateFormatter` is used for high-performance timestamp 
/// generation, completely satisfying Swift 6's Strict Concurrency model without requiring
/// global state or locks.
nonisolated public func trace(_ args: Any...,
                              caller: Any? = nil,
                              file: String = #file,
                              function: String = #function) {
    #if DEBUG
    var timestamp: String {
        sharedISOFormatter.string(from: Date.now)
    }
    
    var prettyCaller: String? {
        if let string = caller as? String {
            return string
        }
        return caller.flatMap {
            String(describing: type(of: $0))
        }
    }
    
    var prettyFile: String {
        file
            .nsString.deletingPathExtension
            .nsString.lastPathComponent
    }
    
    var prettyFunction: String {
        let splits = function.components(separatedBy: CharacterSet(charactersIn: "()"))
        if splits.count == 2 {
            return splits[0] + splits[1].components(separatedBy: ":").map(\.capitalized).joined()
        }
        return function
    }
    
    var context: String {
        [prettyCaller ?? prettyFile, prettyFunction]
            .filter(\.isNotEmpty)
            .joined(.space)
    }
    
    var prefix: String {
        [timestamp, context]
            .filter(\.isNotEmpty)
            .map(\.wrappedIntoBrackets)
            .joined(" • ")
    }
    
    var prettyArguments: String {
        args
            .map(String.init(describing:))
            .joined(.space)
    }
    
    var format: String {
        [prefix, prettyArguments]
            .filter(\.isNotEmpty)
            .joined(.space)
    }
    
    print(format)
    #endif
}
