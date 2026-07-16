# GATT Specification

This document defines the custom BLE GATT (Generic Attribute Profile) specification for **IoT-Link**. To mimic low-power microcontrollers and physical IoT hardware constraints, the profile uses raw binary serialization instead of verbose formats like JSON.

---

## 🛠️ GATT Profile Overview

* **Primary Service**: `SmartDeviceService`
  * **UUID**: `E0C00001-C3B6-4B22-9F1C-123456789ABC`

| Characteristic | UUID | Properties | Payload Size | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Provisioning Endpoint** | `E0C00002-C3B6-4B22-9F1C-123456789ABC` | Write (With Response), Notify | Variable (Max 128 Bytes) | Uploads local Wi-Fi credentials to the device. Notifies provisioning status. |
| **Sensor Telemetry** | `E0C00003-C3B6-4B22-9F1C-123456789ABC` | Notify | 4 Bytes (Fixed) | Streams real-time Temperature & Humidity data. |
| **Hardware Control** | `E0C00004-C3B6-4B22-9F1C-123456789ABC` | Read, WriteWithoutResponse, Notify | 1 Byte | Controls and monitors the simulated status LED. Notifies on any state change. |

---

## 🗜️ Byte Layout Definitions

### 1. Provisioning Endpoint (Write With Response)
Used to send local Wi-Fi credentials from the iOS Central App to the macOS Peripheral CLI.

#### Payload Structure:
```text
┌──────────────────┬──────────────────────┬─────────────────────────┬─────────────────────────────┐
│ SSID Length (L1) │ Password Length (L2) │     SSID String Data    │     Password String Data    │
│    [1 Byte]      │       [1 Byte]       │       [L1 Bytes]        │          [L2 Bytes]         │
└──────────────────┴──────────────────────┴─────────────────────────┴─────────────────────────────┘
```

* **Byte 0**: `SSID Length` (Unsigned 8-bit integer, \(0 \le L_1 \le 32\))
* **Byte 1**: `Password Length` (Unsigned 8-bit integer, \(0 \le L_2 \le 64\))
* **Bytes 2 to \(2 + L_1 - 1\)**: `SSID` encoded as UTF-8 string.
* **Bytes \(2 + L_1\) to \(2 + L_1 + L_2 - 1\)**: `Password` encoded as UTF-8 string.

#### Provisioning Handshake Response:
Upon receiving the write request, the Simulator verifies the packet. The Peripheral acknowledges provisioning status by sending a **notification on the Provisioning Endpoint characteristic** containing a single status byte. The iOS Central subscribes to this characteristic before initiating the write to capture the response.
* `0x00`: Success (Credentials accepted, attempting connection)
* `0x01`: Invalid Payload Format (SSID or password lengths out of bounds)
* `0x02`: Wi-Fi Authentication Failure
* `0x03`: Timeout connecting to Wi-Fi Access Point

---

### 2. Sensor Telemetry (Notify)
Streams environmental sensor readings periodically. 

#### Payload Structure:
```text
┌──────────────────────────────────────────┬──────────────────────────────────────────┐
│             Temperature (Int16)          │              Humidity (Int16)            │
│            [2 Bytes, Big-Endian]         │            [2 Bytes, Big-Endian]         │
└──────────────────────────────────────────┴──────────────────────────────────────────┘
```

To avoid using float data types (which are costly for firmware), environmental decimals are transmitted as **signed 16-bit integers multiplied by 100** (Fixed-point scaling).
* **Bytes 0–1**: `Temperature` (Int16, Big-Endian) in hundredths of a degree Celsius (e.g., `23.85°C` is sent as `2385` / `0x0951`).
* **Bytes 2–3**: `Humidity` (Int16, Big-Endian) in hundredths of a percent (e.g., `45.20%` is sent as `4520` / `0x11A8`).

#### Parsing formula:
$$\text{Temperature (°C)} = \frac{\text{Int16Value}}{100.0}$$
$$\text{Humidity (\%)} = \frac{\text{Int16Value}}{100.0}$$

