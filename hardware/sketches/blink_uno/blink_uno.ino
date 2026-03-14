/*
  Blink - Simple LED test for Arduino UNO
  
  Toggles an LED on pin 13 every second.
  Perfect for verifying board connection.
  
  Circuit:
  - Connect LED anode (long leg) to pin 13 via 220Ω resistor
  - Connect LED cathode (short leg) to GND
  
  Or just use the built-in LED on most Arduino boards.
*/

void setup() {
  // Initialize digital pin 13 as an output
  pinMode(13, OUTPUT);
  
  // Optional: Serial for debugging
  Serial.begin(9600);
  Serial.println("Blink started on pin 13");
}

void loop() {
  digitalWrite(13, HIGH);   // Turn LED on
  delay(1000);              // Wait 1 second
  
  digitalWrite(13, LOW);    // Turn LED off
  delay(1000);              // Wait 1 second
}
