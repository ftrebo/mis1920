/********************************************************************************************************/
/* OSC Based Rolling Terrain Demo                                                                       */
/* Authors: Domenico Stefani, Francesco Trebo                                                           */
/********************************************************************************************************/

import processing.serial.*;
import oscP5.*;

/*---------------------------------------------------*/
/* Parameters                                        */
/*---------------------------------------------------*/
final float relative_bpm_tollerance = 0.1;

/*---------------------------------------------------*/
/* Graphic Parameters                                */
/*---------------------------------------------------*/
float w = 3000;  //Width of the terrain grid
float h = 1000;  //Height of the terrain grid
float scl = 20;  //Size of the small squares of the terrain grid (Default: 20)
float zscl = scl*8;  //Range of elevation on the z axis (Default: 10*scl)
int speed = 40;  //0-255; Terrain speed (Default: 50)
float granularity = 100;  //0-255; Terrain granularity (Default: 85) It changes the range of the input of the perlin noise algoritm resulting in a more dense or more flat surface
float growthLimit = 0.08; //0-1, It stops the growing of the mountains at a certan percentage of advancement

/*---------------*/
/* TerrainMode   */
/*---------------*/
int tmode = TerrainMode.COLOR_GRID_WHITE_STROKE;
/* Available:
 * TerrainMode.GRID
 * TerrainMode.REVERSE_GRID
 * TerrainMode.SHADOW_GRID_WHITE_STROKE
 * TerrainMode.SHADOW_GRID_BLACK_STROKE
 * TerrainMode.COLOR_GRID_WHITE_STROKE
 * TerrainMode.COLOR_GRID_BLACK_STROKE
 */

/*---------------*/
/* Sun Mode      */
/*---------------*/
boolean rotateSun = true;
int sunDetail = 50;
int smode = SunMode.COLOR_LIGHTS_BLACK_STROKE;
/* Available:
 * SunMode.GRID
 * SunMode.REVERSE_GRID
 * SunMode.COLOR_WHITE_STROKE
 * SunMode.COLOR_BLACK_STROKE
 * SunMode.COLOR_FLAT
 * SunMode.COLOR_LIGHTS
 * SunMode.COLOR_LIGHTS_WHITE_STROKE
 * SunMode.COLOR_LIGHTS_BLACK_STROKE
 */

/*Terrain Color*/
short colorGranularity = 1; //Differenciating factors
short red = 128;  //0-255
float rlight= 1;
short green = 128;  //0-255
float glight=0;
short blue = 128;  //0-255
float blight=1;
short blackPoint = 20;  //minimum value for rgb

/*Sun Color*/
color sunColor = #ffccee;



/*DO NOT CHANGE OR DELETE**************************************/
Serial serial;                                              /**/
OscP5 osc;                                                  /**/
int realMillis = millis();                                  /**/
int rows, cols;  //Number of rows and columns               /**/
float[][] elevation;                                        /**/
color[][] boxColor;                                         /**/
float flyingTerrain = 0;                                    /**/
float flyingColor= 0;                                       /**/
float offsetIncrement = 0;                                  /**/
float colorOffsetIncrement = 0;                             /**/
Star stars[];                                               /**/
int bpm = 200;                                              /**/
int bpm_multiplier = 1;                                     /**/
float starspeed_multiplier = 1;                             /**/
int user_bpm = 0;                                           /**/
int asseY = 122;                                            /**/
/**************************************************************/

void setup() {
  frameRate(50);
  size(600, 600, P3D);
  //fullScreen(P3D);
  rows = (int)(h/scl);
  cols = (int)(w/scl);
  elevation = new float[cols][rows];
  boxColor = new color[cols][rows];
  offsetIncrement = map(granularity, 0, 255, 0.05, 0.5);
  colorOffsetIncrement = map(colorGranularity, 0, 255, 0, 1);
  stars = new Star[100];
  for (int i=0; i < stars.length; i++) {
    stars[i] = new Star();
  }
  
  serial = new Serial(this, Serial.list()[0], 19200);
  serial.bufferUntil('\n');
  osc = new OscP5(this, 8080);
}

