//
//  KeyboardCommands.swift
//  iot-link-simulator
//
//  Created by Dumitru Paraschiv on 06.07.2026.
//

import Foundation

/// The terminal settings captured before entering raw mode. Held at file scope so the
/// non-capturing `atexit` handler can restore them on abnormal termination.
private nonisolated(unsafe) var savedTerminalMode = termios()

/// Reads single keystrokes from stdin in raw mode and forwards them to the peripheral.
///
/// Runs its blocking read loop on a detached background thread so the main thread stays
/// free to run the CoreBluetooth run loop. Terminal mode is restored on quit or process
/// termination.
nonisolated enum KeyboardCommands {
    
    /// Installs raw-mode stdin handling and starts the read loop. Returns immediately.
    static func start(forwardingTo peripheral: SimulatorPeripheral) {
        guard isatty(STDIN_FILENO) == 1 else {
            log(.command, "stdin is not a TTY - keyboard commands disabled")
            return
        }
        
        enableRawMode()
        
        // Restore the terminal if the process exits while in raw mode. The closure must
        // not capture context to form a C function pointer, so it reads file-scope state.
        atexit { tcsetattr(STDIN_FILENO, TCSAFLUSH, &savedTerminalMode) }
        
        printHelp()
        
        Thread.detachNewThread {
            readLoop(peripheral: peripheral)
        }
    }
}

// MARK: - Read Loop

private extension KeyboardCommands {
    
    static func readLoop(peripheral: SimulatorPeripheral) {
        var byte: UInt8 = 0
        while read(STDIN_FILENO, &byte, 1) == 1 {
            let key = Character(UnicodeScalar(byte))
            switch key {
            case "l", "L":
                Task { await peripheral.toggleLED() }
            case "t", "T":
                Task { await peripheral.toggleTelemetryPaused() }
            case "d", "D":
                Task { await peripheral.dropConnection() }
            case "q", "Q":
                log(.command, "quitting")
                restoreMode()
                exit(EXIT_SUCCESS)
            case "?", "h", "H":
                printHelp()
            case "\n", "\r":
                break
            default:
                log(.command, "unknown key '\(key)' - press [?] for help")
            }
        }
    }
    
    static func printHelp() {
        log(.command, "keys: [l] toggle LED  [t] pause/resume telemetry  [d] drop connection  [q] quit")
    }
}

// MARK: - Raw Mode

private extension KeyboardCommands {
    
    /// Switches the terminal into raw mode (no line buffering, no echo), saving the
    /// previous settings to file scope so they can be restored on exit.
    static func enableRawMode() {
        tcgetattr(STDIN_FILENO, &savedTerminalMode)
        
        var raw = savedTerminalMode
        raw.c_lflag &= ~(UInt(ICANON | ECHO))
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
    }
    
    static func restoreMode() {
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &savedTerminalMode)
    }
}
