# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
