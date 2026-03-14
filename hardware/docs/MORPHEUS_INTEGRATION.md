# Morpheus + Hardware Integration

_Connect your Arduino/ESP32 boards to your AI system._

---

## Overview

**Goal:** ESP32 boards (and Arduino) → HTTP API → Morpheus decision engine

**Architecture:**
```
[ESP32 Sensor/Device]
    ↓ HTTP POST (JSON)
[Julia API Server] (localhost:8000)
    ↓ queries
[Morpheus] (spawner-matrix.jl, memory search)
    ↓ returns decision
[ESP32] executes action
```

---

## Phase 1: Local HTTP Server (Julia)

### What we need
1. HTTP server listening on `localhost:8000`
2. Accept JSON requests from ESP32
3. Query Morpheus for decisions
4. Return action JSON to device

### Example Request (from ESP32)
```json
{
  "device_id": "esp32-living-room",
  "sensor": "temperature",
  "value": 22.5,
  "unit": "celsius",
  "task": "climate_control"
}
```

### Example Response (from Morpheus)
```json
{
  "decision": "heat",
  "confidence": 0.85,
  "agent": "Sentinel",
  "action": {
    "type": "adjustment",
    "target": "thermostat",
    "value": 23
  }
}
```

### Implementation Plan

**Step 1:** Create HTTP server in Julia (using HTTP.jl)
```julia
# hardware/morpheus-api-server.jl
using HTTP
using JSON

# Connect to spawner-matrix (agent selection)
# Query memory search for context
# Return decisions to devices
```

**Step 2:** Wire into spawner-matrix.jl
```julia
# Include endpoint: POST /api/decide
# Calls spawner-matrix internally
# Returns agent decision + reasoning
```

**Step 3:** Deploy locally
```bash
julia morpheus-api-server.jl
# Server running on http://localhost:8000
```

---

## Phase 2: ESP32 Client Code

### Connect to Morpheus API

**WiFi + HTTP Client:**
```cpp
// sketches/morpheus-client-template/morpheus_client.ino

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* MORPHEUS_API = "http://192.168.1.100:8000/api/decide";

void requestDecision(String sensor, float value) {
  HTTPClient http;
  http.begin(MORPHEUS_API);
  http.addHeader("Content-Type", "application/json");
  
  // Build request JSON
  DynamicJsonDocument doc(256);
  doc["device_id"] = "esp32-1";
  doc["sensor"] = sensor;
  doc["value"] = value;
  
  String payload;
  serializeJson(doc, payload);
  
  // Send request
  int httpCode = http.POST(payload);
  
  if (httpCode == 200) {
    String response = http.getString();
    
    // Parse response
    DynamicJsonDocument respDoc(256);
    deserializeJson(respDoc, response);
    
    String action = respDoc["action"];
    executeAction(action);
  }
  
  http.end();
}
```

---

## Phase 3: Real-World Scenarios

### Scenario 1: Sensor Fusion
3 ESP32 boards (temperature, humidity, light) → Morpheus → Optimal decision
```
Sensor 1 (temp): 22°C → Morpheus
Sensor 2 (humidity): 45% → Morpheus  
Sensor 3 (light): 500 lux → Morpheus
                              ↓
                    Which agent to spawn?
                    Sentinel? (infrastructure)
                    Echo? (creative solution)
                    Lens? (analytics)
```

### Scenario 2: Multi-Device Coordination
- Device A wants to turn on heat
- Device B reports power usage
- Morpheus decides: heat on + dim lights to save power

### Scenario 3: Learning Loop
1. ESP32 sends sensor data
2. Morpheus makes decision + agent spawned
3. Outcome logged to RL system
4. Q-values updated
5. Next decision is smarter

---

## Next Steps

### Short-term (This week)
- [ ] Create morpheus-api-server.jl (Julia HTTP server)
- [ ] Wire into spawner-matrix.jl
- [ ] Test locally (curl requests)
- [ ] Create morpheus-client-template ESP32 sketch

### Medium-term (Next 2 weeks)
- [ ] Deploy to actual hardware (ESP32 + UNO)
- [ ] Add sensor data logging
- [ ] Implement feedback loop (outcome → RL)
- [ ] Multi-device coordination

### Long-term
- [ ] WebSocket support (real-time updates)
- [ ] Local model inference on ESP32
- [ ] Encrypted device communication
- [ ] Mobile app for monitoring

---

## File Structure

```
hardware/
├── SETUP.md                          (this file)
├── sketches/
│   ├── blink_uno/                    (simple test)
│   ├── wifi_esp32/                   (WiFi connection)
│   ├── sensor_demo/                  (read sensor → log)
│   └── morpheus-client-template/     (API client)
├── morpheus-api-server.jl            (Julia server, TBD)
├── docs/
│   ├── MORPHEUS_INTEGRATION.md       (this file)
│   ├── ESP32_REFERENCE.md            (pinouts, specs)
│   └── ARDUINO_REFERENCE.md          (UNO reference)
└── arduino-cli-wrapper.sh            (convenience script)
```

---

## Testing Checklist

- [ ] Arduino CLI installed & boards configured
- [ ] ESP32 connects to WiFi (run wifi_esp32 sketch)
- [ ] Morpheus API server running locally
- [ ] ESP32 makes HTTP request to server
- [ ] Server returns valid JSON decision
- [ ] ESP32 executes decision (e.g., LED on/off)
- [ ] RL system logs outcome

---

## Debugging

### ESP32 can't reach API
```
1. Check WiFi connection (run wifi_esp32 sketch)
2. Verify API server is running: curl http://localhost:8000/health
3. Check firewall: sudo ufw allow 8000
4. Try with IP address instead of hostname
```

### JSON parsing fails
```
1. Enable Serial.println() debugging
2. Print raw HTTP response
3. Validate JSON format at jsonlint.com
```

### Upload fails
```
1. Check USB cable (try different port)
2. Reset ESP32: press RST button during upload
3. Verify board alias in command
4. Check permissions: sudo usermod -aG dialout $USER
```

---

_Integration roadmap created: 2026-03-14 12:26 GMT_  
_Status: Phase 1 (design) complete. Ready for Phase 2 (implementation)._
