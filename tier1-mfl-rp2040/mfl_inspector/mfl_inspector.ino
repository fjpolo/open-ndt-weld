#include <Wire.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_NeoPixel.h>

#define ANCHO_OLED 128
#define ALTO_OLED 64

Adafruit_SSD1306 display(ANCHO_OLED, ALTO_OLED, &Wire, -1);

// Pin Definitions
const int pinSensor1 = 26;   // GP26 (A0) -> Hall Sensor 1
const int pinSensor2 = 27;   // GP27 (A1) -> Hall Sensor 2
const int pinBoton   = 2;    // GP2 Calibration Button
const int pinAlarma  = 8;    // GP8 Buzzer
const int pinRGB     = 16;   // GP16 NeoPixel RGB

float offsetDiferencial = 0.0;
const int umbral = 40;       // Differential gradient threshold

Adafruit_NeoPixel ledRGB(1, pinRGB, NEO_GRB + NEO_KHZ800);

void calibrar();

void setup() {
  analogReadResolution(12);
  pinMode(pinBoton, INPUT_PULLUP);
  pinMode(pinAlarma, OUTPUT);

  ledRGB.begin();
  ledRGB.setBrightness(60);

  Wire.setSDA(4);
  Wire.setSCL(5);
  Wire.begin();
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  display.setTextColor(SSD1306_WHITE);

  calibrar();
}

void loop() {
  if (digitalRead(pinBoton) == LOW) {
    calibrar();
    delay(300);
  }

  // Interleaved oversampling to minimize phase lag between sensors
  long suma1 = 0, suma2 = 0;
  for (int i = 0; i < 20; i++) {
    suma1 += analogRead(pinSensor1);
    suma2 += analogRead(pinSensor2);
    delayMicroseconds(100);
  }

  float lec1 = suma1 / 20.0;
  float lec2 = suma2 / 20.0;

  // DIFFERENTIAL SUBTRACTION: Rejects lift-off, vibration, and background drift
  int gradiente = abs((int)((lec1 - lec2) - offsetDiferencial));
  bool falla = (gradiente > umbral);

  // Output Alerts
  digitalWrite(pinAlarma, falla ? HIGH : LOW);
  ledRGB.setPixelColor(0, falla ? ledRGB.Color(255, 0, 0) : ledRGB.Color(0, 255, 0));
  ledRGB.show();

  // Graphical OLED Display
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.print(falla ? "! GRIETA !" : "OK - GRAD");

  display.setTextSize(1);
  display.setCursor(0, 24);
  display.print("Dif: ");
  display.print(gradiente);
  display.print("  (Lim: ");
  display.print(umbral);
  display.print(")");

  display.drawRect(0, 38, 128, 18, SSD1306_WHITE);
  int anchoBarra = map(constrain(gradiente, 0, umbral * 2), 0, umbral * 2, 0, 124);
  display.fillRect(2, 40, anchoBarra, 14, SSD1306_WHITE);
  display.drawLine(64, 35, 64, 59, SSD1306_WHITE);

  display.display();
  delay(15);
}

void calibrar() {
  ledRGB.setPixelColor(0, ledRGB.Color(0, 0, 255));
  ledRGB.show();

  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(5, 22);
  display.print("TARANDO...");
  display.display();

  long sumaDif = 0;
  for (int i = 0; i < 80; i++) {
    int s1 = analogRead(pinSensor1);
    int s2 = analogRead(pinSensor2);
    sumaDif += (s1 - s2);
    delay(5);
  }
  offsetDiferencial = sumaDif / 80.0;

  digitalWrite(pinAlarma, HIGH);
  delay(80);
  digitalWrite(pinAlarma, LOW);
}
