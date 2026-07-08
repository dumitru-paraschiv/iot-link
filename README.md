# IoT-Link

**IoT-Link** is an iOS proof-of-concept (PoC) ecosystem designed to demonstrate mobile-to-hardware communication in the consumer IoT space. The project serves as a technical portfolio piece showcasing best practices in iOS development—featuring `CoreBluetooth` lifecycle management, custom GATT profiles, raw binary serialization, thread-safe background processing, and robust auto-reconnection flows.

---

## ⚙️ Prerequisites

* **Xcode 26+** (Swift 6.0) — the app icon uses the Icon Composer `.icon` format, which requires Xcode 26 or later
* **iOS 17.0+** deployment target
* **macOS 14.0+** for the peripheral simulator
* After cloning, open the project and let Xcode resolve Swift Package Manager dependencies (Swinject) automatically, or run **File → Packages → Resolve Package Versions**.

---

## 📱 Project Targets

The ecosystem consists of two primary targets within a single workspace:
1. **IoT-Link Mobile Client (iOS App)**: A Swift/SwiftUI app acting as the BLE Central. It manages user onboarding (app features tour), BLE device discovery, Wi-Fi provisioning, live telemetry visualization, and device control.
2. **IoT-Device Simulator (macOS CLI)**: A command-line utility acting as the BLE Peripheral. It mimics a physical, unprovisioned IoT appliance (like a smart climate controller or light switch) advertising service nodes.

---

## 🎯 Target User Personas & Scenarios

### Persona A: The End-User (Product Experience)
* **Scenario 1: App Onboarding (Intro)**: When launching the app for the first time, the user completes a brief walkthrough explaining the app's features and requesting the necessary Bluetooth system authorizations.
* **Scenario 2: Device Provisioning**: The user unboxes a new smart device that has no display or physical UI. They tap "Add Device" from the app's dashboard or settings, scanning for the nearby unprovisioned hardware over BLE. They input their home Wi-Fi SSID and Password and transmit these credentials securely to configure the device's internet connection.
* **Scenario 3: Telemetry (Monitoring & Control)**: Once provisioned, the user monitors live sensor data (temperature, humidity) and controls physical hardware states (toggling the device's status LED) directly from the app dashboard over local BLE link.

### Persona B: The Technical Interviewer (Code Reviewer)
* **Scenario**: An iOS Engineering Manager or Hardware Integration Engineer reviews the repository. They expect to see:
  * Structured `CoreBluetooth` delegation off the main thread.
  * Swift Concurrency (`async`/`await`, `actors`) for thread safety and asynchronous workflows.
  * Custom dependency injection using Swinject and clean decoupling of architectural components.
  * Explicit byte-level serialization without heavy JSON overhead to respect physical hardware constraints.

---

## 📁 Repository Directory Structure

The project uses a structured, modular Clean MVVM architecture with Flow (Coordinator) routing:

```text
iot-link/
├── README.md                      # Project overview and target configurations
├── docs/
│   ├── GATT_SPEC.md               # Custom GATT specifications and byte layouts
│   ├── ARCHITECTURE.md            # Concurrency, state machine, and reconnection logic
│   └── IMPLEMENTATION_PLAN.md     # Git-driven milestone plan and per-milestone status
└── iot-link/                      # Main Xcode Workspace
    ├── iot-link/                  # iOS App Source Target
    │   ├── Core/                  # App Entry Point, Delegates (App, Scene)
    │   ├── Dependencies/          # DI Container, MainResolver, and Swinject Assemblies
    │   ├── Flows/                 # Coordinator / Navigation Flows
    │   │   ├── AppFlow.swift      # Main application router
    │   │   ├── OnboardingFlow.swift # Handles app feature walkthrough tutorial
    │   │   ├── MainFlow.swift     # TabBar coordinator mapping Home/Settings
    │   │   ├── HomeFlow.swift     # Dashboard and control navigation
    │   │   └── ProvisioningFlow.swift # Coordinates scan → credentials → result
    │   ├── Modules/               # MVVM UI Modules
    │   │   ├── Onboarding/        # Welcome screens & features walkthrough UI
    │   │   ├── Provisioning/      # Scan list, Wi-Fi credential form, and result screens
    │   │   ├── Home/              # Live Telemetry & Control Dashboard UI
    │   │   └── Settings/          # Configuration & Manual Re-Onboarding / Add Device triggers
    │   ├── Services/              # Core Services (Account, App, Diagnostics, Bluetooth incl. ReconnectionPolicy)
    │   ├── Factories/             # Factory pattern implementations for Modules and Flows
    │   └── Common/                # Types, Extensions, and Swift Helpers
    ├── iot-link-simulator/        # macOS Simulator CLI Target (CBPeripheralManager)
    ├── iot-linkTests/             # Unit tests: wire codecs, cross-target round-trip, back-off policy, persistence, phase mapping
    └── iot-linkUITests/           # UI test target
```

---

## 🚀 How to Run Both Targets Side-by-Side

### 1. Build and Run the macOS Simulator
Since the simulator is a macOS command-line utility, you can run it directly on your development Mac.
1. Open the project in Xcode: `open iot-link/iot-link.xcodeproj`
2. Select the `iot-link-simulator` target from the Xcode schema selector.
3. Choose **My Mac** as the run destination.
4. Press `Cmd + R` to run. The Xcode debug console will start printing advertising logs (look for `📡 advertising SmartDeviceService…`).

> **Bluetooth permission (first run):** macOS shows a one-time Bluetooth consent prompt the first time the simulator advertises — click **Allow**. If you accidentally deny it, re-enable it under **System Settings → Privacy & Security → Bluetooth**, since the choice is remembered per-app.

**Interactive keyboard commands** (while the simulator is running in the Xcode console):
| Key | Action |
| :-- | :--- |
| `l` | Toggle the status LED locally (pushed to the app via notification) |
| `t` | Pause / resume the telemetry stream |
| `d` | Drop the current connection (restarts advertising) |
| `q` | Quit and restore the terminal |
| `?` | Print the command help |

### 2. Build and Run the iOS Central App
To test BLE interaction:
* **Option A (Real Device - Recommended)**: Build and run the `iot-link` target on a physical iPhone/iPad. Ensure Bluetooth is enabled on both your Mac and your iOS device.
* **Option B (Simulator Limits)**: Please note that the Xcode iOS Simulator **does not support CoreBluetooth Central APIs** for physical BLE hardware. Running the app on a physical device is required to establish a connection with the macOS CLI Peripheral simulator.

### 3. Run the Unit Tests
The unit suite is deterministic and needs **no BLE radio** — it runs fine on the Xcode iOS Simulator. Select the `iot-link` scheme and press `Cmd + U`, or from the terminal:

```bash
xcodebuild test -project iot-link/iot-link.xcodeproj -scheme iot-link \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:iot-linkTests
```

The suite covers the GATT wire codecs, a cross-target round-trip proving the app's and simulator's independent codec implementations agree byte-for-byte, the reconnection back-off policy, onboarding persistence, and the dashboard phase mapping — see the Testing Strategy section in [ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 📄 Associated Documents

* Refer to [GATT_SPEC.md](docs/GATT_SPEC.md) for custom BLE characteristics and raw byte layout definitions.
* Refer to [ARCHITECTURE.md](docs/ARCHITECTURE.md) for details on thread safety, Swinject integration, reconnection back-off math, and the unit-testing strategy.
