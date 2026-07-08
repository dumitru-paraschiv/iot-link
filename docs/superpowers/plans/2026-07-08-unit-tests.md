# M7 Unit Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deterministic unit tests in the `iot-linkTests` target pinning the pure logic of Milestones 1–6: wire codecs, cross-target wire contract, back-off policy, persistence, dashboard phase derivation, and shared value helpers.

**Architecture:** Everything under test is a `nonisolated` value type or pure function — no radio, UI, or async scheduling. Two production-side enablers: `DefaultAccountService` gains an injectable `UserDefaults`, and the simulator's two codec files are compiled into the test target (pbxproj exception set) for a true central ⇄ peripheral round-trip. Spec: `docs/superpowers/specs/2026-07-08-unit-tests-design.md`.

**Tech Stack:** Swift 6 / Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), Xcode 16 synchronized-folder project format, `xcodebuild`.

## Global Constraints

- Branch: `feature/unit-tests` (already checked out; the spec commit is on it).
- Exactly **two** code commits (matching the design doc):
  1. `refactor(service): inject UserDefaults into AccountService for testability` (Task 1)
  2. `test: add unit tests for wire codecs, back-off policy, persistence, and dashboard phase derivation` (Task 10 — everything else accumulates uncommitted until then)
- Working directory for all `xcodebuild` commands: `/Users/dmitri/Documents/Code/Claude/iot-link/iot-link` (where `iot-link.xcodeproj` lives).
- Module name for `@testable import` is `iot_link` (underscore).
- **The simulator's `PeripheralModels.swift` types (`WiFiCredentials`, `TelemetryReading`, `LEDState`, `ProvisioningStatus`, `ProvisioningError`) are compiled into the test target from Task 2 onward.** Unqualified references in ANY test file resolve to the simulator's types; the app's types MUST be referenced as `iot_link.<Type>` (done via `private typealias App… = iot_link.<Type>` at the top of each affected file). Do not skip these typealiases.
- These tests pin **existing shipped behavior**. If a test fails, do NOT silently "fix" production code — stop, investigate whether the test or the code is wrong, and surface the finding.
- Build commands (used repeatedly; `-quiet` keeps output readable):
  - App: `xcodebuild build -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet`
  - One suite: `xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/<SuiteTypeName> -quiet`
  - All unit tests (skips UI tests): `... -only-testing:iot-linkTests -quiet`

---

### Task 1: Inject UserDefaults into DefaultAccountService

**Files:**
- Modify: `iot-link/iot-link/Services/Account/AccountService.swift`

**Interfaces:**
- Produces: `DefaultAccountService.init(defaults: UserDefaults = .standard)` — Task 7's tests construct the service with an isolated `UserDefaults(suiteName:)`.
- `ServiceAssembly.swift` line 14 (`DefaultAccountService()`) keeps compiling unchanged via the default argument — do not touch it.

- [ ] **Step 1: Apply the refactor**

Replace the actor body in `iot-link/iot-link/Services/Account/AccountService.swift` so the file reads (header comment and protocol unchanged):

```swift
protocol AccountService: Sendable {
    
    var isOnboarded: Bool { get async }
    
    func completeOnboarding() async
}

actor DefaultAccountService: AccountService {
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    var isOnboarded: Bool {
        defaults.get(Bool.self, forKey: .isAppOnboarded).orFalse
    }

    func completeOnboarding() {
        defaults.set(true, forKey: .isAppOnboarded)
    }
}
```

- [ ] **Step 2: Verify the app still builds**

Run (from `/Users/dmitri/Documents/Code/Claude/iot-link/iot-link`):
```bash
xcodebuild build -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet
```
Expected: exits 0, no errors or warnings.

- [ ] **Step 3: Commit**

```bash
git add iot-link/Services/Account/AccountService.swift
git commit -m "refactor(service): inject UserDefaults into AccountService for testability

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Compile simulator codec files into the test target

**Files:**
- Modify: `iot-link/iot-link.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `Serialization`, and the simulator's `WiFiCredentials` / `TelemetryReading` / `LEDState` / `ProvisioningStatus` / `ProvisioningError` become **test-target-local** types (used by Task 5; shadowing rule in Global Constraints applies to every test file).

