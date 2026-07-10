//
//  PeripheralDiscoveryStore.swift
//  iot-link
//
//  Created by Dumitru Paraschiv on 10.07.2026.
//

import Foundation

/// Tracks peripherals seen during a scan: RSSI smoothing and staleness pruning, keyed by
/// `UUID` rather than `CBPeripheral` (which has no public initializer and so cannot be
/// constructed in a unit test). The owning actor keeps its own `[UUID: CBPeripheral]`
/// lookup alongside this store for `connect(to:)`, and must prune it using the ids this
/// type's `removeStale(now:)` returns so the two stay in sync.
nonisolated struct PeripheralDiscoveryStore: Sendable {
    
    private struct Entry: Sendable {
        let name: String?
        var rssi: Int
        var lastSeen: Date
    }
    
    private var entries: [UUID: Entry] = [:]
    
    /// Exponential-moving-average weight for smoothing noisy RSSI readings. Higher values
    /// track movement faster; lower values are steadier.
    private let smoothingFactor: Double
    
    /// A peripheral that hasn't advertised within this window is considered out of range.
    private let staleInterval: TimeInterval
    
    init(smoothingFactor: Double = 0.3, staleInterval: TimeInterval = 5) {
        self.smoothingFactor = smoothingFactor
        self.staleInterval = staleInterval
    }
    
    /// Records a sighting, smoothing the RSSI against any prior reading for the same id.
    /// `name` is captured on first sighting and not refreshed on later ones.
    mutating func recordSighting(id: UUID, name: String?, rssi: Int, now: Date = Date()) {
        let smoothed: Int
        if let previous = entries[id]?.rssi {
            smoothed = Int((smoothingFactor * Double(rssi) + (1 - smoothingFactor) * Double(previous)).rounded())
        } else {
            smoothed = rssi
        }
        entries[id] = Entry(name: entries[id]?.name ?? name, rssi: smoothed, lastSeen: now)
    }
    
    /// Removes entries that haven't been sighted within `staleInterval` of `now`.
    /// - Returns: the ids removed, so a caller can prune any parallel lookup it keeps.
    @discardableResult
    mutating func removeStale(now: Date = Date()) -> Set<UUID> {
        let cutoff = now.addingTimeInterval(-staleInterval)
        let staleIDs = entries.filter { $0.value.lastSeen < cutoff }.map(\.key)
        staleIDs.forEach { entries.removeValue(forKey: $0) }
        return Set(staleIDs)
    }
    
    mutating func removeAll() {
        entries.removeAll()
    }
    
    /// The current sightings as the public model.
    var discovered: [DiscoveredPeripheral] {
        entries.map { DiscoveredPeripheral(id: $0.key, name: $0.value.name, rssi: $0.value.rssi) }
    }
}
