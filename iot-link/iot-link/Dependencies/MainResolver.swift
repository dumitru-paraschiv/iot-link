//
//  MainResolver.swift
//  iot-link
//

import Swinject

@MainActor
struct MainResolver: Sendable {
    
    nonisolated(unsafe) private let resolver: Resolver
    
    nonisolated init(_ resolver: Resolver) {
        self.resolver = resolver
    }
    
    func resolve<T>(_ type: T.Type = T.self,
                    name: String? = nil) -> T {
        resolver.resolve(type, name: name) ?? failure()
    }
    
    func resolve<T, Arg>(_ type: T.Type = T.self,
                         name: String? = nil,
                         with argument: Arg) -> T {
        resolver.resolve(T.self, name: name, argument: argument) ?? failure()
    }
    
    func resolve<T, Arg1, Arg2>(_ type: T.Type = T.self,
                                name: String? = nil,
                                with arg1: Arg1,
                                _ arg2: Arg2) -> T {
        resolver.resolve(T.self, name: name, arguments: arg1, arg2) ?? failure()
    }
    
    private func failure<T>() -> T {
        fatalError("Can't resolve \(T.self)")
    }
}
