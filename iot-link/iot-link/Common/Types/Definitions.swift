//
//  Definitions.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 01.07.2026.
//

typealias Callback<T> = (T) -> Void
typealias EmptyCallback = () -> Void

typealias SendableCallback<T> = @Sendable (T) -> Void