---

### 3. Hardware Control (Read, Write Without Response & Notify)
Allows the app to read and toggle the status LED, and receive push updates when it changes.

#### Payload Structure:
* **Byte 0**: LED State (Unsigned 8-bit integer)
  * `0x00`: LED OFF
  * `0x01`: LED ON

#### Change Notifications:
The Peripheral notifies subscribed centrals with the current 1-byte state whenever the LED
changes — whether from a central's write or a local change on the device (e.g. a physical
button). This lets the app's control reflect the device's true state without polling.

---

## 🔓 Threat Model

The provisioning exchange (and the profile generally) has no encryption, key exchange,
or authentication layer. This is an accepted trade-off for a proof-of-concept — it is
recorded here so it is a deliberate, documented decision rather than an oversight.

* **Credentials cross the air in plaintext.** The provisioning packet (§1) is
  length-prefixed UTF-8 with no encryption. Any BLE sniffer in radio range can capture
  the home network's SSID and password during provisioning.
* **The ATT link is never encrypted.** Neither side requires BLE pairing/bonding: the
  peripheral declares every characteristic without `.writeEncryptionRequired` /
  `.notifyEncryptionRequired`, and the central never triggers a pairing flow.
* **There is no authorized-client concept.** Any central in range can connect first and
  write its own credentials, toggle the LED, or read telemetry — the peripheral accepts
  writes from whichever central gets there first.
* **The peripheral's identity is not verified.** The central only checks the advertised
  service UUID (`SmartDeviceService`, §GATT Profile Overview); it has no way to
  distinguish the real device from a spoofed peripheral advertising the same UUID to
  harvest credentials.

**Decision — document and defer.** The provisioning characteristic stays plain
`.writeable` rather than requiring BLE pairing (`.writeEncryptionRequired` /
`.notifyEncryptionRequired`). Pairing alone would not authenticate the peripheral either,
so it would add demo-UX friction (a system pairing prompt on every fresh provision)
without closing the actual gap. Real mitigation — encrypted key exchange and an
authenticated peripheral — is deferred to a future encrypted-provisioning spec revision.

---

## 💻 Swift Serialization & Deserialization Reference

Here are Swift snippets demonstrating parsing and writing these exact byte structures safely.

### A. Constructing the Provisioning Packet
```swift
import Foundation

struct WiFiCredentials {
    let ssid: String
    let password: String
    
    func serialize() -> Data? {
        guard let ssidData = ssid.data(using: .utf8),
              let passwordData = password.data(using: .utf8) else { return nil }
        
        guard ssidData.count <= 32 && passwordData.count <= 64 else { return nil }
        
        var packet = Data()
        packet.append(UInt8(ssidData.count))
        packet.append(UInt8(passwordData.count))
        packet.append(ssidData)
        packet.append(passwordData)
        
        return packet
    }
}
```

### B. Deserializing Telemetry (withUnsafeBytes & Big-Endian Conversion)
This conforms to physical hardware layouts and demonstrates firmware integration capability.
```swift
import Foundation

struct TelemetryData {
    let temperature: Double
    let humidity: Double
    
    static func parse(from data: Data) -> TelemetryData? {
        guard data.count == 4 else { return nil }
        
        // Extract Big-Endian integers using memory layouts safely
        let rawTemp = data.subdata(in: 0..<2).withUnsafeBytes { buffer in
            Int16(bigEndian: buffer.load(as: Int16.self))
        }
        
        let rawHum = data.subdata(in: 2..<4).withUnsafeBytes { buffer in
            Int16(bigEndian: buffer.load(as: Int16.self))
        }
        
        return TelemetryData(
            temperature: Double(rawTemp) / 100.0,
            humidity: Double(rawHum) / 100.0
        )
    }
}
```

### C. Reading Control State
```swift
func parseLEDState(from data: Data) -> Bool {
    guard let firstByte = data.first else { return false }
    return firstByte == 0x01
}
```
