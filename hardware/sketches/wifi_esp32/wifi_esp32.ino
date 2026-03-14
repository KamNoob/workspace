/*
  WiFi Connection Test - ESP32
  
  Connects to WiFi and reports signal strength.
  Foundation for Morpheus integration.
  
  Setup:
  1. Update SSID and PASSWORD below
  2. Compile and upload to ESP32
  3. Open Serial Monitor (9600 baud)
*/

#include <WiFi.h>

// WiFi credentials - UPDATE THESE
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";

void setup() {
  Serial.begin(9600);
  delay(100);
  
  Serial.println("\n\nESP32 WiFi Test");
  Serial.println("===============");
  
  connectToWiFi();
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connected to: ");
    Serial.println(WiFi.SSID());
    Serial.print("Signal strength (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi disconnected. Attempting reconnect...");
    connectToWiFi();
  }
  
  delay(5000); // Check every 5 seconds
}

void connectToWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi connected successfully!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("Failed to connect to WiFi");
  }
}
