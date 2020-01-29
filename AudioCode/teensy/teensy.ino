/*
  MIS Project 2019/2020
  Domenico Stefani - Francesco Trebo
  --
  AUDIO Section
  Teensy code
 */

#include <string.h>
#include <IIRFilter.h>

/* FILTER functioning --------------------------------------------------------*/
// #define USE_THRESHOLDS_STEP_POTS.
#define FILTER_STEP_POTS
#define FILTER_TOP_POTS
#define FILTER_AXIS
#define FILTER_RIBBON

/* VERBOSE Definitions (Activate for debug only) -----------------------------*/
// #define VERBOSE_SERIAL

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
/*- Step related controls -*/
const byte leds[8] = {2,3,4,5,6,7,8,9};         // Led pins
const byte pots[8] = {A14,A15,A16,A17,A18,A19,A20,A21}; // Step-potentiometers pins
/*- Other controls -*/
const byte toppot_1 = A0;
const byte toppot_2 = A1;
const byte vert_axis = A12;
const byte hor_axis = A13;
const byte ribbon = A2;
#define RIBBON_THRESHOLD 60 //under 40 the ribbon is unpressed
// Value variables
uint16_t vpots[STEPS]= {0};
uint16_t vpots_filtered[STEPS]= {0};
uint16_t previous_vpots_filtered[STEPS]= {0};
uint16_t vtoppot_1 = 0;
uint16_t vtoppot_1_filtered = 0;
uint16_t previous_vtoppot_1_filtered = 0;
uint16_t vtoppot_2 = 0;
uint16_t vtoppot_2_filtered = 0;
uint16_t previous_vtoppot_2_filtered = 0;
uint16_t vhor_axis = 0;
uint16_t vhor_axis_filtered = 0;
uint16_t previous_vhor_axis_filtered = 0;
uint16_t vvert_axis = 0;
uint16_t vvert_axis_filtered = 0;
uint16_t previous_vvert_axis_filtered = 0;
uint16_t vribbon = 0;
uint16_t vribbon_filtered = 0;
uint16_t previous_vribbon_filtered = 0;

/* Digital inputs -------------------------------------------------------------*/

const byte pause_but = 29;  // pins for digital inputs
const byte play_but = 30;
int vpause_but = 0;        // value (or state) of digital inputs
int vplay_but = 0;

int pause_but_last_button_state = HIGH;
int play_but_last_button_state = HIGH;
int pause_but_button_state = HIGH;
int play_but_button_state = HIGH;
unsigned long pause_but_last_debounce_time = 0;
unsigned long play_but_last_debounce_time = 0;

unsigned long debounce_delay = 50; // increase if the output flickers

/* 50 Hz Butterworth low-pass ----------------------------------------------*/
// 50 Hz Butterworth low-pass
const double a_lp_50Hz[] = {1.000000000000, -3.180638548875, 3.861194348994,
                            -2.112155355111, 0.438265142262};
const double b_lp_50Hz[] = {0.000416599204407, 0.001666396817626,
                            0.002499595226440, 0.001666396817626,
                            0.000416599204407};

#ifdef FILTER_STEP_POTS
  IIRFilter lowpass_pots[STEPS] = {IIRFilter(b_lp_50Hz, a_lp_50Hz),
                                   IIRFilter(b_lp_50Hz, a_lp_50Hz),
                                   IIRFilter(b_lp_50Hz, a_lp_50Hz),
                                   IIRFilter(b_lp_50Hz, a_lp_50Hz),
                                   IIRFilter(b_lp_50Hz, a_lp_50Hz),
                                   IIRFilter(b_lp_50Hz, a_lp_50Hz),
                                   IIRFilter(b_lp_50Hz, a_lp_50Hz),
                                   IIRFilter(b_lp_50Hz, a_lp_50Hz)};
