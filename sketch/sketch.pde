import processing.serial.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;

Serial  serialPort;
String  portName = "ACM0";
float   ozonePPM     = 0.0;
float   temperature  = 0.0;
float   humidity     = 0.0;
float   ratio        = 0.0;
boolean logEnabled   = false;
boolean[] statusBits = new boolean[8];
int     controllerStatus = 0;
float   lastO3Disp, lastTempDisp, lastHumiDisp;

void drawGrid(){
  stroke(50);
  for (int dx=0; dx<=width; dx+=10){
    line(dx,0,dx,height);
  }
  for (int dy=0; dy<=height; dy+=10){
    line(0,dy,width,dy);
  }
}

void keyPressed(){
  if (key == 'l') {
    logEnabled = !logEnabled;
    println("Log: "+logEnabled);
    if (logEnabled){
      beginLog();
    }
    else {
      endLog();
    }
  }
}

void setup() {
  size(800, 600);

  boolean portFound = false;
  for (int i=0; i<Serial.list().length; i++){
    if (Serial.list()[i].indexOf(portName) >= 0) {
      try {
        serialPort = new Serial(this, Serial.list()[i], 9600);
        serialPort.clear();
        portFound = true;
        break;
      } catch (RuntimeException e) {
        println(e);
      }
    } else {
      portFound = false;
    }
  }

  if (!portFound){
    println("Can't find port:" + portName);
    exit();
  }

  background(42);
  drawGrid();
  file = new datalogger();
}

int x = 1;

void draw() {

  fill(42); stroke(50);
  rect(0,0,140,100);
  fill(255);
  text("T="+temperature+" C", 10, 20);
  text("H="+humidity+" %", 10, 40);
  text("O="+ozonePPM+" ppm", 10, 60);
  text("R="+ratio, 10, 80);

  float t = map(temperature, 0, 100, height, 0);
  stroke(250,50,50); line(x-1,lastTempDisp,x,t);
  lastTempDisp = t;

  float h = map(humidity,    0, 100, height, 0);
  stroke(50,250,50); line(x-1,lastHumiDisp,x,h);
  lastHumiDisp = h;

  float o = map(ozonePPM, 0, 1000, height, 0);
  stroke(50,50,250); line(x-1,lastO3Disp,x,o);
  lastO3Disp = o;

  if (frameCount%10==0){
    x++;
    if (x>=width) {
      x=1;
      background(42);
      drawGrid();
    }
  }
}
