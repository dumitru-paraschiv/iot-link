# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Codebase Intelligence Rules
- NEVER use standard grep or full-file reads for architectural or dependency questions.
- ALWAYS use the `codebase-memory-mcp` tools (such as `trace_path`) to query the knowledge graph first.
- Only fall back to local file reads when checking precise code block details.

## Project Overview

IoT-Link is an iOS proof-of-concept demonstrating mobile-to-hardware BLE communication. Two Xcode targets in one workspace (`iot-link/iot-link.xcodeproj`):
- **`iot-link`** — iOS app (BLE Central, SwiftUI/UIKit) that discovers, provisions, and monitors a smart device.
- **`iot-link-simulator`** — macOS CLI (BLE Peripheral, `CBPeripheralManager`) that mimics the physical hardware. It shares **no code** with the app; `docs/GATT_SPEC.md` is the only coupling between them.

## Commands

```bash
# Run the macOS peripheral simulator (My Mac destination, Cmd+R in Xcode), or:
xcodebuild build -project iot-link/iot-link.xcodeproj -scheme iot-link-simulator -destination 'platform=macOS'

# Run the iOS app — requires a physical device; the iOS Simulator does not support
# CoreBluetooth Central APIs, so the app cannot connect to the peripheral simulator without real hardware.

# Run the full unit test suite (no BLE radio needed, runs on the iOS Simulator)
xcodebuild test -project iot-link/iot-link.xcodeproj -scheme iot-link \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests

# Run a single test suite or case
xcodebuild test -project iot-link/iot-link.xcodeproj -scheme iot-link \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:iot-linkTests/ReconnectionPolicyTests
```

Simulator keyboard commands while running (Xcode console): `l` toggle LED, `t` pause/resume telemetry, `d` drop connection, `q` quit, `?` help.

## Architecture

Read `docs/ARCHITECTURE.md` before making non-trivial changes — it has the full detail (concurrency model, DI, state machine math, testing strategy) with code examples. Summary of the load-bearing patterns:

### Coordinator (Flow) + MVVM, with a strict module shape
Navigation lives in `Flows/` (`AppFlow` → `OnboardingFlow` | `MainFlow` → `HomeFlow`/`SettingsFlow`, plus the modal `ProvisioningFlow`), never inside a ViewModel. Each UI module under `Modules/` (`Onboarding`, `Home`, `Provisioning/{Scan,Credentials,Result}`, `Settings`) is four core files (plus an optional `*ViewComponents` file for extracted SwiftUI subviews — Home and Onboarding have their own; the three Provisioning modules share `ProvisioningViewComponents.swift`): `*Model` (state, `private(set)` properties mutated only through named setters), `*View`/`*ViewOutput` (Input/Output protocols — View and ViewModel never hold concrete references to each other), `*ViewModel` (the only writer of the Model, dispatches on a single `send(_ action:)` entry point), `*ViewController` (hosts the SwiftUI `*ViewUI`). Both Views and Flows expose navigation events through a Combine `steps: PassthroughSubject`, which the owning Flow subscribes to and routes.

### `BluetoothCentralService` — actor + delegate-proxy
The project builds with `-default-isolation=MainActor`, so any unannotated type is `@MainActor` by default — which collides with CoreBluetooth's background delegate callbacks. `DefaultBluetoothCentralService` is an `actor` owning `CBCentralManager`; a `nonisolated` `CentralDelegateProxy` (`NSObject`) receives delegate callbacks on a dedicated background queue and forwards them into the actor via `@Sendable` closures, wrapping non-`Sendable` types (`CBPeripheral`, `CBService`) in `UncheckedSendable`. State (connection state, discovered peripherals, telemetry, LED, connected device) is exposed via `nonisolated(unsafe)` `CurrentValueSubject`-backed publishers, only ever `send`-ed from inside the actor; ViewModels subscribe via `.receive(on: DispatchQueue.main)`.

Three collaborators under `Services/Bluetooth/BluetoothCentralService/` are factored out as `nonisolated`, synchronous, `Sendable` value types that hold state and make decisions but never call CoreBluetooth or spawn a `Task` (that stays on the actor, since a `Task` spawned from a `nonisolated` type wouldn't inherit the actor's isolation):
- **`ReconnectionCoordinator`** — attempt-budget bookkeeping over `ReconnectionPolicy`.
- **`ProvisioningCoordinator`** — resume-exactly-once continuation handling for the provisioning handshake; tracks whether the current link `isProvisioned` (see below).
- **`PeripheralDiscoveryStore`** — RSSI EMA smoothing and staleness pruning during scan.

