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

### 🏁 Milestone 3: IoT-Device macOS Simulator Target
* **Branch**: `feature/device-simulator`
* **Commit Message**: `feat(simulator): add macOS command-line utility peripheral target`
* **Rationale**: The simulator must exist before provisioning and telemetry can be tested end-to-end. Building it early prevents developing BLE features blind.
* **Changes**:
  * Add a new Target `iot-link-simulator` (macOS Command Line Tool) to the Xcode workspace.
  * Implement `CBPeripheralManager` to advertise `SmartDeviceService`.
  * Write logic to handle and log incoming provisioning credential packets.
  * Implement mocked periodic telemetry streams and support read/write LED requests.

### 🏁 Milestone 4: BLE Device Provisioning Flow
* **Branch**: `feature/ble-provisioning`
* **Commit Message**: `feat(provisioning): implement ProvisioningFlow coordinator and Wi-Fi credential binary serialization`
* **Changes**:
  * Create `ProvisioningFlow` coordinator.
  * Create `ProvisioningViewModel` and `ProvisioningViewController` showing scanning lists and Wi-Fi inputs.
  * Implement byte serialization logic mapping `[SSID Length] + [Password Length] + [SSID Data] + [Password Data]` to be written to characteristic `E0C00002-C3B6-4B22-9F1C-123456789ABC`.
  * Handle the provisioning notification handshake response from the peripheral.

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
