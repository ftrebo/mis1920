/*
  MIS Project 2019/2020
  Domenico Stefani - Francesco Trebo
  --
  AUDIO Section
  Teensy code
 */

#include <string.h>
#include <IIRFilter.h>

#define STEPS 8                       // Number of steps of the step sequencer

/*Serial communication*/
const char START_MARKER = '[';
const char END_MARKER = ']';
const byte MAX_LENGTH_MESSAGE = 64;
const byte MAX_LED_INTENSITY = 20;         // [0-255]
/* Usage variables*/
bool new_message_received = false;         // Flag for serial receiver
unsigned long previous_micros = 0;          // microsecond counter
unsigned long current_micros = 0;  // microsecond counter
byte current_step = STEPS - 1;             // Current step (0,...,STEPS)
bool playing = false;                      // Sequence playing flag
char received_message[MAX_LENGTH_MESSAGE]; // Current received message
unsigned short step_time = 0;              // time interval in ms between steps
unsigned short lastsent_pot_vals[8]= {0};  // Last values sent to serial

/* Analog inputs -------------------------------------------------------------*/

#define ANALOG_PERIOD_MICROS 1000               //current_micros
const byte leds[8] = {2,3,4,5,6,7,8,9};         // Led pins
const byte pots[8] = {33,34,35,36,37,38,39,14}; // Potentiometers pins

uint16_t vpots[STEPS]= {0};
uint16_t vpots_filtered[STEPS]= {0};
uint16_t previous_vpots_filtered[STEPS]= {0};
/* 50 Hz Butterworth low-pass -------------------------------------------------*/
// 50 Hz Butterworth low-pass
double a_lp_50Hz[] = {1.000000000000, -3.180638548875, 3.861194348994,
                      -2.112155355111, 0.438265142262};
double b_lp_50Hz[] = {0.000416599204407, 0.001666396817626, 0.002499595226440,
                      0.001666396817626, 0.000416599204407};
IIRFilter lowpass[STEPS] = {IIRFilter(b_lp_50Hz, a_lp_50Hz),
                            IIRFilter(b_lp_50Hz, a_lp_50Hz),
                            IIRFilter(b_lp_50Hz, a_lp_50Hz),
                            IIRFilter(b_lp_50Hz, a_lp_50Hz),
                            IIRFilter(b_lp_50Hz, a_lp_50Hz),
                            IIRFilter(b_lp_50Hz, a_lp_50Hz),
                            IIRFilter(b_lp_50Hz, a_lp_50Hz),
                            IIRFilter(b_lp_50Hz, a_lp_50Hz)};

/* Threshold  ----------------------------------------------------------------*/
#define USE_THRESHOLDS
#ifdef USE_THRESHOLDS
  uint16_t vpots_threshold[STEPS] = {0};
#endif


void shiftLED(byte step){
//  Option 1.  Switch off all other leds
//  for(int i=0; i<STEPS; ++i)
//    analogWrite(leds[i],0);

//  Option 2.  Switch off only previous led
  byte prevstep = ((step - 1)==-1)?(STEPS-1):(step-1); //decrease 1 and go around at 0

  analogWrite(leds[prevstep],0);
  analogWrite(leds[step],MAX_LED_INTENSITY);
}


void receive_message() {
    static boolean reception_in_progress = false;
    static byte ndx = 0;
    char rcv_char;

    while (Serial.available() > 0 && new_message_received == false) {
        rcv_char = Serial.read();
        #ifdef VERBOSE_SERIAL
         Serial.println(rcv_char);
        #endif

        if (reception_in_progress == true) {
            if (rcv_char!= END_MARKER) {
                received_message[ndx] = rcv_char;
                ndx++;
                if (ndx >= MAX_LENGTH_MESSAGE) {
                    ndx = MAX_LENGTH_MESSAGE - 1;
                }
            }
            else {
                received_message[ndx] = '\0'; // terminate the string
                reception_in_progress = false;
                ndx = 0;
                new_message_received = true;
            }
        }
        else if (rcv_char == START_MARKER) {
            reception_in_progress = true;
        }
    }

    if (new_message_received) {
      handle_received_message(received_message);
      new_message_received = false;
    }
}

void handle_received_message(char *received_message) {
  char *all_tokens[2]; //NOTE: the message is composed by 2 tokens: command and value
  const char delimiters[5] = {START_MARKER, ',', ' ', END_MARKER,'\0'};
  int i = 0;

  all_tokens[i] = strtok(received_message, delimiters);

  while (i < 2 && all_tokens[i] != NULL) {
    all_tokens[++i] = strtok(NULL, delimiters);
  }
  char *command = all_tokens[0];
  char *value = all_tokens[1];

  if(strcmp(command,"step") == 0){
    sequence_iteration(atoi(value));
  }else if (strcmp(command,"play") == 0) {
    playing = true;
  }else if (strcmp(command,"stop") == 0) {
    playing = false;
  }

}

uint16_t mapval(uint16_t val){
  return val * (MAX_LED_INTENSITY/1024.0);
}

/**
 * This does the effect of having the light change when moving the pot
 */
void pot_light_effect(){
  for (size_t i = 0; i < STEPS; ++i) {
    if(vpots_filtered[i] != previous_vpots_filtered[i]){
      #ifdef VERBOSE_SERIAL
        Serial.print("Reading ");
        Serial.print(i);
        Serial.print(" ");
        Serial.print(vpots_filtered[i]);
        Serial.print(" prev ");
        Serial.println(previous_vpots_filtered[i]);
      #endif
      analogWrite(leds[i],(int)mapval(vpots_filtered[i]));
    }
  }
}

void init_pot_light_effect(){
  for (size_t i = 0; i < STEPS; ++i){
    previous_vpots_filtered[i] = vpots_filtered[i];
  }
}

void send_sensors(){
  for (size_t i = 0; i < STEPS; ++i){
    if(vpots_filtered[i] != previous_vpots_filtered[i]){
      previous_vpots_filtered[i] = vpots_filtered[i];
      Serial.print("a");
      Serial.print(i);
      Serial.print(", ");
      Serial.println(vpots_filtered[i]);
    }
  }
}

void setup() {
  Serial.begin(115200);
  for (size_t i = 0; i < STEPS; ++i)
    analogWrite(leds[i],0);
  Serial.println("Audio Section");
  Serial.println("Send tempo to play (eg. '[tempo,100]')");

  init_pot_light_effect();
  send_sensors();
}

void sequence_iteration(byte step){
  // change step and led
  shiftLED(step);
}

void loop() {
  receive_message();
  if(playing) {
    current_micros = micros();
    if ((current_micros - previous_micros) >= ANALOG_PERIOD_MICROS) {
     previous_micros = current_micros;
      /* Loop for the analog sensors ******************************************************************************/
      for (size_t i = 0; i < STEPS; ++i) {
        vpots[i] = analogRead(pots[i]);
        vpots_filtered[i] =  (uint16_t)lowpass[i].filter((double)vpots[i]);
      }

      #ifdef APPLY_THRESHOLDS
        for (size_t i = 0; i < STEPS; ++i)
          vpots_filtered[i] = (vpots_filtered[i] < vpots_threshold[i]) ? 0 : vpots_filtered;
      #endif

      //pot_light_effect();
      send_sensors();
    }
  }
}
