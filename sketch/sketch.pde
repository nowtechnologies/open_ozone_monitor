import processing.serial.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;

Serial  serialPort;
String  portName = "usbmodem";
float   ozonePPM     = 0.0;
float   temperature  = 0.0;
float   humidity     = 0.0;
float   ratio        = 0.0;
boolean logEnabled   = false;
boolean[] statusBits = new boolean[8];
int     controllerStatus = 0;

float   lastO3Disp, lastTempDisp, lastHumiDisp, lastGenDisp, lastUVDisp;
String[] nameOfPeripherals = {"GEN","FAN","UVC","HMD","LCK","NA","NA","NA"};

void drawGrid(){
  stroke(50);
  for (int dx=0; dx<=width; dx+=10){
    line(dx,0,dx,height);
  }
  for (int dy=0; dy<=height; dy+=10){
    line(0,dy,width,dy);
  }
}

void logger(boolean on){
  if (on){
    beginLog();
  } else {
    endLog();
  }
}

void mousePressed(){
  if ( mouseX > width-100 &&
       mouseX < width &&
       mouseY > 10 &&
       mouseY < 90) {
         logEnabled = !logEnabled;
         logger(logEnabled);
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
  ellipseMode(CENTER);
  drawGrid();
  file = new datalogger();
}

int x = 1;

void draw() {

  fill(42); stroke(80);
  rect(0,0,width,100);
  textSize(20);
  fill(250,50,50);
  text("T="+temperature+" C", 10, 25);
  fill(50,250,50);
  text("H="+humidity+" %", 10, 55);
  fill(150,100,250);
  text("O="+nf(ozonePPM,0,2)+" ppm", 10, 85);
  // text("R="+ratio, 130, 25);

  stroke(128);
  if (logEnabled) fill(128); else fill(60);
  rect(width-110, 10, 100, 80);
  fill(255);
  text("LOG",width-80, 55);

  noStroke();
  for (int i=0; i<5; i++){
    if (statusBits[i]) fill(255); else fill(0);
    ellipse((i*50)+(3*width/8), 50, 20, 20);
    fill(255);
    textSize(12);
    text(nameOfPeripherals[i],(i*50)+(3*width/8)-13, 85);
  }

  float t = map(temperature, 0, 100, height, 100);
  stroke(250,50,50); line(x-1,lastTempDisp,x,t);
  lastTempDisp = t;

  float h = map(humidity,    0, 100, height, 100);
  stroke(50,250,50); line(x-1,lastHumiDisp,x,h);
  lastHumiDisp = h;

  float o = map(ozonePPM, 0, 1000, height, 100);
  stroke(150,100,250); line(x-1,lastO3Disp,x,o);
  lastO3Disp = o;

  float g = map(int(statusBits[0]), 0, 1, height, height/2);
  stroke(255); line(x-1,lastGenDisp,x,g);
  lastGenDisp = g;

  if (frameCount%10==0){
    x++;
    if (x>=width) {
      x=1;
      background(42);
      drawGrid();
    }
  }
}
