#include <Arduino.h>
#include <Wire.h>
#include "SHT31.h"
#include "rgb_lcd.h"
// Objects
SHT31 sht31 = SHT31();
rgb_lcd lcd;
// Vars
const int colorR = 183;
const int colorG = 37;
const int colorB = 248;
int soilMoisturePin0 = A0;
int soilMoisturePin1 = A1;
int soilMoistureValue0 = 0;
int soilMoistureValue1 = 0;

void setup() {
    Serial.begin(9600);
    // sht31
    while (!Serial);
    Serial.println("begin...");
    sht31.begin();
    //rgb_lcd
    lcd.begin(16, 2);
    lcd.setRGB(colorR, colorG, colorB);
    delay(1000);
}

void loop() {
    // get & print temp
    float temp = sht31.getTemperature();
    float hum = sht31.getHumidity();
    Serial.print("\nTemp = ");
    Serial.print(temp);
    Serial.print(" C");
    Serial.print("\nHum = ");
    Serial.print(hum);
    Serial.println("%");
    delay(1000);
    // get & print moisture
    soilMoistureValue0 = analogRead(soilMoisturePin0);
    soilMoistureValue1 = analogRead(soilMoisturePin1);
    Serial.print("Plant1 = ");
    Serial.print(soilMoistureValue0);
    Serial.print("\nPlant2 = ");
    Serial.print(soilMoistureValue1);
    delay(1000);
    // print temp&hum to lcd
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Temp: ");
    lcd.print(temp);
    lcd.setCursor(0, 1);
    lcd.print("RH: ");
    lcd.print(hum);
    delay(1000);
    // print moisture to lcd
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Plant1 H2O: ");
    lcd.print(soilMoistureValue0);
    lcd.setCursor(0, 1);
    lcd.print("Plant2 H2O: ");
    lcd.print(soilMoistureValue1);
    delay(1000);
}