- [ ] **Step 1: Verify the new UUID is unused**

```bash
grep -c "2AFFFF012FF5897100C3F82E" iot-link.xcodeproj/project.pbxproj
```
Expected: `0` (grep exits 1). If nonzero, pick another 24-hex-digit ID and substitute it in the steps below.

- [ ] **Step 2: Add the exception set**

In `iot-link.xcodeproj/project.pbxproj`, replace:

```
/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */
		2A4280272FF591A800C3F82E /* Exceptions for "iot-link" folder in "iot-link" target */ = {
```

with:

```
/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */
		2AFFFF012FF5897100C3F82E /* Exceptions for "iot-link-simulator" folder in "iot-linkTests" target */ = {
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				PeripheralModels.swift,
				Serialization.swift,
			);
			target = 2A427F712FF5897100C3F82E /* iot-linkTests */;
		};
		2A4280272FF591A800C3F82E /* Exceptions for "iot-link" folder in "iot-link" target */ = {
```

- [ ] **Step 3: Attach the exception set to the simulator folder group**

In the same file, replace:

```
		2A2A00E52FFB26B7002C6FE5 /* iot-link-simulator */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = "iot-link-simulator";
			sourceTree = "<group>";
		};
```

with:

```
		2A2A00E52FFB26B7002C6FE5 /* iot-link-simulator */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				2AFFFF012FF5897100C3F82E /* Exceptions for "iot-link-simulator" folder in "iot-linkTests" target */,
			);
			path = "iot-link-simulator";
			sourceTree = "<group>";
		};
```

- [ ] **Step 4: Verify the project parses and the test bundle builds**

```bash
xcodebuild build-for-testing -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet
```
Expected: exits 0. (This compiles `iot-linkTests` including the two simulator files — pure Foundation, so they build in an iOS bundle.)

- [ ] **Step 5: Verify the simulator target is unaffected**

```bash
xcodebuild build -project iot-link.xcodeproj -scheme iot-link-simulator -destination 'platform=macOS' -quiet
```
Expected: exits 0.

*No commit — accumulates into the Task 10 `test:` commit.*

---

### Task 3: WiFiCredentials serialization tests

**Files:**
- Create: `iot-link/iot-linkTests/Codecs/WiFiCredentialsTests.swift`

**Interfaces:**
- Consumes: `iot_link.WiFiCredentials(ssid:password:)`, `.serialize() -> Data?` (app module).

- [ ] **Step 1: Write the test file**

```swift
//
//  WiFiCredentialsTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

/// The simulator's `WiFiCredentials` is compiled into this target and wins unqualified
/// lookup; the app's type under test must be module-qualified.
private typealias AppCredentials = iot_link.WiFiCredentials

@Suite("WiFiCredentials serialization")
struct WiFiCredentialsTests {

    @Test("lays out [ssidLen][pwdLen][ssid][pwd] per GATT_SPEC")
    func packetLayout() {
        let packet = AppCredentials(ssid: "MyWiFi", password: "secret42").serialize()
        
        var expected = Data([0x06, 0x08])
        expected.append(Data("MyWiFi".utf8))
        expected.append(Data("secret42".utf8))
        #expect(packet == expected)
    }

    @Test("counts multibyte UTF-8 SSIDs in bytes, not characters")
    func multibyteSSID() {
        // "Café" is 4 characters but 5 UTF-8 bytes.
        let packet = AppCredentials(ssid: "Café", password: "pw").serialize()
        
        #expect(packet?.first == 5)
        #expect(packet?.count == 2 + 5 + 2)
    }

    @Test("accepts fields exactly at the spec bounds (32/64)")
    func boundaryLengths() {
        let ssid = String(repeating: "s", count: 32)
        let password = String(repeating: "p", count: 64)
        let packet = AppCredentials(ssid: ssid, password: password).serialize()
        
        #expect(packet?.count == 2 + 32 + 64)
        #expect(packet?.first == 32)
    }

    @Test("allows an empty password (open network)")
    func emptyPassword() {
        let packet = AppCredentials(ssid: "Open", password: "").serialize()
        #expect(packet == Data([0x04, 0x00]) + Data("Open".utf8))
    }

    @Test("rejects an empty SSID")
    func emptySSID() {
        #expect(AppCredentials(ssid: "", password: "secret42").serialize() == nil)
    }

    @Test("rejects fields over the spec bounds")
    func overBounds() {
        let longSSID = String(repeating: "s", count: 33)
        let longPassword = String(repeating: "p", count: 65)
        
        #expect(AppCredentials(ssid: longSSID, password: "pw").serialize() == nil)
        #expect(AppCredentials(ssid: "net", password: longPassword).serialize() == nil)
    }
}
```