void draw() {
  float wait = 3750 * bpm_multiplier / bpm;
  
  background(0);
  space_init(PI/2.5);

  if (millis() > realMillis + wait) {
    realMillis = millis();
    elevation_init();
  }
  
  if (Level.drawStars()) draw_stars();
  if (Level.drawSun()) draw_sun();
  draw_terrain();
  
}

boolean isBpmGood(int bpm, int user_bpm) {
  float tollerance = bpm * relative_bpm_tollerance;
  if (abs(bpm*2 - user_bpm) < tollerance*2) return true;
  if (abs(bpm - user_bpm) < tollerance) return true;
  if (abs(bpm/2 - user_bpm) < tollerance/2) return true;
  if (abs(bpm/4 - user_bpm) < tollerance/4) return true;
  if (abs(bpm/8 - user_bpm) < tollerance/8) return true;
  return false;
}

void elevation_init() {
  flyingTerrain -= map(speed, 0, 255, 0, offsetIncrement);
  flyingColor -= map(speed, 0, 255, 0, colorOffsetIncrement);
  float yoff = flyingTerrain;
  float yCoff = flyingColor;
  for (int y=0; y < rows; y++) {
    float xoff = 0;
    float xCoff = 0;
    for (int x=0; x < cols; x++) {
      float maxvalue = +zscl/2;
      if (yoff < (offsetIncrement*rows*growthLimit)+flyingTerrain)
        maxvalue *= map(yoff, flyingTerrain, flyingTerrain+(offsetIncrement*rows), 0, 1);
      elevation[x][y] = map(noise(xoff, yoff), 0, 1, -maxvalue, maxvalue);
      if (tmode == TerrainMode.SHADOW_GRID_BLACK_STROKE || tmode == TerrainMode.SHADOW_GRID_WHITE_STROKE)
        boxColor[x][y] = color(((noise(xCoff, yCoff))*255));
      else if (tmode == TerrainMode.COLOR_GRID_BLACK_STROKE || tmode == TerrainMode.COLOR_GRID_WHITE_STROKE)
        boxColor[x][y] = color((((noise(xCoff, yCoff)*100*red)%(255-blackPoint))+blackPoint)*Level.colorIntensity()*rlight, 
          (((noise(xCoff, yCoff)*100*green)%(255-blackPoint))+blackPoint)*Level.colorIntensity()*glight, 
          (((noise(xCoff, yCoff)*100*blue)%(255-blackPoint))+blackPoint)*Level.colorIntensity()*blight);

      xoff += offsetIncrement;
      xCoff += colorOffsetIncrement;
    }
    yoff += offsetIncrement;
    yCoff += colorOffsetIncrement;
  }
}

void space_init(float angle) {
  translate(width/2, height/2);
  rotateX(angle);
  translate(-w/2, -h/2);
}

