/*
  Morpheus Client - ESP32 Hardware Integration
  
  Reads sensor data, sends to Morpheus decision server, executes decision.
  WiFi → HTTP POST → AI Decision → Execute (LED blink, relay, etc.)
  
  Prerequisites:
  - ESP32 board (Wemos D1 Mini ESP32, TTGO T-Display, etc.)
  - WiFi network credentials
  - Morpheus server running on host machine (port 8000)
  
  Setup:
  1. Define WiFi credentials (SSID, PASSWORD)
  2. Set SERVER_IP to your Morpheus host IP
  3. Upload to ESP32 via Arduino CLI
  
  Hardware Pins:
  - LED: GPIO 2 (built-in)
  - Relay/Actuator: GPIO 4 (customize as needed)
  - Analog sensor: A0 (ADC)
*/

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi Configuration
const char* SSID = "NETGEAR-2G";
const char* PASSWORD = "aggressivewhale457";

// Server Configuration
const char* SERVER_IP = "192.168.0.210";  // Change to your machine IP
const int SERVER_PORT = 8000;
const char* ENDPOINT = "/api/decide";

// Hardware Pins
const int LED_PIN = 2;          // Built-in LED
const int RELAY_PIN = 4;        // Relay/actuator control
const int SENSOR_PIN = A0;      // Analog sensor input

// Timing
unsigned long lastDecisionTime = 0;
const unsigned long DECISION_INTERVAL = 5000;  // Every 5 seconds

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // Initialize hardware
  pinMode(LED_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(SENSOR_PIN, INPUT);
  
  digitalWrite(LED_PIN, LOW);
  digitalWrite(RELAY_PIN, LOW);
  
  Serial.println("\n\n=== Morpheus Client Starting ===");
  Serial.println("Initializing WiFi connection...");
  
  // Connect to WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi Failed - will retry...");
  }
  
  Serial.print("Server: http://");
  Serial.print(SERVER_IP);
  Serial.print(":");
  Serial.print(SERVER_PORT);
  Serial.println(ENDPOINT);
  Serial.println("=== Ready ===\n");
}

void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    digitalWrite(LED_PIN, HIGH);  // LED on = error
    delay(1000);
    return;
  }
  
  // Request decision at interval
  if (millis() - lastDecisionTime >= DECISION_INTERVAL) {
    lastDecisionTime = millis();
    requestDecision();
  }
  
  delay(100);
}

void requestDecision() {
  // Read sensor
  int sensorValue = analogRead(SENSOR_PIN);
  float temperature = map(sensorValue, 0, 4095, -40, 85);  // Example: -40 to +85°C
  
  Serial.print("Sensor: ");
  Serial.print(sensorValue);
  Serial.print(" -> ");
  Serial.print(temperature);
  Serial.println("°C");
  
  // Build JSON payload
  StaticJsonDocument<256> doc;
  doc["sensor"] = "temperature";
  doc["value"] = temperature;
  doc["unit"] = "C";
  doc["timestamp"] = millis();
  doc["device_id"] = "ESP32_001";
  
  // Serialize to string
  String payload;
  serializeJson(doc, payload);
  
  Serial.print("Sending: ");
  Serial.println(payload);
  
  // Make HTTP request
  HTTPClient http;
  String url = "http://" + String(SERVER_IP) + ":" + String(SERVER_PORT) + String(ENDPOINT);
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  int httpCode = http.POST(payload);
  
  if (httpCode == HTTP_CODE_OK) {
    String response = http.getString();
    Serial.print("Response: ");
    Serial.println(response);
    
    // Parse decision and execute
    StaticJsonDocument<256> responseDoc;
    DeserializationError error = deserializeJson(responseDoc, response);
    
    if (!error) {
      const char* decision = responseDoc["decision"];
      bool execute = responseDoc["execute"] | false;
      
      Serial.print("Decision: ");
      Serial.println(decision);
      
      if (execute) {
        executeDecision(decision);
      }
    } else {
      Serial.print("JSON parse error: ");
      Serial.println(error.c_str());
    }
  } else {
    Serial.print("HTTP Error: ");
    Serial.println(httpCode);
    digitalWrite(LED_PIN, HIGH);
    delay(500);
    digitalWrite(LED_PIN, LOW);
  }
  
  http.end();
}

void executeDecision(const char* decision) {
  Serial.print(">>> Executing: ");
  Serial.println(decision);
  
  // Decode decision and execute hardware action
  if (strcmp(decision, "blink") == 0) {
    blink(3);
  } 
  else if (strcmp(decision, "relay_on") == 0) {
    digitalWrite(RELAY_PIN, HIGH);
    Serial.println("    Relay ON");
  } 
  else if (strcmp(decision, "relay_off") == 0) {
    digitalWrite(RELAY_PIN, LOW);
    Serial.println("    Relay OFF");
  } 
  else if (strcmp(decision, "alert") == 0) {
    blink(10);
  } 
  else if (strcmp(decision, "idle") == 0) {
    digitalWrite(LED_PIN, LOW);
    digitalWrite(RELAY_PIN, LOW);
  }
}

void blink(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
}