- [ ] **Step 2: Run the suite**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/WiFiCredentialsTests -quiet
```
Expected: `** TEST SUCCEEDED **`, 6 tests pass. (These pin shipped behavior — a failure means investigate, not patch.)

*No commit yet.*

---

### Task 4: Telemetry and control codec tests

**Files:**
- Create: `iot-link/iot-linkTests/Codecs/TelemetryCodecTests.swift`
- Create: `iot-link/iot-linkTests/Codecs/ControlCodecTests.swift`

**Interfaces:**
- Consumes: `iot_link.TelemetryReading.parse(from:) -> TelemetryReading?`, `iot_link.LEDState.parse(from:)` / `.serialize()`, `iot_link.ProvisioningStatus(rawValue:)`.

- [ ] **Step 1: Write TelemetryCodecTests.swift**

```swift
//
//  TelemetryCodecTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

/// The simulator's `TelemetryReading` is compiled into this target and wins unqualified
/// lookup; the app's type under test must be module-qualified.
private typealias AppTelemetryReading = iot_link.TelemetryReading

@Suite("TelemetryReading parsing")
struct TelemetryCodecTests {

    @Test("decodes big-endian fixed-point values (÷ 100)")
    func knownVector() {
        // 0x09C4 = 2500 → 25.0 °C, 0x1388 = 5000 → 50.0 %
        let reading = AppTelemetryReading.parse(from: Data([0x09, 0xC4, 0x13, 0x88]))
        #expect(reading == AppTelemetryReading(temperature: 25.0, humidity: 50.0))
    }

    @Test("decodes negative temperatures via the Int16 bit pattern")
    func negativeTemperature() {
        // 0xFF38 = -200 as Int16 → -2.0 °C
        let reading = AppTelemetryReading.parse(from: Data([0xFF, 0x38, 0x13, 0x88]))
        #expect(reading == AppTelemetryReading(temperature: -2.0, humidity: 50.0))
    }

    @Test("rejects payloads that are not exactly 4 bytes", arguments: [0, 1, 3, 5])
    func rejectsWrongLength(count: Int) {
        let data = Data(repeating: 0x00, count: count)
        #expect(AppTelemetryReading.parse(from: data) == nil)
    }
}
```

- [ ] **Step 2: Write ControlCodecTests.swift**

```swift
//
//  ControlCodecTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

/// The simulator's counterparts are compiled into this target and win unqualified
/// lookup; the app's types under test must be module-qualified.
private typealias AppLEDState = iot_link.LEDState
private typealias AppProvisioningStatus = iot_link.ProvisioningStatus

@Suite("LEDState codec")
struct LEDStateCodecTests {

    @Test("round-trips both states", arguments: [AppLEDState.off, AppLEDState.on])
    func roundTrip(state: AppLEDState) {
        #expect(AppLEDState.parse(from: state.serialize()) == state)
    }

    @Test("serializes to the single spec byte")
    func serializedBytes() {
        #expect(AppLEDState.off.serialize() == Data([0x00]))
        #expect(AppLEDState.on.serialize() == Data([0x01]))
    }

