datalogger file;

void beginLog(){
  file.beginSave();
  file.add("TIME,PPM,TEMP,RH%,GEN,FAN,UVC");
  logEnabled = true;
}

void endLog(){
  file.endSave( file.getIncrementalFilename( sketchPath("LOG" + java.io.File.separator + "log###.csv" )));
}
