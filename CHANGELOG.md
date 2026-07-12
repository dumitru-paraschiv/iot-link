# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Telemetry Dashboard**: the Home dashboard no longer shows live telemetry for a device that hasn't completed Wi-Fi provisioning. `HomeModelBuilder.makePhase` previously mapped both `.connected` (reached right after BLE discovery) and `.provisioned` (reached after the `0x00` handshake) to the same dashboard phase; `.connected` alone no longer advances the phase. `ProvisioningCoordinator` now tracks whether the current link has completed provisioning, so a reconnect of an already-provisioned device still correctly restores the dashboard.
- **Provisioning Cancellation**: the Wi-Fi credentials screen previously had no way to back out except the sheet's interactive swipe-dismiss gesture, which bypassed `ProvisioningFlow`'s disconnect cleanup entirely — leaving a live, unprovisioned BLE connection behind. Both the Scan and Credentials screens now have an explicit Cancel action, and the swipe gesture is wired to the same teardown via `ProvisioningFlow.handleInteractiveDismiss()`. Unit test count grew from 53 to 56.

### Changed
- **Bluetooth Central Service**: split the 570-line `DefaultBluetoothCentralService` actor into `Services/Bluetooth/BluetoothCentralService/`, extracting `ReconnectionCoordinator`, `ProvisioningCoordinator`, and `PeripheralDiscoveryStore` as independently unit-tested, `nonisolated` value types owning pure decision/state logic while the actor retains all scheduling and CoreBluetooth I/O. No public API or behavior change; unit test count grew from 37 to 53.

## [1.0.0] - 2026-07-08

Initial release of the IoT-Link ecosystem: an iOS BLE central app and a macOS
command-line peripheral simulator, developed across seven git-flow milestones.

### Added
- **Onboarding**: a three-page feature walkthrough (BLE, Provisioning, Telemetry) with local persistence of completion state.
- **Bluetooth Central Service**: an actor-based `CBCentralManager` wrapper reaching full connection, service, and characteristic discovery.
- **IoT-Device macOS Simulator**: a self-contained command-line peripheral target implementing the same GATT contract as the iOS app, with an interactive keyboard control interface.
- **BLE Device Provisioning**: end-to-end scan → connect → discover → write Wi-Fi credentials → handshake flow, including a live RSSI-sorted scan list and a validated credentials form.
- **Telemetry Dashboard & Control UI**: live temperature/humidity gauges and status LED control, backed by notify-based Bluetooth characteristics.
- **Resiliency**: automatic exponential back-off reconnection on unexpected disconnects, with a dedicated "reconnecting" dashboard state and a per-attempt connect timeout.
- **Unit Tests**: 10 suites covering wire codecs (against `GATT_SPEC.md`), a cross-target central/simulator round-trip, the reconnection back-off policy, onboarding persistence, and dashboard phase derivation.

See [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for the full per-milestone breakdown and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for design details.
