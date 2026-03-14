# Tier 1 Hardware Guide - Arduino CLI & Sketches

_Complete reference for Arduino/ESP32 development._

## Overview

**Status:** Phase 1 complete. CLI installed, boards configured, sketches ready.

**Hardware:**
- 3x ESP32 modules (WiFi, Bluetooth, 240MHz CPU)
- 3x Arduino UNO (ATmega328P, 16MHz CPU)

**Tools:**
- Arduino CLI v1.4.1
- Arduino AVR Boards 1.8.7
- ESP32 Boards 2.0.18

## Installation

### Arduino CLI

Already installed at: `~/.local/bin/arduino-cli`

Verify:
```bash
~/.local/bin/arduino-cli version
# arduino-cli  Version: 1.4.1
```

Add to PATH (optional):
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
arduino-cli version  # Should work without full path
```

### Board Definitions

Already installed:

```bash
arduino-cli core list
# ID            Installed        Latest           Name
# arduino:avr   1.8.7            1.8.7            Arduino AVR Boards
# esp32:esp32   2.0.18-arduino.5 2.0.18-arduino.5 Arduino ESP32 Boards
```

## Quick Commands

### List Boards
```bash
arduino-cli board list
# No boards found (when nothing connected)
```

When ESP32 is connected via USB:
```bash
arduino-cli board list
# Port       Type              Board Name                FQBN                  Core
# /dev/ttyUSB0 Serial Port (USB) ESP32 Dev Module          esp32:esp32:esp32     esp32:esp32
```

### Compile

**Arduino UNO:**
```bash
arduino-cli compile -b arduino:avr:uno sketches/blink_uno
```

**ESP32:**
```bash
arduino-cli compile -b esp32:esp32:esp32 sketches/wifi_esp32
```

### Upload

**Arduino UNO:**
```bash
arduino-cli upload -p /dev/ttyUSB0 -b arduino:avr:uno sketches/blink_uno
```

**ESP32:**
```bash
arduino-cli upload -p /dev/ttyUSB0 -b esp32:esp32:esp32 sketches/wifi_esp32
```

### Serial Monitor

```bash
screen /dev/ttyUSB0 9600      # Arduino UNO (9600 baud)
screen /dev/ttyUSB0 115200    # ESP32 (115200 baud)
# Exit: Ctrl+A, then Ctrl+D
```

Or with Arduino CLI wrapper:
```bash
hardware/arduino-cli-wrapper.sh monitor /dev/ttyUSB0 115200
```

## Sketches

### blink_uno - Arduino UNO LED Test

**File:** `hardware/sketches/blink_uno/blink_uno.ino`

**What it does:**
- Toggles LED on pin 13 every 1 second
- Built-in LED on most Arduino boards
- Perfect for verifying upload works

**Test:**
```bash
arduino-cli compile -b arduino:avr:uno sketches/blink_uno
arduino-cli upload -p /dev/ttyUSB0 -b arduino:avr:uno sketches/blink_uno
# LED should blink
```

### wifi_esp32 - ESP32 WiFi Connection Test

**File:** `hardware/sketches/wifi_esp32/wifi_esp32.ino`

**What it does:**
- Connects to WiFi network
- Reports signal strength (RSSI)
- Prints IP address to serial monitor

**Setup:**
Edit the sketch and update:
```cpp
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
```

**Test:**
```bash
arduino-cli compile -b esp32:esp32:esp32 sketches/wifi_esp32
arduino-cli upload -p /dev/ttyUSB0 -b esp32:esp32:esp32 sketches/wifi_esp32

# Open serial monitor
screen /dev/ttyUSB0 115200
# Should show WiFi connection status and RSSI
```

## Troubleshooting

### Board Not Found

```bash
lsusb | grep -i arduino
# Should show USB device

ls -la /dev/ttyUSB*
# Check permissions: should be readable
```

**Fix permissions:**
```bash
sudo usermod -aG dialout $USER
# Log out and back in
```

### Port In Use

```bash
lsof /dev/ttyUSB0
kill -9 <PID>
```

### Compile Error

Add `-v` for verbose output:
```bash
arduino-cli compile -v -b arduino:avr:uno sketches/blink_uno
```

### Upload Fails on ESP32

Press RST (reset) button during upload. Or:
```bash
# Hold GPIO0 to ground while uploading, release after upload starts
```

## Board Specifications

### Arduino UNO
- Processor: ATmega328P (16 MHz)
- Flash: 32 KB
- RAM: 2 KB
- Pins: 14 digital, 6 analog
- USB: Built-in (ATmega16U2)
- Voltage: 5V

### ESP32
- Processor: Dual-core 32-bit (240 MHz)
- Flash: 4 MB
- RAM: 520 KB (SRAM) + 4 MB (PSRAM)
- WiFi: 802.11 b/g/n
- Bluetooth: BLE + Classic
- Pins: 36 GPIO
- Voltage: 3.3V

## Next Steps

### Phase 2: Morpheus Integration

Build Julia HTTP server that:
1. Receives sensor data from ESP32
2. Queries Morpheus for decisions
3. Returns action JSON to device

**Reference:** `hardware/docs/MORPHEUS_INTEGRATION.md`

### Phase 3: Real Hardware

1. Connect ESP32 via USB
2. Flash `wifi_esp32` sketch
3. Deploy decision server
4. Test multi-device coordination

## Resources

- Arduino CLI Docs: https://arduino.github.io/arduino-cli/
- ESP32 Arduino Docs: https://docs.espressif.com/projects/arduino-esp32/
- Arduino Language Ref: https://www.arduino.cc/reference/en/

## Wrapper Script Commands

**All commands available:**
```bash
hardware/arduino-cli-wrapper.sh
# Usage:
#   list-boards       List installed boards
#   list-ports        List connected devices
#   compile <alias> <sketch>
#   upload <alias> <port> <sketch>
#   monitor <port> [baud]
#   board-info <alias>
#   new-sketch <name>
```

**Board aliases:**
- `uno` → arduino:avr:uno
- `nano` → arduino:avr:nano
- `esp32` → esp32:esp32:esp32
- `esp32-s3` → esp32:esp32:esp32s3

**Example:**
```bash
hardware/arduino-cli-wrapper.sh compile esp32 wifi_esp32
hardware/arduino-cli-wrapper.sh upload esp32 /dev/ttyUSB0 wifi_esp32
hardware/arduino-cli-wrapper.sh monitor /dev/ttyUSB0 115200
```
