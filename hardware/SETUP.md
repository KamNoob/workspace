# Hardware Setup - Arduino CLI

_Arduino/ESP32 development environment configured and ready._

---

## Installation Status

✅ **Arduino CLI:** v1.4.1 installed  
✅ **Arduino AVR Boards:** 1.8.7 installed (Arduino Uno, Nano, etc.)  
✅ **ESP32 Boards:** 2.0.18-arduino.5 installed (ESP32 + variants)  
✅ **Config:** ~/.arduino15/arduino-cli.yaml  
✅ **Workspace:** ~/.openclaw/workspace/hardware/

---

## Quick Start

### Add to PATH (optional)

```bash
export PATH="$HOME/.local/bin:$PATH"
# Add to ~/.bashrc for persistence
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Then just use:
```bash
arduino-cli version
```

Without PATH, use the full path:
```bash
~/.local/bin/arduino-cli version
```

---

## Commands

### List installed boards
```bash
arduino-cli core list
```

### Search for boards
```bash
arduino-cli core search esp32
arduino-cli core search arduino
```

### List connected devices
```bash
arduino-cli board list
```

### Create a sketch
```bash
arduino-cli sketch new my_sketch
```

### Compile a sketch
```bash
arduino-cli compile -b arduino:avr:uno sketches/my_sketch
```

### Upload to board
```bash
arduino-cli upload -p /dev/ttyUSB0 -b arduino:avr:uno sketches/my_sketch
```

### Get board info
```bash
arduino-cli board details arduino:avr:uno
arduino-cli board details esp32:esp32:esp32
```

---

## Your Hardware

### Arduino UNOs (3x)
- **Board ID:** `arduino:avr:uno`
- **Typical port:** `/dev/ttyUSB0` (when connected)
- **Use:** Classic Arduino sketches, basic prototyping

### ESP32 Modules (3x)
- **Board ID:** `esp32:esp32:esp32`
- **Typical port:** `/dev/ttyUSB1` (when connected)
- **Use:** WiFi, Bluetooth, more RAM, faster processor
- **Advantage:** Can run more complex logic, network communication

---

## Workspace Structure

```
hardware/
├── SETUP.md                    ← This file
├── sketches/                   ← Your sketch projects
│   ├── blink_uno/             ← Arduino example
│   ├── wifi_esp32/            ← ESP32 WiFi example
│   └── sensor_network/        ← Multi-board example
└── docs/
    ├── ESP32_REFERENCE.md     ← Pinout, specs
    ├── ARDUINO_REFERENCE.md   ← UNO reference
    └── MORPHEUS_INTEGRATION.md ← AI bridge setup
```

---

## Next Steps

1. **Connect a board** (USB cable to computer)
2. **Verify connection:**
   ```bash
   arduino-cli board list
   ```
   Should show your board with port (e.g., `/dev/ttyUSB0`)

3. **Run first sketch** (see sketches/ directory)
4. **Integrate with Morpheus** (see MORPHEUS_INTEGRATION.md)

---

## Troubleshooting

### Board not detected
```bash
# Check USB connection
lsusb | grep -i arduino

# Check permissions
ls -l /dev/ttyUSB*
# If permission denied, add user to dialout group:
sudo usermod -aG dialout $USER
# Log out and back in for change to take effect
```

### Sketch won't compile
```bash
# Check board is specified correctly
arduino-cli compile -b arduino:avr:uno -v sketches/my_sketch
# -v shows verbose output for debugging
```

### Port in use
```bash
# Find what's using the port
lsof /dev/ttyUSB0

# Kill process if needed
kill -9 <PID>
```

---

## Resources

- **Arduino CLI Docs:** https://arduino.github.io/arduino-cli/
- **ESP32 Arduino Docs:** https://docs.espressif.com/projects/arduino-esp32/en/latest/
- **Arduino Tutorials:** https://www.arduino.cc/en/Guide/

---

_Setup completed: 2026-03-14 12:26 GMT_
