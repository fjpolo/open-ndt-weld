#include <Arduino.h>
#include <Wire.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_NeoPixel.h>

#define OLED_WIDTH 128
#define OLED_HEIGHT 64

Adafruit_SSD1306 display(OLED_WIDTH, OLED_HEIGHT, &Wire, -1);

// Pin Definitions (RP2040-Zero)
const int pinSensor1 = 26;   // GP26 (A0) -> Hall Sensor 1
const int pinSensor2 = 27;   // GP27 (A1) -> Hall Sensor 2
const int pinButton  = 2;    // GP2 Calibration Button
const int pinBuzzer  = 8;    // GP8 Buzzer
const int pinRGB     = 16;   // GP16 NeoPixel RGB

float differentialOffset = 0.0;
const int threshold = 40;    // Differential gradient threshold

Adafruit_NeoPixel ledRGB(1, pinRGB, NEO_GRB + NEO_KHZ800);

void calibrate();

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  pinMode(pinButton, INPUT_PULLUP);
  pinMode(pinBuzzer, OUTPUT);

  ledRGB.begin();
  ledRGB.setBrightness(60);

  Wire.setSDA(4);
  Wire.setSCL(5);
  Wire.begin();
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setTextColor(SSD1306_WHITE);

  calibrate();
}

void loop() {
  if (digitalRead(pinButton) == LOW) {
    calibrate();
    delay(300);
  }

  // Interleaved oversampling to minimize phase lag between sensors
  long sum1 = 0, sum2 = 0;
  for (int i = 0; i < 20; i++) {
    sum1 += analogRead(pinSensor1);
    sum2 += analogRead(pinSensor2);
    delayMicroseconds(100);
  }

  float read1 = sum1 / 20.0;
  float read2 = sum2 / 20.0;

  // DIFFERENTIAL SUBTRACTION: Rejects lift-off, vibration, and background drift
  int gradient = abs((int)((read1 - read2) - differentialOffset));
  bool defectDetected = (gradient > threshold);

  // USB Serial Telemetry (Arduino Serial Plotter & CSV compatible)
  Serial.print("S1:");
  Serial.print(read1, 1);
  Serial.print(",S2:");
  Serial.print(read2, 1);
  Serial.print(",Grad:");
  Serial.print(gradient);
  Serial.print(",Lim:");
  Serial.print(threshold);
  Serial.print(",Defect:");
  Serial.println(defectDetected ? 1 : 0);

  // Output Alerts
  digitalWrite(pinBuzzer, defectDetected ? HIGH : LOW);
  ledRGB.setPixelColor(0, defectDetected ? ledRGB.Color(255, 0, 0) : ledRGB.Color(0, 255, 0));
  ledRGB.show();

  // Graphical OLED Display
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.print(defectDetected ? "! CRACK !" : "OK - GRAD");

  display.setTextSize(1);
  display.setCursor(0, 24);
  display.print("Diff: ");
  display.print(gradient);
  display.print("  (Lim: ");
  display.print(threshold);
  display.print(")");

  display.drawRect(0, 38, 128, 18, SSD1306_WHITE);
  int barWidth = map(constrain(gradient, 0, threshold * 2), 0, threshold * 2, 0, 124);
  display.fillRect(2, 40, barWidth, 14, SSD1306_WHITE);
  display.drawLine(64, 35, 64, 59, SSD1306_WHITE);

  display.display();
  delay(15);
}

void calibrate() {
  ledRGB.setPixelColor(0, ledRGB.Color(0, 0, 255));
  ledRGB.show();

  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(10, 22);
  display.print("TARING...");
  display.display();

  long diffSum = 0;
  for (int i = 0; i < 80; i++) {
    int s1 = analogRead(pinSensor1);
    int s2 = analogRead(pinSensor2);
    diffSum += (s1 - s2);
    delay(5);
  }
  differentialOffset = diffSum / 80.0;

  digitalWrite(pinBuzzer, HIGH);
  delay(80);
  digitalWrite(pinBuzzer, LOW);
}
