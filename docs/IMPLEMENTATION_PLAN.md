# Implementation Plan - Git-Driven Code Generation Milestones

This plan outlines the code generation stages for **IoT-Link**, utilizing a Git flow branching model starting from the `develop` branch. 

## Git Flow Guidelines
1. **Branching**: For each milestone, we will branch off `develop` into a dedicated feature branch: `feature/<milestone-name>`.
2. **Milestone Approvals**: Before merging a feature branch back into `develop`, we will perform verification steps.
3. **Commit Messages**: Commits will follow Conventional Commits format (e.g., `feat(service):`, `fix(ui):`, `test:`).

---

## Proposed Milestones

### ✅ Milestone 1: App Onboarding Walkthrough (Feature Tour)
* **Branch**: `feature/app-onboarding`
* **Commit Message**: `feat(onboarding): implement onboarding walkthrough flow and local state persistence`
* **Rationale**: Simplest end-to-end slice — validates the full Flow → Module → Service wiring pattern without BLE complexity. Matches the user's actual journey (onboarding before any device interaction).
* **Changes**:
  * Built a 3-page walkthrough (BLE, Provisioning, Telemetry) using `TabView` with paged style inside the `Onboarding` module.
  * Extracted reusable view components into `OnboardingViewComponents` (PageCard, PageIndicator, ActionButton, DismissButton).
  * Added `OnboardingModel` with `Page` struct, `OnboardingModelBuilder` for default page construction, and mutation via named setters.
  * Updated `AccountService` to persist `isAppOnboarded` state via type-safe `UserDefaults` extension with enum-based keys and tracing.
  * Added `Optional.orFalse` convenience and `UserDefaults+Extensions` with generic typed get/set/remove.
  * Wired coordinator steps transition in `OnboardingFlow` (hidden navigation bar) to route back to `AppFlow` once onboarding completes.
  * Added a subtle dismiss (x-mark) button for skipping onboarding directly.

### ✅ Milestone 2: Bluetooth Central Service Core
* **Branch**: `feature/bluetooth-central-service`
* **Commit Message**: `feat(service): implement BluetoothCentralService and Swinject registration`
* **Scope**: Reaches the `.connected` state (services + characteristics discovered & cached). Characteristic I/O is deferred — telemetry subscribe/parse and LED read/write are Milestone 5, Wi-Fi credential writes Milestone 4, exponential back-off reconnection Milestone 6.
* **Changes**:
  * Added `Services/Bluetooth/` mirroring the per-service folder layout:
    * `BluetoothCentralService.swift` — protocol + `actor DefaultBluetoothCentralService` owning the `CBCentralManager`, connection state machine, and discovery caches.
    * `CentralDelegateProxy.swift` — a `nonisolated` NSObject bridging `CBCentralManagerDelegate`/`CBPeripheralDelegate` callbacks into the actor via `@Sendable` closures.
    * `GATTProfile.swift` — type-safe `CBUUID` namespace for the service + three characteristics (per `GATT_SPEC.md`).
    * `BluetoothModels.swift` — Sendable `BluetoothState` enum and `DiscoveredPeripheral`, keeping `CBPeripheral` out of the ViewModel layer.
  * Added `Common/Types/UncheckedSendable.swift` — a transfer box for moving non-`Sendable` CoreBluetooth objects across the isolation boundary.
  * Exposed state via Combine `CurrentValueSubject`-backed publishers (current-value replay), consistent with the `steps` subject pattern. `AsyncStream` is reserved for the telemetry stream in Milestone 5.
  * Registered `BluetoothCentralService` in `ServiceAssembly.swift` with `.container` scope (shared singleton).
  * Added `NSBluetoothAlwaysUsageDescription` to `Info.plist` (required before the permission prompt).
  * Marked shared value utilities (`Optional`, `Sequence` extensions) `nonisolated` so the actor compiles warning-free under the project's `-default-isolation=MainActor` setting.

