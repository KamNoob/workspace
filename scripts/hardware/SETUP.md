# ESP32 + Morpheus Hardware Integration Setup

## Current Status

✅ **Morpheus Server:** Running on http://localhost:8000  
⏳ **Arduino Sketch:** Compiling (morpheus_client.ino)  
✅ **ESP32 Hardware:** Connected on /dev/ttyUSB0  

## Quick Test (Server Already Running)

### 1. Test Server Health
```bash
curl http://localhost:8000/api/health
# Should return: {"status":"ok","port":8000,"timestamp":...}
```

### 2. Send a Sensor Reading
```bash
curl -X POST http://localhost:8000/api/decide \
  -H "Content-Type: application/json" \
  -d '{"sensor":"temperature","value":42.5,"unit":"C","device_id":"ESP32_001"}'

# Should return:
# {"decision":"relay_on","execute":true,"reasoning":"High temperature, activating cooling","confidence":0.9}
```

### 3. View Recent Decisions
```bash
curl http://localhost:8000/api/decisions/5
```

## Upload Sketch to ESP32

### Prerequisites
- Arduino CLI installed: ✅ `/home/art/.local/bin/arduino-cli`
- ESP32 board definition: ✅ Installed (esp32:esp32)
- USB cable connected: ✅ `/dev/ttyUSB0`
- ArduinoJson library: ✅ Installed

### Configuration (IMPORTANT)

Edit `morpheus_client/morpheus_client.ino` at the top:

```cpp
// WiFi Configuration
const char* SSID = "YOUR_SSID";           // ← YOUR NETWORK NAME
const char* PASSWORD = "YOUR_PASSWORD";   // ← YOUR NETWORK PASSWORD

// Server Configuration
const char* SERVER_IP = "192.168.1.100";  // ← YOUR MACHINE IP
```

**Find your machine IP:**
```bash
hostname -I
# or
ip addr show | grep "inet " | grep -v "127.0.0.1"
```

### Compile & Upload

```bash
# 1. Compile (first time only, or when sketch changes)
cd /home/art/.openclaw/workspace/scripts/hardware
arduino-cli compile -b esp32:esp32:esp32 morpheus_client/morpheus_client.ino

# 2. Upload to ESP32
arduino-cli upload -p /dev/ttyUSB0 -b esp32:esp32:esp32 morpheus_client/morpheus_client.ino
```

### Monitor Serial Output

After upload, watch the ESP32's status:

```bash
# Option 1: Arduino CLI monitor
arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200

# Option 2: screen (Ctrl+A then Ctrl+X to exit)
screen /dev/ttyUSB0 115200

# Option 3: minicom
minicom -D /dev/ttyUSB0 -b 115200
```

## Full End-to-End Test

1. **Terminal 1:** Monitor server
```bash
tail -f /home/art/.openclaw/workspace/logs/morpheus-decisions.jsonl | jq .
```

2. **Terminal 2:** Watch ESP32 serial
```bash
arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
```

3. **Terminal 3:** (After upload) Watch the magic happen!
```bash
# ESP32 reads sensor → Posts to /api/decide → Gets decision → Executes (LED blink, relay on/off)
```

## Hardware Wiring

### Default Pin Configuration (Edit morpheus_client.ino if different)

```
ESP32 Pin 2  → Built-in LED (D2 on most boards)
ESP32 Pin 4  → Relay/Actuator control (GPIO 4)
ESP32 A0     → Analog sensor input (ADC)
```

### Example Setup

**Temperature Sensor (DHT22 or LM35):**
- VCC → 3.3V
- GND → GND
- Data → A0 (or GPIO 34/35 for other ADCs)

**Relay Module:**
- IN → GPIO 4 (or change RELAY_PIN)
- VCC → 5V (via external supply)
- GND → GND (share with ESP32)

**LED:**
- Anode → GPIO 2 (via 330Ω resistor)
- Cathode → GND

## Decision Rules

Current rules in morpheus-server.jl:

| Sensor | Condition | Decision | Action |
|--------|-----------|----------|--------|
| temperature | value > 30°C | relay_on | Activate cooling |
| temperature | value < 5°C | relay_off | Stop cooling |
| temperature | 5-30°C | idle | No action |
| light | value > 800 | alert | Trigger alert |
| motion | value > 0.5 | blink | Blink LED |

**To customize:** Edit `make_decision()` function in `morpheus-server.jl`

## Troubleshooting

### ESP32 Not Detected
```bash
# Check USB connection
ls -la /dev/ttyUSB*

# Install CH340 driver if needed (common ESP32 boards)
sudo apt-get install ch340-dkms
```

### Upload Fails
```bash
# Try specifying the exact board
arduino-cli upload -p /dev/ttyUSB0 -b esp32:esp32:esp32 \
  -P net.squix.esp8266.arduino.cores.esp32.CpuFreq=240 \
  morpheus_client/morpheus_client.ino
```

### WiFi Connection Fails
- Check SSID/password spelling
- Verify router isn't filtering MAC addresses
- Ensure 2.4GHz WiFi (ESP32 doesn't support 5GHz on many boards)

### Server Not Responding
```bash
# Check if server is still running
ps aux | grep morpheus-server

# Restart if needed
pkill -f morpheus-server.jl
/snap/julia/165/bin/julia /home/art/.openclaw/workspace/scripts/hardware/morpheus-server.jl &
```

## Next: Deploy Real ML

Once hardware is working:

1. Replace simple rules in `make_decision()` with real Codex/Scout spawning
2. Add agent routing based on decision complexity
3. Log outcomes to RL system
4. Retrain models based on hardware feedback

---

**Status:** Hardware ready. Waiting for sketch upload. 🚀
