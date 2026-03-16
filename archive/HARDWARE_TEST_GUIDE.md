# ESP32 Hardware Test Guide

_Ready to test with physical ESP32 connected via USB_

---

## ✅ Prerequisites

**Software:**
- ✅ Arduino CLI installed (`hardware/arduino-cli-wrapper.sh`)
- ✅ ESP32 sketches ready (`hardware/sketches/morpheus_client/`)
- ✅ Morpheus server script ready (`hardware/morpheus-api/morpheus-server.jl`)

**Hardware:**
- ✅ ESP32 Dev Module (connected via USB)
- ✅ DHT11 temperature sensor (optional - sketch has fallback)
- ✅ LED + 220Ω resistor (on GPIO 13)
- ✅ Power supply (USB provides 5V)

---

## 🔧 **Step 1: Verify Hardware Connection**

### Check if ESP32 is detected:

```bash
hardware/arduino-cli-wrapper.sh list-boards
# Should show: /dev/ttyUSB0 (or similar) ESP32 Dev Module
```

If not detected:
```bash
# Check USB connection
lsusb | grep -i esp32
# Or: ls -la /dev/ttyUSB*

# If needed: install driver (CP2102 or CH340)
sudo apt-get install -y ch340-dkms
# Then reconnect device
```

---

## 📝 **Step 2: Configure WiFi in Sketch**

Edit `hardware/sketches/morpheus_client/morpheus_client.ino`:

```cpp
// Line ~19-20: Update WiFi credentials
const char* ssid = "YOUR_SSID";           // Your WiFi network
const char* password = "YOUR_PASSWORD";   // Your WiFi password

// Line ~23: Update Morpheus server IP
const char* morpheus_host = "192.168.1.100";  // Your computer's IP
const int morpheus_port = 8000;
```

### Find your computer's IP:

```bash
# Linux/Mac:
hostname -I
# Shows: 192.168.1.XXX (use this)

# Or check Morpheus server startup message
# It will show: "Listening on http://127.0.0.1:8000"
# Use your machine's actual network IP instead of 127.0.0.1
```

---

## 🔨 **Step 3: Compile Sketch**

```bash
hardware/arduino-cli-wrapper.sh compile esp32 morpheus_client

# Output should show:
# ✓ Compiling sketch...
# ✓ Compile successful!
```

If errors, check:
- WiFi credentials are strings (in quotes)
- Port number is int (no quotes): 8000
- GPIO pins match (14, 13, 15)

---

## 📤 **Step 4: Upload to ESP32**

### Find the correct port:

```bash
hardware/arduino-cli-wrapper.sh list-boards
# Look for line like: /dev/ttyUSB0 Arduino ESP32 ...
```

### Upload:

```bash
hardware/arduino-cli-wrapper.sh upload esp32 /dev/ttyUSB0 morpheus_client

# Wait ~15 seconds for upload
# Should show: Upload completed!
```

### If upload fails:

**Error: "Waiting for packet header" timeout**
```bash
# Hold GPIO0 button to ground while uploading, release after upload starts
# Then retry:
hardware/arduino-cli-wrapper.sh upload esp32 /dev/ttyUSB0 morpheus_client
```

**Error: "Permission denied /dev/ttyUSB0"**
```bash
sudo chmod 666 /dev/ttyUSB0
# Or add user to dialout group:
sudo usermod -aG dialout $USER
# Log out and back in
```

---

## 🌐 **Step 5: Start Morpheus Server**

In a **new terminal** (keep it running):

```bash
cd /home/art/.openclaw/workspace
julia hardware/morpheus-api/morpheus-server.jl

# Should show:
# 🌐 Morpheus Decision Server
# ==================================================
# Listening on http://127.0.0.1:8000
```

### Verify server is running:

In another terminal:
```bash
curl http://127.0.0.1:8000/api/health
# Should respond with JSON status
```

---

## 📊 **Step 6: Monitor ESP32 Serial Output**

In a **third terminal**:

```bash
hardware/arduino-cli-wrapper.sh monitor /dev/ttyUSB0 115200

# Should show:
# 🌐 Morpheus ESP32 Client
# ========================
# Connecting to WiFi: YOUR_SSID
# ...
# ✓ WiFi connected!
# IP address: 192.168.1.105
# ✓ Ready to send sensor data to Morpheus!
```

### Serial Monitor Output

**Every 5 seconds, should see:**

```
📊 Sending sensor data...(temp: 24.5°C)
✓ Connected to Morpheus
Decision: alert
→ Alert: LED blinked 3 times
```

Or:
```
📊 Sending sensor data...(temp: 26.8°C)
✓ Connected to Morpheus
Decision: low_light
→ LED turned ON (low light)
```

---

## 🧪 **Full Test Loop (Complete System)**

### **Terminal 1: Morpheus Server**
```bash
julia hardware/morpheus-api/morpheus-server.jl
# (Keep running in background)
```

