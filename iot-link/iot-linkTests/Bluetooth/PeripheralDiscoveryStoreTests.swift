//
//  PeripheralDiscoveryStoreTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("PeripheralDiscoveryStore sightings")
struct PeripheralDiscoveryStoreTests {

    private let id = UUID()
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    @Test("first sighting is not smoothed")
    func firstSighting() {
        var store = PeripheralDiscoveryStore()
        store.recordSighting(id: id, name: "Device", rssi: -50, now: epoch)
        #expect(store.discovered == [DiscoveredPeripheral(id: id, name: "Device", rssi: -50)])
    }

    @Test("later sightings are smoothed with the exponential moving average")
    func smoothedSighting() {
        var store = PeripheralDiscoveryStore(smoothingFactor: 0.3, staleInterval: 5)
        store.recordSighting(id: id, name: "Device", rssi: -50, now: epoch)
        store.recordSighting(id: id, name: "Device", rssi: -80, now: epoch)
        // 0.3 * -80 + 0.7 * -50 = -59, rounded
        #expect(store.discovered.first?.rssi == -59)
    }

    @Test("name is captured on first sighting and not overwritten")
    func nameCapturedOnce() {
        var store = PeripheralDiscoveryStore()
        store.recordSighting(id: id, name: "First Name", rssi: -50, now: epoch)
        store.recordSighting(id: id, name: "Second Name", rssi: -50, now: epoch)
        #expect(store.discovered.first?.name == "First Name")
    }

    @Test("removeStale removes entries past the stale interval and returns their ids")
    func removesStaleEntries() {
        var store = PeripheralDiscoveryStore(smoothingFactor: 0.3, staleInterval: 5)
        store.recordSighting(id: id, name: "Device", rssi: -50, now: epoch)
        let removed = store.removeStale(now: epoch.addingTimeInterval(6))
        #expect(removed == [id])
        #expect(store.discovered.isEmpty)
    }

    @Test("removeStale is a no-op within the stale interval")
    func keepsFreshEntries() {
        var store = PeripheralDiscoveryStore(smoothingFactor: 0.3, staleInterval: 5)
        store.recordSighting(id: id, name: "Device", rssi: -50, now: epoch)
        let removed = store.removeStale(now: epoch.addingTimeInterval(4))
        #expect(removed.isEmpty)
        #expect(store.discovered.count == 1)
    }

    @Test("removeAll clears every entry")
    func removesEverything() {
        var store = PeripheralDiscoveryStore()
        store.recordSighting(id: id, name: "Device", rssi: -50, now: epoch)
        store.removeAll()
        #expect(store.discovered.isEmpty)
    }
}
