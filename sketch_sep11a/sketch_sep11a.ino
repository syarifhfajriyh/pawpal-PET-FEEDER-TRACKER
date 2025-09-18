#include "HX711.h"

// Pin configuration for ESP32 (adjust to your wiring)
#define DT  18   // HX711 DT pin
#define SCK 19   // HX711 SCK pin

HX711 scale;

void setup() {
  Serial.begin(115200);
  Serial.println("HX711 Load Cell Test on ESP32...");

  scale.begin(DT, SCK);
  scale.set_gain(128);

  if (!scale.is_ready()) {
    Serial.println("HX711 not found.");
    while (1); // stop program
  } else {
    Serial.println("HX711 connected!");
  }
}

void loop() {
  if (scale.is_ready()) {
    long reading = scale.read();  // raw ADC value
    Serial.print("Raw reading: ");
    Serial.println(reading);
  } else {
    Serial.println("HX711 not ready");
  }
  delay(500);
}
