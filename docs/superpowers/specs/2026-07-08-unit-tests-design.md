# M7 Unit Tests — Design

**Date**: 2026-07-08
**Milestone**: 7 (final) — `feature/unit-tests` off `develop`
**Status**: Approved

## Goal

Lock in the pure logic shipped across Milestones 1–6 with deterministic unit tests in the
existing `iot-linkTests` target. Everything under test is a `nonisolated` value type or pure
function, so no BLE radio, UI, or async scheduling is required.

## Production changes

Two changes outside the test target, both minimal:

1. **`DefaultAccountService` dependency injection**: add
   `init(defaults: UserDefaults = .standard)` and use the stored instance in `isOnboarded`
   and `completeOnboarding()`. `ServiceAssembly` registration is untouched (the default
   argument preserves current behavior). This lets tests run against an isolated
   `UserDefaults(suiteName:)` with no bleed into the real app domain.
2. **Test-target membership for simulator codec files**: an Xcode 16
   `PBXFileSystemSynchronizedBuildFileExceptionSet` on the `iot-link-simulator`
   synchronized folder adds exactly `Serialization.swift` and `PeripheralModels.swift` to
   the `iot-linkTests` target. Both files are pure Foundation and compile in an iOS test
   bundle. The test target has no `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` override, so
   the `nonisolated` declarations compile without friction.

### Type-name collisions (round-trip file)

Compiling the simulator's `PeripheralModels.swift` into the test target introduces
`WiFiCredentials`, `TelemetryReading`, `LEDState`, and `ProvisioningStatus` that collide
with the app's types from `@testable import iot_link`. Test-target-local declarations win
unqualified lookup, so app types are referenced as `iot_link.WiFiCredentials` etc. Local
typealiases (`AppCredentials` / `SimCredentials`, …) are confined to
`WireContractRoundTripTests.swift`; every other test file uses only app types and stays
collision-free.

## Test suite layout

Replaces the stub `iot_linkTests.swift`. All Swift Testing (`@Suite` / `@Test` /
`#expect`), with parameterized `@Test(arguments:)` where a table reads naturally.

```
iot-linkTests/
├── Codecs/
│   ├── WiFiCredentialsTests.swift      // serialize() layout + spec bounds
│   ├── TelemetryCodecTests.swift       // TelemetryReading.parse
│   └── ControlCodecTests.swift         // LEDState codec + ProvisioningStatus raw bytes
├── WireContractRoundTripTests.swift    // central ⇄ simulator cross-target
├── ReconnectionPolicyTests.swift
├── AccountServiceTests.swift
├── UserDefaultsExtensionsTests.swift
├── HomeModelBuilderTests.swift
└── ValueHelpersTests.swift             // Optional/Collection/Bool/Sequence/String/Array
```

## What each suite pins

### WiFiCredentialsTests (against `docs/GATT_SPEC.md`)

- Exact byte layout `[SSID length][Password length][SSID bytes][Password bytes]`.
- Multibyte UTF-8 SSIDs counted in **bytes**, not characters.
- Boundary acceptance: 32-byte SSID and 64-byte password serialize.
- `nil` on: empty SSID, SSID > 32 bytes, password > 64 bytes.
- Empty password **allowed** (open network) — pins current, intended behavior.

### TelemetryCodecTests

- Known Big-Endian vectors, e.g. `09C4 1388` → 25.0 °C / 50.0 %.
- Negative temperature via `Int16` bit-pattern (e.g. `FF38` → −2.0).
- `nil` for payloads ≠ 4 bytes (0, 3, 5 bytes).

### ControlCodecTests

- `LEDState` 1-byte round-trip; any non-`0x01` byte parses as `.off`; empty data → `.off`.
- `ProvisioningStatus` raw mapping `0x00`–`0x03`; unknown bytes → `nil`.

### WireContractRoundTripTests (cross-target)

The two targets share no code; these tests pin the wire contract itself:

- App `WiFiCredentials.serialize()` → simulator `Serialization.decodeProvisioning` →
  identical SSID/password.
- Simulator `Serialization.encodeTelemetry` → app `TelemetryReading.parse` → equal within
  fixed-point rounding (±0.005).
- LED state in both directions.
- Malformed/truncated packets throw `ProvisioningError.invalidPayload` on the simulator
  side.

### ReconnectionPolicyTests

- Pinned (injected) jitter → exact `baseDelay × 2ⁿ + jitter` curve for attempts 0–4.
- Negative attempt index clamps to attempt 0.
- Budget boundary: `allowsAttempt(maxAttempts − 1)` is true, `allowsAttempt(maxAttempts)`
  is false.

### AccountServiceTests

- Against a unique-per-test `UserDefaults(suiteName:)`, wiped after each test.
- `isOnboarded` defaults to `false`.
- `completeOnboarding()` flips it and **persists** across a second service instance sharing
  the same suite.

### UserDefaultsExtensionsTests

- Typed get/set/remove round-trip on an isolated suite.
- Wrong-type `get` returns `nil`.

### HomeModelBuilderTests

- Exhaustive 13-case `BluetoothState → HomeModel.Phase?` table:
  `connected`/`provisioned` → `.dashboard`; `reconnecting` → `.reconnecting`;
  `disconnected` → `.empty`; the nine transitional/radio states → `nil`.
- Written as a parameterized table over explicit cases (no `switch` in the test). Note:
  `makePhase` uses a `default:` branch, so a new enum case is not compiler-surfaced —
  the table must be extended by hand when a case is added.

### ValueHelpersTests

- `Optional`: `isNone`, `isSome`, `orFalse`, `orEmpty`.
- `Collection.isNotEmpty`, `Bool.isFalse`.
- `Sequence`: `unique(_:)`, `unique(by:)`, `notContains(_:)`.
- `String`: `space`, `wrappedIntoBrackets`; `Array`: `prepending(_:)`, `joined(_:)`.
- Note: the implementation plan mentions an `orTrue`-style helper; it does not exist in
  the codebase and is out of scope.

## Branch & commits

`feature/unit-tests` off `develop`, two commits by impact:

1. `refactor(service): inject UserDefaults into AccountService for testability`
2. `test: add unit tests for wire codecs, back-off policy, persistence, and dashboard
   phase derivation` — includes the pbxproj test-membership change and the deleted stub.

## Verification

1. Build all three targets (app, simulator, tests) with zero errors/warnings.
2. `xcodebuild test` on an iOS Simulator destination — all tests green.
3. Update `docs/IMPLEMENTATION_PLAN.md` M7 entry to ✅ (as done for M1–M6) before merge.