### BLE state machine & reconnection
`Idle → Scanning → Connecting → DiscoveringServices → DiscoveringCharacteristics → Connected → Provisioning → Provisioned` (three radio/permission states — `unknown`, `unauthorized`, `poweredOff` — precede `Idle`, for 13 `BluetoothState` cases total), with `Connected`/`Provisioned` dropping to `Reconnecting` on unexpected link loss (an `intentionalDisconnect` flag distinguishes deliberate teardown, which goes straight to `Disconnected`). Reconnect delay is `baseDelay × 2ⁿ + jitter` (`ReconnectionPolicy`, 2s base / 5 attempts default; jitter is an injected closure so tests can pin it). A reconnect of an already-provisioned link re-enters `Provisioned` directly rather than stopping at `Connected` (tracked by `ProvisioningCoordinator.isProvisioned`). `HomeModelBuilder.makePhase` maps `BluetoothState` to the dashboard's `Phase` (empty/dashboard/reconnecting) through an explicitly exhaustive `switch` with no `default:` — adding a new `BluetoothState` case is a compile error until this table is updated.

### Wire contract
`docs/GATT_SPEC.md` defines the raw byte layouts (provisioning credentials, Big-Endian `Int16 ÷ 100` fixed-point telemetry, 1-byte LED state) — the single source of truth both independent codec implementations (app and simulator) must agree with. `WireContractRoundTripTests` pins this by compiling the simulator's `Serialization.swift`/`PeripheralModels.swift` into the test target directly (via a `PBXFileSystemSynchronizedBuildFileExceptionSet` in the project file); because the simulator's types shadow the app's under the same names, test files reference the app's types via `private typealias App… = iot_link.<Type>`.

### Dependency injection (Swinject)
Registrations live in `ServiceAssembly.swift`; every injectable dependency is a protocol with its production implementation prefixed `Default` (e.g. `AccountService` → `DefaultAccountService`). `BluetoothCentralService` is `.container`-scoped (shared singleton); ViewModels take it as a constructor parameter and never resolve the container directly.

### Testing
Swift Testing (`@Suite`/`@Test`/`#expect`) in `iot-linkTests`, fully deterministic, no BLE radio or UI. Two seams exist specifically to remove nondeterminism: `ReconnectionPolicy`'s injectable jitter closure, and `DefaultAccountService`'s injectable `UserDefaults` (tests use per-test UUID-named `UserDefaults(suiteName:)`, wiped in `deinit`).

## Documentation map

- `docs/ARCHITECTURE.md` — concurrency, state machine, DI, module pattern, testing strategy (all with code snippets).
- `docs/GATT_SPEC.md` — GATT characteristics, byte layouts, Swift serialization reference.
- `docs/IMPLEMENTATION_PLAN.md` — **historical only**, documents the original v1.0.0 milestones (1-7); frozen as of the v1.0.0 release and not updated for later work.
- `CHANGELOG.md` — Keep a Changelog format; all post-1.0.0 work is recorded under `[Unreleased]` here, not in the implementation plan.

## Git workflow

This repo follows git-flow off `develop` (see `docs/IMPLEMENTATION_PLAN.md`'s Git Flow Guidelines), extended by observed convention for everything since v1.0.0:
- Every branch — including refactors and fixes, not just literal new features — uses `feature/<name>` off `develop` (e.g. `feature/bluetooth-central-service-decomposition`, `feature/provisioning-gated-dashboard`).
- Commit messages follow Conventional Commits (`feat(service):`, `fix(ui):`, `test:`, `docs:`).
- A branch's commits are ordered: spec commit → plan commit (if the change went through a design/planning step) → code/test commits split by architectural boundary (e.g. `fix(service):` separate from `fix(provisioning):` separate from `test:`) → `docs: update architecture for <topic>` → `docs: add unreleased changelog entry for <topic>`. Docs are never folded into code/test commits.
- A bug found during manual/hardware verification (not caught by diff-only review) gets its own dedicated `fix(...)` commit explaining the root cause, appended after the originally planned commits.
- Before merging a feature branch to `develop`: all targets build clean, unit tests pass, and (for BLE-touching changes) the app and simulator are verified against each other over a real connection.