### ✅ Milestone 3: IoT-Device macOS Simulator Target
* **Branch**: `feature/device-simulator`
* **Commit Message**: `feat(simulator): add macOS command-line utility peripheral target`
* **Rationale**: The simulator must exist before provisioning and telemetry can be tested end-to-end. Building it early prevents developing BLE features blind.
* **Design**: Self-contained target — no code shared with the iOS app (mirrors real firmware; the wire contract in `GATT_SPEC.md` is the only coupling). Reuses the M2 concurrency pattern: an `actor SimulatorPeripheral` owning the `CBPeripheralManager`, fed by a `nonisolated PeripheralDelegateProxy`.
* **Changes**:
  * Added the `iot-link-simulator` (macOS Command Line Tool) target with its own `GATTProfile` and `UncheckedSendable`.
  * `SimulatorPeripheral` (actor) advertises `SmartDeviceService` with three characteristics and handles reads/writes/subscriptions.
  * `Serialization` decodes the provisioning packet (bounds-checked → `0x01` on malformed input, `0x00` after a ~0.5 s delay on success) and encodes big-endian fixed-point telemetry.
  * `TelemetryTicker` emits a bounded random-walk reading every ~1 s, only while a central is subscribed.
  * Interactive CLI (`KeyboardCommands`, raw-mode stdin): `l` toggle LED, `t` pause/resume telemetry, `d` drop connection, `q` quit; unmapped keys log a hint.
  * Configured the CLI target to embed an Info.plist (`GENERATE_INFOPLIST_FILE` + `CREATE_INFOPLIST_SECTION_IN_BINARY`) carrying `NSBluetoothAlwaysUsageDescription`, so the macOS Bluetooth permission prompt appears reliably on a reviewer's machine.

### ✅ Milestone 4: BLE Device Provisioning Flow
* **Branch**: `feature/ble-provisioning`
* **Scope**: The end-to-end "Add Device" journey — scan → connect → discover → write Wi-Fi credentials → observe the `0x00`/`0x01` handshake. Split into three commits by impact (service → flow/scan → form/result).
* **Commit 1 — `feat(service): provisioning write + handshake`**:
  * Extended `BluetoothCentralService` with `provision(_:) async throws -> ProvisioningStatus`: serializes the packet, writes `.withResponse`, and suspends on a `CheckedContinuation` resumed by the status-byte notification or a 10 s timeout (single-resume guard, `.notReady` on disconnect).
  * Enabled notifications on the provisioning characteristic at discovery; added `onWriteValue`/`onUpdateValue` callbacks to `CentralDelegateProxy`.
  * Added `ProvisioningModels.swift` (`WiFiCredentials` + `serialize()` per `GATT_SPEC.md`, `ProvisioningStatus`, `ProvisioningError`) and the `.provisioning`/`.provisioned` states.
* **Commit 2 — `feat(provisioning): flow + BLE scan list`**:
  * Added `ProvisioningFlow` coordinator (presented modally from the Home empty-state and a Settings "Add Device" row) and the `Scan` module.
  * Live scan list sorted by a 3-tier RSSI signal bucket, tap-to-connect, with EMA smoothing and time-based pruning of devices that stop advertising (duplicate-allowed scanning).
  * Marked shared `Optional`/`Sequence`/`Collection`/`Bool` utilities `nonisolated` as needed for actor-safe use.
* **Commit 3 — `feat(provisioning): Wi-Fi credential form and result screens`**:
  * Added the `Credentials` module (live validation against spec byte bounds, password reveal) and the `Result` module (success auto-dismiss; typed failure with recovery-aware "Try Again" — re-enter credentials if the device is still connected, or re-scan if it is gone).
  * Hardened the scan/credentials lifecycle: scan only navigates for a connection it initiated (ignoring replayed `.connected`) and restarts scanning on appear; credentials observes connection state only while on top.
  * Centralized per-screen navigation-bar visibility via `prefersNavigationBarHidden` on the base controllers, applied in sync with the push/pop transition.

### 🏁 Milestone 5: Telemetry Dashboard & Control UI
* **Branch**: `feature/telemetry-dashboard`
* **Commit Message**: `feat(dashboard): implement telemetry decoding and live dashboard UI`
* **Changes**:
  * Update `HomeViewModel` to bind to `BluetoothCentralService` streams.
  * Implement raw Big-Endian Int16 parsing using `withUnsafeBytes` to decode Temperature & Humidity values.
  * Build the SwiftUI gauge/graph indicators inside `HomeView`.
  * Add a toggle control to write `0x01` / `0x00` without response to the LED status characteristic.
  * Handle the empty/disconnected state with a prompt and "Add Device" button.

### 🏁 Milestone 6: Resiliency & Unit Tests
* **Branch**: `feature/tests-and-resiliency`
* **Commit Message**: `feat(resiliency): implement exponential back-off reconnection and add unit tests`
* **Changes**:
  * Add the exponential back-off reconnection scheduling algorithm inside the `BluetoothCentralService`.
  * Add unit tests for packet serialization/deserialization.
  * Add unit tests for back-off delay calculations.
  * Add unit tests for `AccountService` persistence logic.

---

## Verification Plan

For each feature branch before merging to `develop`:
1. Compile all targets to ensure zero build errors.
2. Run Xcode unit tests (where applicable for the milestone).
3. For BLE milestones (3–5): validate communication logs between the iOS client and macOS CLI simulator, confirming byte-level correctness of the GATT transactions.
4. Capture simulator console output demonstrating the provisioning handshake and telemetry stream as evidence of end-to-end correctness.
