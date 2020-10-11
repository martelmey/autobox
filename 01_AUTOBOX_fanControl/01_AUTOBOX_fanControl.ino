#include <Arduino.h>
#include <Wire.h>
#include "DHT.h"
#include <stdint.h>
#include <TFTv2.h>

#define DHTPIN 2
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

#if defined(ARDUINO_ARCH_AVR)
#define SERIAL  Serial
#elif defined(ARDUINO_ARCH_SAMD) ||  defined(ARDUINO_ARCH_SAM)
#define SERIAL  SerialUSB
#else
#define SERIAL  Serial
#endif

int relay = 40;

void setup() {
    SERIAL.begin(500000); 
    SERIAL.println("begin...");
    Wire.begin();
    dht.begin();
    pinMode(relay, OUTPUT);
    TFT_BL_ON;
    Tft.TFTinit();
    SERIAL.println("TFT init ....");
}

void loop() {
  //Display
  for (int r = 0; r < 115; r = r + 2) {
    Tft.drawCircle(119, 160, r, random(0xFFFF));
  }
  delay(10);
  //Temp&Hum
  float temp_hum_val[2] = {0};
  if(!dht.readTempAndHumidity(temp_hum_val)){
    SERIAL.print("Humidity: "); 
    SERIAL.print(temp_hum_val[0]);
    SERIAL.print(" %\t");
    SERIAL.print("Temperature: "); 
    SERIAL.print(temp_hum_val[1]);
    SERIAL.println(" *C");
    //Relay
    if(temp_hum_val[1]>25.00){
      digitalWrite(relay,HIGH);
    }
    else{
      digitalWrite(relay,LOW);
    }
  }
  else{
    SERIAL.println("Failed to get temprature and humidity value.");
  }
  delay(1500);
}
