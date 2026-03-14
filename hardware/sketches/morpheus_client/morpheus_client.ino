/*
 * morpheus_client.ino
 * 
 * ESP32 Client for Morpheus Decision Server
 * 
 * Sends sensor data to Morpheus server and executes returned decisions.
 * 
 * Hardware:
 *   - ESP32 Dev Module
 *   - DHT11 temperature sensor (pin 14)
 *   - LED (pin 13)
 *   - Servo (pin 15) [optional]
 * 
 * Setup:
 *   1. Update SSID and PASSWORD below
 *   2. Set MORPHEUS_SERVER to your server IP:port
 *   3. Upload to ESP32
 *   4. Open Serial Monitor (115200 baud)
 */

#include <WiFi.h>
#include <ArduinoJson.h>

// WiFi Configuration
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

// Morpheus Server Configuration
const char* morpheus_host = "192.168.1.100";  // Change to your server IP
const int morpheus_port = 8000;

// Hardware Pins
const int SENSOR_PIN = 14;     // DHT11 on GPIO14
const int LED_PIN = 13;        // LED on GPIO13
const int SERVO_PIN = 15;      // Servo on GPIO15

// Timing
unsigned long last_request = 0;
const unsigned long REQUEST_INTERVAL = 5000;  // Request every 5 seconds

// ============================================================================
// WiFi Setup
// ============================================================================

void setup_wifi() {
  Serial.print("\nConnecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n✗ WiFi connection failed!");
  }
}

// ============================================================================
// Sensor Reading
// ============================================================================

float read_temperature() {
  /*
   * Read temperature from DHT11 sensor
   * For demo: use analog input + analog-to-temperature conversion
   * In production: use DHT library
   */
  
  // Simple demo: return simulated temperature (20-30°C)
  int raw = analogRead(SENSOR_PIN);
  float temp = 20.0 + (raw / 4095.0) * 10.0;
  return temp;
}

int read_light_level() {
  /*
   * Read light level from analog pin
   * ADC range: 0-4095 (0-3.3V)
   */
  return analogRead(35);  // GPIO35 (ADC)
}

bool read_motion() {
  /*
   * Read motion sensor (PIR)
   * HIGH = motion detected
   */
  return digitalRead(SENSOR_PIN) == HIGH;
}

// ============================================================================
// Morpheus Communication
// ============================================================================

String send_request_to_morpheus(String sensor_data) {
  /*
   * Send sensor data to Morpheus and get decision back
   */
  
  WiFiClient client;
  
  if (!client.connect(morpheus_host, morpheus_port)) {
    Serial.println("✗ Connection to Morpheus failed!");
    return "";
  }
  
  Serial.println("✓ Connected to Morpheus");
  
  // Build HTTP request
  String request = "POST /api/decide HTTP/1.1\r\n";
  request += "Host: " + String(morpheus_host) + "\r\n";
  request += "Content-Type: application/json\r\n";
  request += "Content-Length: " + String(sensor_data.length()) + "\r\n";
  request += "Connection: close\r\n";
  request += "\r\n";
  request += sensor_data;
  
  // Send request
  client.print(request);
  
  // Read response
  String response = "";
  unsigned long timeout = millis() + 5000;  // 5 second timeout
  
  while (client.connected() && millis() < timeout) {
    if (client.available()) {
      char c = client.read();
      response += c;
    }
  }
  
  client.stop();
  
  // Extract JSON body from HTTP response
  int body_start = response.indexOf("\r\n\r\n") + 4;
  if (body_start > 4) {
    response = response.substring(body_start);
  }
  
  return response;
}

// ============================================================================
// Decision Execution
// ============================================================================

void execute_decision(String decision_json) {
  /*
   * Parse decision JSON and execute action
   */
  
  DynamicJsonDocument doc(512);
  DeserializationError error = deserializeJson(doc, decision_json);
  
  if (error) {
    Serial.print("✗ JSON parse failed: ");
    Serial.println(error.c_str());
    return;
  }
  
  String decision = doc["decision"];
  
  Serial.print("Decision: ");
  Serial.println(decision);
  
  // Execute action based on decision
  if (decision == "alert") {
    // Blink LED 3 times
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_PIN, HIGH);
      delay(200);
      digitalWrite(LED_PIN, LOW);
      delay(200);
    }
    Serial.println("→ Alert: LED blinked 3 times");
    
  } else if (decision == "low_light") {
    // Turn on LED
    digitalWrite(LED_PIN, HIGH);
    Serial.println("→ LED turned ON (low light)");
    
  } else if (decision == "motion_detected") {
    // Pulse LED
    for (int i = 0; i < 2; i++) {
      digitalWrite(LED_PIN, HIGH);
      delay(100);
      digitalWrite(LED_PIN, LOW);
      delay(100);
    }
    Serial.println("→ Motion detected: LED pulsed");
    
  } else if (decision == "process") {
    // Just log
    Serial.println("→ Decision processed");
  }
}

// ============================================================================
// Setup & Loop
// ============================================================================

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n🌐 Morpheus ESP32 Client");
  Serial.println("========================\n");
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  pinMode(SENSOR_PIN, INPUT);
  
  // Connect to WiFi
  setup_wifi();
  
  // Initial blink to show ready
  digitalWrite(LED_PIN, HIGH);
  delay(200);
  digitalWrite(LED_PIN, LOW);
  delay(200);
  digitalWrite(LED_PIN, HIGH);
  delay(200);
  digitalWrite(LED_PIN, LOW);
  
  Serial.println("\n✓ Ready to send sensor data to Morpheus!");
}

void loop() {
  // Check if time to send request
  if (millis() - last_request < REQUEST_INTERVAL) {
    delay(100);
    return;
  }
  
  last_request = millis();
  
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("✗ WiFi disconnected, reconnecting...");
    setup_wifi();
    return;
  }
  
  // Read sensor
  float temperature = read_temperature();
  
  Serial.print("\n📊 Sending sensor data...");
  Serial.print("(temp: ");
  Serial.print(temperature);
  Serial.println("°C)");
  
  // Build sensor data JSON
  String sensor_data = "{\"device_id\":\"esp32-01\",";
  sensor_data += "\"sensor_type\":\"temperature\",";
  sensor_data += "\"value\":" + String(temperature) + "}";
  
  // Send to Morpheus
  String decision = send_request_to_morpheus(sensor_data);
  
  // Execute decision
  if (!decision.isEmpty()) {
    execute_decision(decision);
  } else {
    Serial.println("✗ No decision received");
  }
}
