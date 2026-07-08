//
//  HomeModelBuilderTests.swift
//  iot-linkTests
//

import Testing
@testable import iot_link

@MainActor
@Suite("Home phase derivation")
struct HomeModelBuilderTests {

    /// Exhaustive: all 13 BluetoothState cases as of M7. `makePhase` falls through a
    /// `default:` branch, so a newly added case is NOT compiler-surfaced — it silently
    /// maps to `nil` until this table is extended to pin it.
    private nonisolated static let mapping: [(BluetoothState, HomeModel.Phase?)] = [
        (.unknown, nil),
        (.unauthorized, nil),
        (.poweredOff, nil),
        (.idle, nil),
        (.scanning, nil),
        (.connecting, nil),
        (.discoveringServices, nil),
        (.discoveringCharacteristics, nil),
        (.connected, .dashboard),
        (.provisioning, nil),
        (.provisioned, .dashboard),
        (.reconnecting, .reconnecting),
        (.disconnected, .empty),
    ]

    @Test("maps every BluetoothState to its phase", arguments: mapping)
    func phaseMapping(state: BluetoothState, expected: HomeModel.Phase?) {
        #expect(HomeModelBuilder.makePhase(from: state) == expected)
    }
}