### **Terminal 2: ESP32 Serial Monitor**
```bash
hardware/arduino-cli-wrapper.sh monitor /dev/ttyUSB0 115200
# Watch for: "Connecting to WiFi", "Connected", "Sending sensor data"
```

### **Terminal 3: Test Calls to Morpheus**
```bash
# While ESP32 is sending:
curl -X POST http://127.0.0.1:8000/api/decide \
  -H 'Content-Type: application/json' \
  -d '{"device_id":"esp32-test","sensor_type":"temperature","value":27.5}'

# Response should be decision JSON:
# {"decision":"alert","action":{"type":"alert","message":"Temperature high"}...}
```

### **Watch LED Blink!**

When Morpheus sends decision, ESP32 executes:
- Temperature > 25°C → LED blinks 3 times ✨
- Light < 100 → LED stays on 💡
- Motion detected → LED pulses 2x 🔔
- Default → Message logged 📝

---

## 🎯 **Expected Behavior**

### Success Indicators
✅ ESP32 connects to WiFi (see "✓ WiFi connected" in serial)  
✅ ESP32 sends POST requests (see "📊 Sending sensor data")  
✅ Morpheus receives requests (check server logs)  
✅ LED responds to decisions (watch GPIO 13)  
✅ Serial shows decision execution (see "→ Alert", "→ LED turned ON", etc.)

### Troubleshooting

**ESP32 doesn't connect to WiFi:**
- Check SSID and password (must match exactly)
- WiFi must be 2.4GHz (not 5GHz)
- Check IP range (192.168.x.x typical)

**ESP32 connects but can't reach Morpheus:**
- Verify Morpheus server IP in sketch matches your computer
- Both must be on same network
- Check firewall (port 8000 must be open)
- Use `ifconfig` to find your actual IP (not 127.0.0.1)

**LED doesn't blink:**
- Check GPIO 13 wiring (220Ω resistor in series)
- Check power (LED long leg = positive)
- Check sketch uploaded correctly
- Monitor serial output for "→ Alert" messages

**Morpheus server won't start:**
- Port 8000 already in use: `lsof -i :8000`
- Kill process: `kill -9 <PID>`
- Or use different port in server code

---

## 📈 **Performance Monitoring**

### Check Morpheus Decision Log

```bash
# View last 5 decisions
tail -5 data/rl/morpheus-decisions.jsonl | jq '.'

# Count total decisions
wc -l data/rl/morpheus-decisions.jsonl
```

### Check Agent Router Predictions

```bash
# View spawner KB context usage
tail -5 data/rl/agent-router-spawns-with-kb.jsonl | jq '.'
```

---

## 🎉 **Success Checklist**

- [ ] ESP32 compiles without errors
- [ ] ESP32 uploads successfully
- [ ] Serial monitor shows "✓ WiFi connected"
- [ ] Serial monitor shows "✓ Ready to send sensor data"
- [ ] Morpheus server running (listening on :8000)
- [ ] `curl` to Morpheus returns JSON response
- [ ] Serial monitor shows "✓ Connected to Morpheus"
- [ ] Serial monitor shows "Decision: ..." messages
- [ ] LED blinks/lights up on decisions
- [ ] Decisions logged to morpheus-decisions.jsonl

---

## 📚 **Architecture Diagram**

```
┌─────────────────────┐
│   ESP32 Hardware    │
│  (GPIO 13 LED)      │
│  (DHT11 Sensor)     │
│  (WiFi 802.11)      │
└──────────┬──────────┘
           │
           │ WiFi: POST /api/decide
           │ JSON: {"sensor_type": "temperature", "value": 26.5}
           ↓
┌─────────────────────┐
│ Morpheus Server     │
│ (:8000)             │
│ - Parse request     │
│ - Generate decision │
│ - Log outcome       │
└──────────┬──────────┘
           │
           │ HTTP Response: {"decision": "alert", "action": {...}}
           │
           ↓
┌─────────────────────┐
│ ESP32 Executes      │
│ - Parse JSON        │
│ - Run action        │
│ - Blink LED         │
└─────────────────────┘
```

---

## 🚀 **Next Steps After Test**

1. **Log outcomes** for agent router retraining
2. **Test multiple sensors** (light, motion)
3. **Expand decisions** (servo control, relay switching)
4. **Collect metrics** (latency, success rate)
5. **Feed back to spawner** (improve agent selection)

---

## 📞 **Quick Command Reference**

```bash
# Compile
hardware/arduino-cli-wrapper.sh compile esp32 morpheus_client

# Upload
hardware/arduino-cli-wrapper.sh upload esp32 /dev/ttyUSB0 morpheus_client

# Monitor serial
hardware/arduino-cli-wrapper.sh monitor /dev/ttyUSB0 115200

# Start Morpheus
julia hardware/morpheus-api/morpheus-server.jl

# Test server
curl http://127.0.0.1:8000/api/health

# View decisions
tail data/rl/morpheus-decisions.jsonl | jq '.'
```

---

_Hardware Test Guide Ready_  
_Status: 🟢 Ready to Deploy_  
_Next: Connect ESP32 and run test!_
