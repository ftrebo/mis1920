/********************************************************************************************************/
/* Nunchuck integration for visuals                                                                     */
/* Authors: Francesco Trebo, Domenico Stefani                                                           */
/********************************************************************************************************/

#include <Wire.h>
#include <ArduinoNunchuk.h>

const byte motorPin = 13;
const int maxIdleTime = 2000; // if no movement detected, level down [ms]


/*DO NOT CHANGE OR DELETE**************************************/
ArduinoNunchuk nunchuk = ArduinoNunchuk();                  /**/
unsigned long previousMillis = millis();                                /**/
unsigned long currentMillis = 0;                                        /**/
unsigned long t_tempo_received;                             /**/
int t_diff = 0;                                             /**/
int bpm = 0;                                                /**/
int bpm_prev1 = 0; // bpm at last hit                       /**/
int bpm_prev2 = 0;                                          /**/
int bpm_media = 0;                                          /**/
int prevAccelValue = 0;                                     /**/
int prevXValue = 0;                                         /**/
int prevYValue = 0;                                         /**/
/**************************************************************/

void setup() {
  Serial.begin(19200);
  nunchuk.init();
  pinMode(motorPin, OUTPUT);
}

void loop() {
  currentMillis = millis();
  t_diff = currentMillis - previousMillis;

  if (t_diff > maxIdleTime) {
    Serial.println("T-0");
    previousMillis = currentMillis;
  }

  nunchuk.update();
  if ((nunchuk.accelZ > 900) && (prevAccelValue < 900)) {
    bpm_prev2 = bpm_prev1;
    bpm_prev1 = bpm;
    bpm = 60000 / t_diff;
    bpm_media = (bpm_prev2 + bpm_prev1 + bpm) / 3;
    Serial.println("T-" + String(bpm_media));
    previousMillis = currentMillis;
  }
  prevAccelValue = nunchuk.accelZ;

  if (nunchuk.analogY != prevYValue) {
    Serial.println("Y-" + String(nunchuk.analogY));
    prevYValue = nunchuk.analogY;
  }

  if (nunchuk.analogX != prevXValue) {
    Serial.println("X-" + String(nunchuk.analogX));
    prevXValue = nunchuk.analogX;
  }

  if (currentMillis > (unsigned long)(t_tempo_received + 75)) digitalWrite(motorPin, LOW);
  else if (currentMillis > t_tempo_received) digitalWrite(motorPin, HIGH);
}

void serialEvent() {
  while (Serial.available()) {
    Serial.read();
    digitalWrite(motorPin, LOW);
    t_tempo_received = millis() + 105; //delay to sync with audio
  }
}
