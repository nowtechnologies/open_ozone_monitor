// OPEN OZONE SERIAL PROTOCOL JAVA IMPLEMENTATION

// packet ids
static final byte PID_SENSOR    = 1;
static final byte PID_LOG       = 2;
// header index
static final byte leadIndex     = 0;
static final byte headIndex     = 1;
static final byte lengthIndex   = 2;
static final byte packetIDindex = 3;
static final byte CRCIndex      = 4;
// data index
static final byte ozoneIndex    = 0;
static final byte tempIndex     = 4;
static final byte humidIndex    = 8;
static final byte ratioIndex    = 12;
static final byte statusIndex   = 16;

class UHR {
  public int firstLeadIn = 0;
  public int lastLeadIn = 0;
  public int packetLength = 0;
  public int packetID = 0;
  public int crc = 0;

  public final int sizeOf = 5;
  public final int IN_L = 0x55;
  public final int IN_H = 0xAA;

  public String toString() {
    return "L:[0x"+hex(firstLeadIn,2)+""+hex(lastLeadIn,2)+"], " + "ID:0x"+hex(packetID, 2)+", L:"+packetLength+", C:"+hex(crc, 2);
  }

  public UHR() {
    clear();
  }

  public void clear() {
    firstLeadIn = 0;
    lastLeadIn = 0;
    packetLength = 0;
    packetID = 0;
    crc = 0;
  }

  void set(int[] data) {
    firstLeadIn = data[leadIndex];
    lastLeadIn = data[headIndex];
    packetLength = data[lengthIndex];
    packetID = data[packetIDindex];
    crc = data[CRCIndex];
  }

  void set(byte[] data) {
    firstLeadIn = data[leadIndex];
    lastLeadIn = data[headIndex];
    packetLength = data[lengthIndex];
    packetID = data[packetIDindex];
    crc = data[CRCIndex];
  }
};

UHR header = new UHR();
RingBuffer buffer = new RingBuffer(256);
long shpCounter = 0;
boolean gotPacket = false;

public void serialEvent(Serial serialPort) {
  while (serialPort.available () > 0) {
    int p = serialPort.read();
    //print("0x" + hex(p,2) +"\t");

    if(buffer.push(p)) {
      int required = header.sizeOf + header.packetLength;
      while(buffer.size() >= required) {
        //println("BUFFER: " + buffer.size() + "/" + required);
        try {
          int[] pkt = buffer.get(0, header.sizeOf);
          header.set(pkt);
          //println("Header: " + header.toString());
          if(header.firstLeadIn == header.IN_L && header.lastLeadIn == header.IN_H) {
            int crc = crc8(pkt, 0, header.sizeOf - 1);
            //println("HEADER CRC: "+hex(crc, 4)+"<=>"+hex(header.crc, 4));
            if(crc == header.crc) {
              if(buffer.size() >= (header.sizeOf + header.packetLength)) {
                  buffer.popN(header.sizeOf);
                  int crcdata[] = buffer.get(header.packetLength - 2, 2);
                  int checksum = buffer.crc16(0, header.packetLength - 2);
                  int datacrc = getInt(crcdata, 0);
                  //println("DATA CRC: ("+datacrc+") => " + hex(datacrc, 8) + " / ("+checksum+") => " + hex(checksum, 8) + "");
                  if(datacrc == checksum) {
                    process(header, buffer);
                  } else {
                    println("DATA CHECKSUM MISMATCH");
                  }
                  buffer.popN(header.packetLength);
                  header.clear();
              } else {
                // need more bytes
                break;
              }
            } else {
              println("HEADER CRC ERROR");
              header.clear();
              buffer.pop();
            }
          } else {
            println("INVALID LEAD-IN");
            header.clear();
            buffer.pop();
          }
        } catch(Exception e) {
          /// ERROR
          println("RINGBUFFER UNDERFLOW");
          buffer.clear();
          break;
        } // try
      } // while
    } else {
      // buffer overflow
      println("RINGBUFFER OVERFLOW");
      buffer.clear();
    } // push
  } // serialPort.available
}

String packetContentString;
void printPacketContent(int[] data){
  packetContentString = "";
    print("(HEADER: " + header.toString() + ") DATA: [");
    for(int i=0; i<data.length - 2; i++) {
      if(i>0) {
        print(", ");
      }
      String hexS = "0x"+hex(data[i],2)+"\t";
      packetContentString=packetContentString+hexS;
      print(hexS);
    }
    println("]");
}

void process(UHR header, RingBuffer buffer) throws Exception {
  int[] data = buffer.get(0, header.packetLength);

  if (header.packetID == PID_SENSOR) {
    //printPacketContent(data);
    temperature = getFloat(data, tempIndex);
    humidity    = getFloat(data, humidIndex);
    ozonePPM    = getFloat(data, ozoneIndex);
    ratio       = getFloat(data, ratioIndex);
    if (logEnabled){
      file.add(hour()+":"+minute()+":"+second() +","+ ozonePPM +","+ temperature +","+ humidity + ",0,0,0");
    }
  } else
  if (header.packetID == PID_LOG) {
    temperature = getFloat(data, tempIndex);
    humidity    = getFloat(data, humidIndex);
    ozonePPM    = getFloat(data, ozoneIndex);
    ratio       = getFloat(data, ratioIndex);

    controllerStatus = data[statusIndex];
    statusBits = new boolean[8];
    for (int i = 7; i >= 0; i--) {
        statusBits[i] = (controllerStatus & (1 << i)) != 0;
    }

    if (logEnabled){
      file.add(
        hour()+":"+minute()+":"+second() +","+
        ozonePPM +","+ temperature +","+ humidity +","+
        int(statusBits[0]) +","+ int(statusBits[1]) +","+ int(statusBits[2])
      );
    }
  }
}