    @Test("treats any non-0x01 byte as off", arguments: [UInt8]([0x00, 0x02, 0x7F, 0xFF]))
    func nonOneIsOff(byte: UInt8) {
        #expect(AppLEDState.parse(from: Data([byte])) == .off)
    }

    @Test("treats empty data as off")
    func emptyIsOff() {
        #expect(AppLEDState.parse(from: Data()) == .off)
    }
}

@Suite("ProvisioningStatus raw bytes")
struct ProvisioningStatusTests {

    @Test("maps the four spec status bytes")
    func specBytes() {
        #expect(AppProvisioningStatus(rawValue: 0x00) == .success)
        #expect(AppProvisioningStatus(rawValue: 0x01) == .invalidPayload)
        #expect(AppProvisioningStatus(rawValue: 0x02) == .authFailure)
        #expect(AppProvisioningStatus(rawValue: 0x03) == .wifiTimeout)
    }

    @Test("rejects unknown bytes", arguments: [UInt8]([0x04, 0x10, 0xFF]))
    func unknownBytes(byte: UInt8) {
        #expect(AppProvisioningStatus(rawValue: byte) == nil)
    }
}
```

- [ ] **Step 3: Run the three suites**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/TelemetryCodecTests -only-testing:iot-linkTests/LEDStateCodecTests -only-testing:iot-linkTests/ProvisioningStatusTests -quiet
```
Expected: `** TEST SUCCEEDED **`.

*No commit yet.*

---

### Task 5: Cross-target wire-contract round-trip tests

**Files:**
- Create: `iot-link/iot-linkTests/WireContractRoundTripTests.swift`

**Interfaces:**
- Consumes: simulator's `Serialization.decodeProvisioning(_:) throws -> WiFiCredentials`, `.encodeTelemetry(_:) -> Data`, `.decodeLED(_:)` / `.encodeLED(_:)`, and `ProvisioningError.invalidPayload` (all **unqualified** — compiled into this target by Task 2); app's types via `iot_link.` qualification.

- [ ] **Step 1: Write the test file**

```swift
//
//  WireContractRoundTripTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

// The iOS app and the macOS simulator deliberately share no code — only the wire
// contract in docs/GATT_SPEC.md. Task 2 compiles the simulator's Serialization.swift +
// PeripheralModels.swift into this target, so these tests prove the two independent
// codec implementations agree byte-for-byte.
//
// Unqualified names resolve to the simulator's types; the app's need qualification.
private typealias SimCredentials = WiFiCredentials
private typealias SimTelemetryReading = TelemetryReading
private typealias AppCredentials = iot_link.WiFiCredentials
private typealias AppTelemetryReading = iot_link.TelemetryReading
private typealias AppLEDState = iot_link.LEDState

@Suite("Central ⇄ simulator wire contract")
struct WireContractRoundTripTests {

    @Test("credentials serialized by the central decode identically on the peripheral")
    func provisioningRoundTrip() throws {
        let app = AppCredentials(ssid: "Café-Network", password: "hunter2!")
        let packet = try #require(app.serialize())
        
        let sim = try Serialization.decodeProvisioning(packet)
        #expect(sim.ssid == app.ssid)
        #expect(sim.password == app.password)
    }

    @Test("telemetry encoded by the peripheral parses back on the central",
          arguments: [(23.47, 51.9), (-2.0, 0.0), (0.0, 100.0)])
    func telemetryRoundTrip(temperature: Double, humidity: Double) throws {
        let encoded = Serialization.encodeTelemetry(
            SimTelemetryReading(temperature: temperature, humidity: humidity)
        )
        let parsed = try #require(AppTelemetryReading.parse(from: encoded))
        
        // Fixed-point (× 100) rounding allows at most half a hundredth of drift.
        #expect(abs(parsed.temperature - temperature) < 0.005)
        #expect(abs(parsed.humidity - humidity) < 0.005)
    }

    @Test("LED state crosses the wire in both directions")
    func ledRoundTrip() {
        #expect(Serialization.decodeLED(AppLEDState.on.serialize()) == .on)
        #expect(Serialization.decodeLED(AppLEDState.off.serialize()) == .off)
        #expect(AppLEDState.parse(from: Serialization.encodeLED(.on)) == .on)
        #expect(AppLEDState.parse(from: Serialization.encodeLED(.off)) == .off)
    }

    @Test("malformed packets are rejected by the peripheral", arguments: [
        Data(),                                 // no header
        Data([0x05]),                           // truncated header
        Data([0x05, 0x02, 0x61, 0x62]),         // declared lengths exceed buffer
        Data([0x21, 0x00]),                     // SSID length 33 over spec bound
    ])
    func malformedPackets(packet: Data) {
        #expect(throws: ProvisioningError.invalidPayload) {
            _ = try Serialization.decodeProvisioning(packet)
        }
    }
}
```