#endif
#ifdef FILTER_TOP_POTS
  IIRFilter lowpass_toppot_1 = IIRFilter(b_lp_50Hz, a_lp_50Hz);
  IIRFilter lowpass_toppot_2 = IIRFilter(b_lp_50Hz, a_lp_50Hz);
#endif
#ifdef FILTER_AXIS
  IIRFilter lowpass_hor_axis = IIRFilter(b_lp_50Hz, a_lp_50Hz);
  IIRFilter lowpass_vert_axis = IIRFilter(b_lp_50Hz, a_lp_50Hz);
#endif
#ifdef FILTER_RIBBON
  IIRFilter lowpass_ribbon = IIRFilter(b_lp_50Hz, a_lp_50Hz);
#endif
/* Threshold  ----------------------------------------------------------------*/
#ifdef USE_THRESHOLDS_STEP_POTS
  uint16_t vpots_threshold[STEPS] = {0};
#endif


void shiftLED(byte step){
//  Option 1.  Switch off all other leds
//  for(int i=0; i<STEPS; ++i)
//    analogWrite(leds[i],0);

//  Option 2.  Switch off only previous led
  byte prevstep = ((step - 1)==-1)?(STEPS-1):(step-1); //-1 and loop when at 0

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
  char *all_tokens[2]; // the message is composed by 2 tokens: command and value
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
    for (size_t i = 0; i < STEPS; ++i)
      analogWrite(leds[i],0);
    analogWrite(leds[current_step],MAX_LED_INTENSITY);
  }

}

uint16_t mapval(uint16_t val){
  return val * (MAX_LED_INTENSITY/1024.0);
}


bool loose_equality(uint16_t v1,uint16_t v2, uint16_t maxerror = 4){
  if ((v1 >= (v2-maxerror)) && (v1 <= (v2+maxerror)))
    return true;
  return false;
}

/**
 * This does the effect of having the light change when moving the pot
 */
