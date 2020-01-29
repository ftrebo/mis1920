/********************************************************************************************************/
/* Rolling Terrain Demo                                                                                 */
/* Author: Domenico Stefani                                                                             */
/* Inspired by: Coding Challenge #11: 3D Terrain Generation with Perlin Noise in Processing             */
/* https://www.youtube.com/watch?v=IKB1hWWedMk                                                          */
/********************************************************************************************************/

/*---------------------------------------------------*/
/* Parameters                                        */
/*---------------------------------------------------*/
float w = 2000;  //Width of the terrain grid
float h = 1600;  //Height of the terrain grid
float scl = 10;  //Size of the small squares of the terrain grid (Default: 20)
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
short colorGranularity = 1;
//Differenciating factors
short red = 50;  //0-255
short green = 1;  //0-255
short blue = 2;  //0-255
short blackPoint = 20;  //minimum value for rgb
float light = 0.9;  //0-1; 1 means that that each rgb value can reach maximum saturation

/*Sun Color*/
color sunColor = #ffccee;



/*DO NOT CHANGE OR DELETE**************************************/
int realMillis = millis();                                  /**/
int rows,cols;   //Number of rows and columns               /**/
float[][] elevation;                                        /**/
color[][] boxColor;                                         /**/
float flyingTerrain = 0;                                    /**/
float flyingColor= 0;                                       /**/
float offsetIncrement = 0;                                  /**/
float colorOffsetIncrement = 0;                             /**/
/**************************************************************/

void setup(){
  frameRate(24);
  size(600,600,P3D);
  rows = (int)(h/scl);
  cols = (int)(w/scl);
  elevation = new float[cols][rows];
  boxColor = new color[cols][rows];
  offsetIncrement = map(granularity,0,255,0.05,0.5);
  colorOffsetIncrement = map(colorGranularity,0,255,0,1);
}

boolean flag = false;
void draw(){

  //if(millis() > realMillis + 5000){
  //  flag = false;
  //  realMillis = millis();
  //  tmode = (tmode+1)%6;
  //  speed = 0;
  //}
  //if(millis() > realMillis + 5000 && flag == false){
  //  smode = (smode+1)%8;
  //  flag = true;
  //  speed = 40;
  //}

  background(0);
  elevation_init();
  space_init(PI/2.5);
  //draw_stars();
  draw_terrain();
  draw_sun();
}



void elevation_init(){
  flyingTerrain -= map(speed,0,255,0,offsetIncrement);
  flyingColor -= map(speed,0,255,0,colorOffsetIncrement);
  float yoff = flyingTerrain;
  float yCoff = flyingColor;
  for(int y=0; y < rows; y++){
    float xoff = 0;
    float xCoff = 0;
    for(int x=0; x < cols; x++){
      float maxvalue = +zscl/2;
      if(yoff < (offsetIncrement*rows*growthLimit)+flyingTerrain)
        maxvalue *= map(yoff,flyingTerrain,flyingTerrain+(offsetIncrement*rows),0,1);
      elevation[x][y] = map(noise(xoff,yoff),0,1,-maxvalue,maxvalue);
      if(tmode == TerrainMode.SHADOW_GRID_BLACK_STROKE || tmode == TerrainMode.SHADOW_GRID_WHITE_STROKE)
        boxColor[x][y] = color(((noise(xCoff,yCoff))*255));
      else if(tmode == TerrainMode.COLOR_GRID_BLACK_STROKE || tmode == TerrainMode.COLOR_GRID_WHITE_STROKE)
        boxColor[x][y] = color(((noise(xCoff,yCoff)*100*red)%(255-blackPoint))+blackPoint*light,
                              ((noise(xCoff,yCoff)*100*green)%(255-blackPoint))+blackPoint*light,
                              ((noise(xCoff,yCoff)*100*blue)%(255-blackPoint))+blackPoint*light);

      xoff += offsetIncrement;
      xCoff += colorOffsetIncrement;
    }
    yoff += offsetIncrement;
    yCoff += colorOffsetIncrement;
  }
}

void space_init(float angle){

  translate(width/2,height/2);
  rotateX(angle);
  translate(-w/2,-h/2);
}

void draw_terrain(){

  switch(tmode){
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

  for(int y=0; y < rows-1; y++){
    beginShape(TRIANGLE_STRIP);
    for(int x=0; x < cols; x+=2){
      if(tmode!=TerrainMode.GRID && tmode!=TerrainMode.REVERSE_GRID)
        fill(boxColor[x][y]);
      vertex(x*scl,y*scl, elevation[x][y] );
      vertex(x*scl,(y+1)*scl, elevation[x][y+1] );
    }
    endShape();
  }
}
void draw_sun(){

  switch(smode){
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

  //stroke(0);
  //  lights();
  //  noStroke();
  //fill(#ffcc00);
  translate(w/2, -h/5, 0);
  if(rotateSun)
    rotateY(radians(frameCount*map(speed,0,255,0.01,3)));
  sphereDetail(sunDetail);
  sphere(300);
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

//void draw_stars(){
//  pushMatrix();
//  translate(w/4, -h/8, 0);
//  fill(255);
//  stroke(255);
//  sphereDetail(100);
//  sphere(100);
//  popMatrix();
//}
