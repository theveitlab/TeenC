int value;

void setup() {
// Establishing connection to serial port
  Serial.begin(128000);
}

void loop() {
// Pauses the loop until data is available on the serial port
  while(Serial.available() <= 0){}
  
  while(Serial.available() > 0) {

// Read the value from the serial port
    value = Serial.read();
    
// Send out the value to the serial port
    Serial.write(value);

// Transmits the data stored in the buffer immediately
    Serial.send_now();    
  }
}
