/********************************************************************************************************/
/* Nunchuck integration for visuals                                                                     */
/* Authors: Francesco Trebo, Domenico Stefani                                                           */
/********************************************************************************************************/

#include <Wire.h>
#include <ArduinoNunchuk.h>

const byte motorPin = 13;
const int maxIdleTime = 2000; // if no movement detected, level down [ms]
const int audioSync = 105; // delay to sync with audio [ms]
const int accelThreshold = 900;


/*DO NOT CHANGE OR DELETE**************************************/
ArduinoNunchuk nunchuk = ArduinoNunchuk();                  /**/
unsigned long previousMillis = millis();                    /**/
unsigned long currentMillis = 0;                            /**/
unsigned long t_tempo_received;                             /**/
int t_diff = 0;                                             /**/
int bpm = 0;                                                /**/
int bpm_prev1 = 0;                                          /**/
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

  if (t_diff > maxIdleTime) {                         // if controller not moved for long time
    Serial.println("T-0");                            // send 0 tempo to processing
    previousMillis = currentMillis;
  }

  nunchuk.update();                                   //gets values from nunchuk
  if ((nunchuk.accelZ > accelThreshold) && (prevAccelValue < accelThreshold)) { 
    bpm_prev2 = bpm_prev1;
    bpm_prev1 = bpm;                                  // stores previous values
    bpm = 60000 / t_diff;
    bpm_media = (bpm_prev2 + bpm_prev1 + bpm) / 3;    // average of the last 3 hits, to mitigate errors
    Serial.println("T-" + String(bpm_media));         // send averaged tempo to processing
    previousMillis = currentMillis;
  }
  prevAccelValue = nunchuk.accelZ;

  if (nunchuk.analogY != prevYValue) {                // only if joystick vertical movement detected
    Serial.println("Y-" + String(nunchuk.analogY));   // send joystick Y value
    prevYValue = nunchuk.analogY;
  }

  if (nunchuk.analogX != prevXValue) {                // only if joystick horizontal movement detected
    Serial.println("X-" + String(nunchuk.analogX));   // send joystick X value
    prevXValue = nunchuk.analogX;
  }

  if (currentMillis > (t_tempo_received + 75))        // turn motor off after 75ms (experimental value)
    digitalWrite(motorPin, LOW);    
  else if (currentMillis > t_tempo_received)          // turn motor when signal received ( + sync delay)
    digitalWrite(motorPin, HIGH);
}

void serialEvent() {
  while (Serial.available()) {
    Serial.read();                              // not actually intrested in the received value
    digitalWrite(motorPin, LOW);                //to avoid it staying HIGH instead of pulsing
    t_tempo_received = millis() + audioSync;    // adding delay to sync with audio
  }
}
