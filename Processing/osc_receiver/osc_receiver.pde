import processing.serial.*;
import oscP5.*;
import netP5.*;


// Arduino Communication
Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port

// OSC Communication
OscP5 osc;

// Graphics Variables
int cols, rows;
int scale = 80;
int w = 2600;
int h = 1600;
float[][] terrain;
int meshFreedom = 20;
float flying = 0;

int level = 0;

void setup() {
  frameRate(15);
  size(1000, 600, P3D);
  myPort = new Serial(this, Serial.list()[0], 19200);
  osc = new OscP5(this, 8080);
  cols = w / scale;
  rows = h / scale;
  terrain = new float[cols][rows];
}

void draw() {
  if ( myPort.available() > 0) {
    val = myPort.readStringUntil('\n');
    println(val);
  }
  flying -= 0.1;
  float yoff = flying;
  for (int y = 0; y < rows; y++) {
    float xoff = 0;
    for (int x = 0; x < cols; x++) {
      terrain[x][y] = map(noise(xoff, yoff), 0, 1, -meshFreedom, meshFreedom);
      xoff += 0.2;
    }
    yoff += 0.2;
  }
  background(0);
  stroke(255);
  noFill();
  strokeWeight(1);  
  pushMatrix();
  translate(width/2, height/2);
  translate(-w/2, -h/2,-400);
  for (int y = 0; y < rows-1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      if (level == 0) fill(map(terrain[x][y],-80,80,0,80));
      else if (level < 15) fill(0,10,map(terrain[x][y],-80,80,0,255));
      else {
        float max = map(terrain[x][y],-80,80,0,255);
        fill(random(0,max),random(0,max),random(0,max));
      }
      vertex(x*scale, y*scale, terrain[x][y]);
      vertex(x*scale, (y+1)*scale, terrain[x][y+1]);
    }
    endShape();
  }
  popMatrix();
}

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/tempo")==true) {
    meshFreedom = int(map(theOscMessage.get(0).floatValue(), 70, 470, 20, 80));
  }
  print("Received OSC: "+theOscMessage.addrPattern()+" - ");
  if(theOscMessage.checkTypetag("s")) {
    println(theOscMessage.get(0).stringValue());
  } else if(theOscMessage.checkTypetag("f")) {
    println(theOscMessage.get(0).floatValue());
  } else if(theOscMessage.checkTypetag("i")) {
    println(theOscMessage.get(0).intValue());
  } 
}
