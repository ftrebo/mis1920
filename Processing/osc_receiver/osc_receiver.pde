import processing.serial.*;
import oscP5.*;
import netP5.*;

Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port
OscP5 osc;
NetAddress myRemoteLocation;

void setup() {
  String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 19200);
  osc = new OscP5(this, 8080);
}

void draw() {
  if ( myPort.available() > 0) {
    val = myPort.readStringUntil('\n');
    println(val);
  }
}

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.addrPattern() == "/frequency") {
    print(" SI ");
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