- [ ] **Step 2: Run the suite**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/WireContractRoundTripTests -quiet
```
Expected: `** TEST SUCCEEDED **`.

*No commit yet.*

---

### Task 6: ReconnectionPolicy tests

**Files:**
- Create: `iot-link/iot-linkTests/ReconnectionPolicyTests.swift`

**Interfaces:**
- Consumes: `ReconnectionPolicy(baseDelay:maxAttempts:jitter:)`, `.delay(forAttempt:) -> Duration`, `.allowsAttempt(_:) -> Bool` (no name collision — unqualified is fine).

- [ ] **Step 1: Write the test file**

```swift
//
//  ReconnectionPolicyTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("ReconnectionPolicy back-off")
struct ReconnectionPolicyTests {

    /// Jitter pinned to a fixed value makes the curve fully deterministic.
    private static let jitter = 0.25

    private let policy = ReconnectionPolicy(
        baseDelay: .seconds(2),
        maxAttempts: 5,
        jitter: { Self.jitter }
    )

    @Test("follows baseDelay × 2ⁿ plus jitter", arguments: [
        (0, 2), (1, 4), (2, 8), (3, 16), (4, 32)
    ])
    func delayCurve(attempt: Int, scaledSeconds: Int) {
        let expected = Duration.seconds(scaledSeconds) + .seconds(Self.jitter)
        #expect(policy.delay(forAttempt: attempt) == expected)
    }

    @Test("clamps negative attempt indices to the first attempt")
    func negativeAttempt() {
        #expect(policy.delay(forAttempt: -3) == policy.delay(forAttempt: 0))
    }

    @Test("permits attempts strictly under the budget")
    func budgetBoundary() {
        #expect(policy.allowsAttempt(0))
        #expect(policy.allowsAttempt(4))     // maxAttempts − 1: last allowed
        #expect(!policy.allowsAttempt(5))    // maxAttempts: refused
    }
}
```

- [ ] **Step 2: Run the suite**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/ReconnectionPolicyTests -quiet
```
Expected: `** TEST SUCCEEDED **`.

*No commit yet.*

---

### Task 7: AccountService and UserDefaults-extension tests

**Files:**
- Create: `iot-link/iot-linkTests/AccountServiceTests.swift`
- Create: `iot-link/iot-linkTests/UserDefaultsExtensionsTests.swift`

**Interfaces:**
- Consumes: `DefaultAccountService(defaults:)` from Task 1; `UserDefaults.get(_:forKey:)` / `get(forKey:)` / `set(_:forKey:)` / `remove(forKey:)` with `UserDefaults.Key.isAppOnboarded`.
- Pattern: `final class` suites — Swift Testing creates a fresh instance per test, and `deinit` wipes the per-instance UUID-named suite, so nothing bleeds into the real app domain or between tests.

- [ ] **Step 1: Write AccountServiceTests.swift**