void pot_light_effect(){
  for (size_t i = 0; i < STEPS; ++i){
    if(!loose_equality(vpots_filtered[i],previous_vpots_filtered[i])){
//        #ifdef VERBOSE_SERIAL
//          Serial.print("Reading ");
//          Serial.print(i);
//          Serial.print(" ");
//          Serial.print(vpots_filtered[i]);
//          Serial.print(" prev ");
//          Serial.println(previous_vpots_filtered[i]);
//        #endif
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
    if(!loose_equality(vpots_filtered[i],previous_vpots_filtered[i])){
      previous_vpots_filtered[i] = vpots_filtered[i];
      Serial.print("a");
      Serial.print(i);
      Serial.print(", ");
      Serial.println(vpots_filtered[i]);
    }
  }

  if(!loose_equality(vtoppot_1_filtered,previous_vtoppot_1_filtered)){
    previous_vtoppot_1_filtered = vtoppot_1_filtered;
    Serial.print("t1, ");
    Serial.println(vtoppot_1_filtered);
  }
  if(!loose_equality(vtoppot_2_filtered,previous_vtoppot_2_filtered)){
    previous_vtoppot_2_filtered = vtoppot_2_filtered;
    Serial.print("t2, ");
    Serial.println(vtoppot_2_filtered);
  }
  if(!loose_equality(vhor_axis_filtered,previous_vhor_axis_filtered)){
    previous_vhor_axis_filtered = vhor_axis_filtered;
    Serial.print("ha, ");
    Serial.println(vhor_axis_filtered);
  }
  if(!loose_equality(vvert_axis_filtered,previous_vvert_axis_filtered)){
    previous_vvert_axis_filtered = vvert_axis_filtered;
    Serial.print("va, ");
    Serial.println(vvert_axis_filtered);
  }
  if((!loose_equality(vribbon_filtered,previous_vribbon_filtered)) &&
     (vribbon_filtered > RIBBON_THRESHOLD)){
    Serial.print("rb, ");
    Serial.println(previous_vribbon_filtered);
    previous_vribbon_filtered = vribbon_filtered;
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(pause_but, INPUT_PULLUP);
  pinMode(play_but, INPUT_PULLUP);

  for (size_t i = 0; i < STEPS; ++i)
    analogWrite(leds[i],0);

  init_pot_light_effect();
  send_sensors();
  playing = false;
}

void sequence_iteration(byte step){
  current_step = step;
  // change step and led
  shiftLED(step);
}

void loop() {
  receive_message();

  
  /* Handle Play button (play_but)********************************/
  vplay_but = digitalRead(play_but);
  if (vplay_but != play_but_last_button_state){
    play_but_last_debounce_time = millis(); // reset the debouncing timer
  }
  if ((millis() - play_but_last_debounce_time) > debounce_delay) {
    // if the button state has changed, toggle
    if (vplay_but != play_but_button_state){
      play_but_button_state = vplay_but;

      Serial.print("play, ");
      Serial.println(!play_but_button_state); //pullup, send negation
      if(play_but_button_state == LOW) //if pressed, play (Pullup)
        playing = true;
    }
  }
  play_but_last_button_state = vplay_but;



  /* Handle Pause button (pause_but)********************************/
  vpause_but = digitalRead(pause_but);
  if (vpause_but != pause_but_last_button_state){
    pause_but_last_debounce_time = millis(); // reset the debouncing timer
  }
  if ((millis() - pause_but_last_debounce_time) > debounce_delay) {
    // if the button state has changed, toggle
    if (vpause_but != pause_but_button_state){
      pause_but_button_state = vpause_but;

      // Send button status
      Serial.print("pause, ");
      Serial.println(!pause_but_button_state); //pullup, send negation
      if (pause_but_button_state == LOW) //if pressed, stop (pullup config)
        playing = false;
    }
  }
  pause_but_last_button_state = vpause_but;


  if(playing) {
    current_micros = micros();
    if ((current_micros - previous_micros) >= ANALOG_PERIOD_MICROS) {
     previous_micros = current_micros;
      /* READ NOTE POTENTIOMETERS -------------------------------------------*/
      for (size_t i = 0; i < STEPS; ++i) {
        vpots[i] = analogRead(pots[i]);
        #ifdef FILTER_STEP_POTS
          vpots_filtered[i] =  (uint16_t)lowpass_pots[i].filter((double)vpots[i]);
        #else
          vpots_filtered[i] =  vpots[i];
        #endif
      }

      vtoppot_1  = analogRead(toppot_1);
      vtoppot_2  = analogRead(toppot_2);
      vhor_axis  = analogRead(hor_axis);
      vvert_axis = analogRead(vert_axis);
      vribbon    = analogRead(ribbon);
      #ifdef FILTER_TOP_POTS
        vtoppot_1_filtered = (uint16_t)lowpass_toppot_1.filter((double)vtoppot_1);
        vtoppot_2_filtered = (uint16_t)lowpass_toppot_2.filter((double)vtoppot_2);
      #else
        vtoppot_1_filtered = vtoppot_1;
        vtoppot_2_filtered = vtoppot_2;
      #endif
      #ifdef FILTER_AXIS
        vhor_axis_filtered = (uint16_t)lowpass_hor_axis.filter((double)vhor_axis);
        vvert_axis_filtered = (uint16_t)lowpass_vert_axis.filter((double)vvert_axis);
      #else
        vhor_axis_filtered = vhor_axis;
        vvert_axis_filtered = vvert_axis;
      #endif
      #ifdef FILTER_RIBBON
        vribbon_filtered   = (uint16_t)lowpass_ribbon.filter((double)vribbon);
      #else
        vribbon_filtered   = vribbon;
      #endif

      #ifdef APPLY_THRESHOLDS
        for (size_t i = 0; i < STEPS; ++i)
          vpots_filtered[i] = (vpots_filtered[i] < vpots_threshold[i]) ? 0 : vpots_filtered;
      #endif

      pot_light_effect();
      send_sensors();
    }
  }
}