void draw_terrain() {
  switch(tmode) {
  case TerrainMode.GRID:
    fill(0);
    stroke(255);
    break;
  case TerrainMode.REVERSE_GRID:
    fill(255);
    stroke(0);
    break;
  case TerrainMode.SHADOW_GRID_WHITE_STROKE:
  case TerrainMode.COLOR_GRID_WHITE_STROKE:
    noFill();
    stroke(255);
    break;
  case TerrainMode.SHADOW_GRID_BLACK_STROKE:
  case TerrainMode.COLOR_GRID_BLACK_STROKE:
    noFill();
    stroke(0);
    break;
  }

  for (int y=0; y < rows-1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x=0; x < cols; x+=2) {
      if (tmode!=TerrainMode.GRID && tmode!=TerrainMode.REVERSE_GRID)
        fill(boxColor[x][y]);
      vertex(x*scl, y*scl, elevation[x][y] );
      vertex(x*scl, (y+1)*scl, elevation[x][y+1] );
    }
    endShape();
  }
}
void draw_sun() {
  pushMatrix();
  switch(smode) {
  case SunMode.GRID:
    noFill();
    stroke(255);
    break;
  case SunMode.REVERSE_GRID:
    fill(255);
    stroke(0);
    break;
  case SunMode.COLOR_WHITE_STROKE:
    fill(sunColor);
    stroke(255);
    break;
  case SunMode.COLOR_BLACK_STROKE:
    fill(sunColor);
    stroke(0);
    break;
  case SunMode.COLOR_LIGHTS:
    lights();
  case SunMode.COLOR_FLAT:
    fill(sunColor);
    noStroke();
    break;
  case SunMode.COLOR_LIGHTS_WHITE_STROKE:
    lights();
    fill(sunColor);
    stroke(255);
    break;
  case SunMode.COLOR_LIGHTS_BLACK_STROKE:
    lights();
    fill(sunColor);
    stroke(0);
    break;
  }
  translate(w/2, -h/5, 0);
  if (rotateSun)
    rotateY(radians(frameCount*map(speed, 0, 255, 0.01, 3)));
  sphereDetail(sunDetail);
  sphere(300);
  popMatrix();
}

void draw_stars() {
  for (int i=0; i < stars.length; i++) {    
    stars[i].update(starspeed_multiplier);
    stars[i].show();
  }
}

static abstract class TerrainMode {
  static final int GRID = 0;
  static final int REVERSE_GRID = 1;
  static final int SHADOW_GRID_WHITE_STROKE = 2;
  static final int SHADOW_GRID_BLACK_STROKE = 3;
  static final int COLOR_GRID_WHITE_STROKE = 4;
  static final int COLOR_GRID_BLACK_STROKE = 5;
}

static abstract class SunMode {
  static final int GRID = 0;
  static final int REVERSE_GRID = 1;
  static final int COLOR_WHITE_STROKE = 2;
  static final int COLOR_BLACK_STROKE = 3;
  static final int COLOR_FLAT = 4;
  static final int COLOR_LIGHTS = 5;
  static final int COLOR_LIGHTS_WHITE_STROKE = 6;
  static final int COLOR_LIGHTS_BLACK_STROKE = 7;
}

String serialIn, command; 
int param;
void serialEvent(Serial serial) {
  serialIn = serial.readStringUntil('\n');
  if (serialIn != null) {
    try {
      command = serialIn.substring(0, 2);
      param = int(serialIn.substring(2, serialIn.indexOf("\n")-1));
      if (command.equals("Y-")) bpm_multiplier = int(map(param, 0, 255, 5, 1));
      if (command.equals("X-")) starspeed_multiplier = map(param, 0, 255, 0.3, 4);
      if (command.equals("T-")) {
        if (isBpmGood(bpm, param) == true) Level.hit();
        else { 
          if (param == 0) Level.miss(5);
          else Level.miss(); 
        }
      }
    } 
    catch (Exception e) {
      println("-- Serial error --");
    }
  }
}

int tempoCounter = 0;
int tempoDiv = 1;
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/tempo")==true) {
    bpm = int(oscReceive(theOscMessage));
    tempoDiv = (bpm > 240) ? 2 : 1;
    tempoCounter += 1;
    if (tempoCounter >= tempoDiv) {
      tempoCounter = 0;
      serial.write("T");
    }
    
  } else if (theOscMessage.checkAddrPattern("/Yaxis")==true) {
    rlight = oscReceive(theOscMessage);
  } else if (theOscMessage.checkAddrPattern("/Xaxis")==true) {
    blight = oscReceive(theOscMessage);
  } else if (theOscMessage.checkAddrPattern("/filter")==true) {
    zscl = map(oscReceive(theOscMessage), 0, 1, 50, 200);
  }   
  //println("Received OSC: "+theOscMessage.addrPattern()+" - ");
}

float oscReceive(OscMessage oscMessage) {
  if (oscMessage.checkTypetag("i"))
    return (float)oscMessage.get(0).intValue();
  return oscMessage.get(0).floatValue();
}