```swift
//
//  AccountServiceTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("AccountService persistence")
final class AccountServiceTests {

    private let suiteName = "AccountServiceTests-\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("defaults to not onboarded")
    func defaultsToNotOnboarded() async {
        let service = DefaultAccountService(defaults: defaults)
        let onboarded = await service.isOnboarded
        #expect(onboarded == false)
    }

    @Test("completeOnboarding persists across service instances")
    func completeOnboardingPersists() async {
        let service = DefaultAccountService(defaults: defaults)
        await service.completeOnboarding()
        
        let onboarded = await service.isOnboarded
        #expect(onboarded)
        
        // A fresh instance over the same backing suite sees the persisted flag.
        let second = DefaultAccountService(defaults: defaults)
        let persisted = await second.isOnboarded
        #expect(persisted)
    }
}
```

- [ ] **Step 2: Write UserDefaultsExtensionsTests.swift**

```swift
//
//  UserDefaultsExtensionsTests.swift
//  iot-linkTests
//

import Testing
import Foundation
@testable import iot_link

@Suite("Typed UserDefaults extensions")
final class UserDefaultsExtensionsTests {

    private let suiteName = "UserDefaultsExtensionsTests-\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("get returns nil for an unset key")
    func getUnset() {
        #expect(defaults.get(Bool.self, forKey: .isAppOnboarded) == nil)
    }

    @Test("set then get round-trips")
    func setGetRoundTrip() {
        defaults.set(true, forKey: .isAppOnboarded)
        #expect(defaults.get(Bool.self, forKey: .isAppOnboarded) == true)
    }

    @Test("inferred-type get matches the explicit-type variant")
    func inferredGet() {
        defaults.set(true, forKey: .isAppOnboarded)
        let value: Bool? = defaults.get(forKey: .isAppOnboarded)
        #expect(value == true)
    }

    @Test("get with a mismatched type returns nil")
    func wrongTypeGet() {
        defaults.set(true, forKey: .isAppOnboarded)
        #expect(defaults.get(String.self, forKey: .isAppOnboarded) == nil)
    }

    @Test("remove clears the stored value")
    func removeClears() {
        defaults.set(true, forKey: .isAppOnboarded)
        defaults.remove(forKey: .isAppOnboarded)
        #expect(defaults.get(Bool.self, forKey: .isAppOnboarded) == nil)
    }
}
```

- [ ] **Step 3: Run both suites**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/AccountServiceTests -only-testing:iot-linkTests/UserDefaultsExtensionsTests -quiet
```
Expected: `** TEST SUCCEEDED **`, 7 tests pass.

*No commit yet.*

---

### Task 8: Home phase-derivation tests

**Files:**
- Create: `iot-link/iot-linkTests/HomeModelBuilderTests.swift`

**Interfaces:**
- Consumes: `HomeModelBuilder.makePhase(from: BluetoothState) -> HomeModel.Phase?`. `HomeModel`/`HomeModelBuilder` are MainActor-isolated (app target's default isolation), so the suite is `@MainActor`; the arguments table is `nonisolated static` so test discovery can read it.

- [ ] **Step 1: Write the test file**

```swift
//
//  HomeModelBuilderTests.swift
//  iot-linkTests
//

import Testing
@testable import iot_link

@MainActor
@Suite("Home phase derivation")
struct HomeModelBuilderTests {

    /// Exhaustive: all 13 BluetoothState cases. Adding a case surfaces in the service's
    /// switch (compiler) — this table pins the mapping itself.
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
```

- [ ] **Step 2: Run the suite**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/HomeModelBuilderTests -quiet
```
Expected: `** TEST SUCCEEDED **`, 13 parameterized cases pass.

*No commit yet.*

---

### Task 9: Shared value-helper tests; delete the stub

**Files:**
- Create: `iot-link/iot-linkTests/ValueHelpersTests.swift`
- Delete: `iot-link/iot-linkTests/iot_linkTests.swift` (Xcode template stub, superseded)

**Interfaces:**
- Consumes: `Optional.isNone/.isSome/.orFalse/.orEmpty`, `Collection.isNotEmpty`, `Bool.isFalse`, `Sequence.unique(_:)/.unique(by:)/.notContains(_:)`, `String.space/.wrappedIntoBrackets`, `Array.prepending(_:)/.joined(_:)` — all `public`/`nonisolated` in the app module, no collisions.

- [ ] **Step 1: Write the test file**

```swift
//
//  ValueHelpersTests.swift
//  iot-linkTests
//

import Testing
@testable import iot_link

@Suite("Shared value helpers")
struct ValueHelpersTests {

    @Test("Optional presence flags")
    func optionalPresence() {
        let some: Int? = 3
        let none: Int? = nil
        
        #expect(some.isSome && !some.isNone)
        #expect(none.isNone && !none.isSome)
    }

    @Test("Optional fallbacks: orFalse and orEmpty")
    func optionalFallbacks() {
        let noBool: Bool? = nil
        let noArray: [Int]? = nil
        
        #expect(noBool.orFalse == false)
        #expect((true as Bool?).orFalse == true)
        #expect(noArray.orEmpty == [])
        #expect(([1, 2] as [Int]?).orEmpty == [1, 2])
    }

    @Test("Collection.isNotEmpty and Bool.isFalse")
    func collectionAndBoolFlags() {
        #expect([1].isNotEmpty)
        #expect([Int]().isNotEmpty == false)
        #expect(false.isFalse)
        #expect(true.isFalse == false)
    }

    @Test("Sequence.unique keeps the first occurrence, preserving order")
    func sequenceUnique() {
        let values = [1, 2, 1, 3, 2]
        
        #expect(values.unique { $0 == $1 } == [1, 2, 3])
        #expect(values.unique(by: { $0 }) == [1, 2, 3])
    }

    @Test("Sequence.notContains")
    func sequenceNotContains() {
        #expect([1, 2, 3].notContains(4))
        #expect([1, 2, 3].notContains(2) == false)
    }

    @Test("String helpers")
    func stringHelpers() {
        #expect(String.space == " ")
        #expect("home".wrappedIntoBrackets == "[home]")
    }

    @Test("Array helpers")
    func arrayHelpers() {
        #expect([2, 3].prepending(1) == [1, 2, 3])
        #expect(["a", "b"].joined("-") == "a-b")
    }
}
```

- [ ] **Step 2: Delete the template stub**

```bash
git rm iot-link/iot-linkTests/iot_linkTests.swift
```

- [ ] **Step 3: Run the suite**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests/ValueHelpersTests -quiet
```
Expected: `** TEST SUCCEEDED **`, 7 tests pass.

*No commit yet.*

---

### Task 10: Full verification, docs update, final commit

**Files:**
- Modify: `docs/IMPLEMENTATION_PLAN.md` (M7 heading only)

**Interfaces:**
- Consumes: all suites from Tasks 3–9.

- [ ] **Step 1: Run the entire unit-test bundle**

```bash
xcodebuild test -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests -quiet
```
Expected: `** TEST SUCCEEDED **` — 10 suites (9 files; ControlCodecTests.swift holds two), ~65 test cases counting parameterized expansions, zero failures.

- [ ] **Step 2: Verify all three targets build clean**

```bash
xcodebuild build -project iot-link.xcodeproj -scheme iot-link -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet && xcodebuild build -project iot-link.xcodeproj -scheme iot-link-simulator -destination 'platform=macOS' -quiet
```
Expected: both exit 0, no warnings.

- [ ] **Step 3: Mark M7 done in the implementation plan**

In `docs/IMPLEMENTATION_PLAN.md`, replace:

```markdown
### 🏁 Milestone 7: Unit Tests
```

with:

```markdown
### ✅ Milestone 7: Unit Tests
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "test: add unit tests for wire codecs, back-off policy, persistence, and dashboard phase derivation

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Confirm a clean tree and exactly two new code commits**

```bash
git status --short && git log --oneline develop..HEAD
```
Expected: empty status; log shows the spec-doc commit, the `refactor(service):` commit, and this `test:` commit.
