import com.yourinventit.processing.android.serial.*;

import android.content.Context;                // required imports for sensor data
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import java.util.Iterator;
import android.view.MotionEvent;

/* Accelerometer and touch screen based quadcopter controller.  Hacked
 from Jeff Thompson's (www.jeffreythompson.org) 'ball' example, a multi
 touch demo, and some other stuff too.
 
 First held touch (e.g. left thumb) will initialise throttle to zero, slide up for throttle up.
 
 Second held touch (e.g. right thumb) will initialise rudder to zero,
 slide left/right for left/right.  Second touch will also enable
 accelerometer for adjusting tilt, e.g. tilt forward to tilt copter
 forward.  The 'flat' position is the position the tablet was in when
 second touch is made.
 
 Communicates with copter by sending 5 bytes per frame over USB, first
 byte '23' (random fence number indicating start of packet), then
 throttle, rudder, aileron.
 
 A NOTE ON SPEED OF READING:
 The sensors can be read at three different rates, depending on need:
 1. SENSOR_DELAY_FASTEST
 2. SENSOR_DELAY_GAME
 3. SENSOR_DELAY_NORMAL
 
 
 */


SensorManager sensorManager;       // keep track of sensor
SensorListener sensorListener;     // special class for noting sensor changes
SensorData gyroData = new SensorData(), accelData = new SensorData();
PVector accelZero, initialThrottlePos, initialRudderPos, filteredData;
float angleXZ, angleYZ;                // ball coordinates
PFont font;

float throttle =0, aileron =0, rudder =0, elevator =0 ;

TouchProcessor touch;
ArrayList touchPoints;
Serial port;

void setup() {
  orientation(LANDSCAPE);                  // basic setup
  smooth();
  noStroke();

  font = createFont("SansSerif", 72);      // font setup
  textFont(font);
  textAlign(CENTER, CENTER);

  touch = new TouchProcessor();
  accelZero=new PVector(0, 0, 0);

  try {
    port = new Serial(this, Serial.list(this)[0], 115200);  // make sure Arduino is talking serial at this baud rate
    port.clear();            // flush buffer
    port.bufferUntil('\n');  // set buffer full flag on receipt of carriage return
  } 
  catch (IllegalStateException e) {
    port=null;
  }
}

int nLastPoints =0, lastDX=0;//, throttle, rudder; 
void handleTouch() {
  touch.analyse();
  touchPoints = touch.getPoints();
  if (nLastPoints == 0 && touchPoints.size() > 0) {
    accelZero = new PVector(angleXZ, angleYZ);
    TouchPoint point = (TouchPoint)touchPoints.get(0);
    initialThrottlePos = new PVector(point.x, point.y);
  } 
  else if (nLastPoints == 1 && touchPoints.size() > 1) {
    TouchPoint point = (TouchPoint)touchPoints.get(1);
    initialRudderPos = new PVector(point.x, point.y);
  } 
  if (nLastPoints == touchPoints.size() && touchPoints.size() >0) {
    TouchPoint point = (TouchPoint)touchPoints.get(0);
    int dx, dy;
    dx=(int)(point.x-initialThrottlePos.x);
    dy=(int)(point.y-initialThrottlePos.y);
    if (dx<0) dx=0;
    if (dy>0) dy=0;
    throttle=1-map(sqrt( dx*dx + dy*dy), 0, height*0.2, 0, 1);//(point.x-initialThrottlePos.x)*(point.x-initialThrottlePos.x) + (point.y-initialThrottlePos.y)*(point.y-initialThrottlePos.y));
  }
  if (nLastPoints == touchPoints.size() && touchPoints.size() >1) {
    TouchPoint point = (TouchPoint)touchPoints.get(1);
    int dx, dy;
    dx=(int)(point.x-initialRudderPos.x);
    dy=(int)(point.y-initialRudderPos.y);
    initialRudderPos.x = point.x;
    initialRudderPos.y = point.y;
    if (dx==0) dx=0;
    else dx=(int)(lastDX+dx)/2;
    lastDX = dx;
    //   if (dx<0) dx=0;
    //   if (dy>0) dy=0;
    rudder=map(dx, 0, height * 0.2, 0, 1);//(int)sqrt( dx*dx + dy*dy);//(point.x-initialThrottlePos.x)*(point.x-initialThrottlePos.x) + (point.y-initialThrottlePos.y)*(point.y-initialThrottlePos.y));
  }
  if (touchPoints.size()<2) {
    accelZero = new PVector(angleXZ, angleYZ);
    rudder=0;
  }
  if (touchPoints.size()<1) { 
    throttle=1;
  }
  nLastPoints=touchPoints.size();
}

float clamp(float in, float min, float max) {
  if (in < min) return min;
  if (in > max) return max;
  return in;
}

void handleSensors() {  
  if (accelData != null) {

    // display the reading - uses nf() to format the numbers so the # of decimal places
    // is managable and consistent
    if (filteredData==null) 
      filteredData=new PVector();
    PVector newData = accelData.consumeData();
    float tf=0.9;
    filteredData.x += (newData.x - filteredData.x) * tf;
    filteredData.y += (newData.y - filteredData.y) * tf;
    filteredData.z += (newData.z - filteredData.z) * tf;
    PVector nData = filteredData.get();
    
    nData.normalize(); 
    angleXZ = 180 * atan2(nData.x, nData.z) / PI;
    angleYZ = 180 * atan2(nData.y, nData.z) / PI;
    aileron = -map(angleXZ - accelZero.x, 0, 40, 0, 1);
    elevator = map(angleYZ - accelZero.y, 0, 50, 0, 1);
  } //trouble loading the data? let us know...
  else {
    text("[ no accelerometer data ]", width/2, height/2);
  }
}

void draw() {
  background(0, 255, 150);
  fill(0);
  // if we are able to get sensor data
  handleTouch();
  handleSensors();
  text("aileron - elevator: " + nf(aileron, 2, 3) + ", " + nf(elevator, 2, 3), width/2, height/2);
  text("throttle - rudder: " + nf(throttle, 2, 3) + ", " + nf(rudder, 2, 3), width/2, height/2+100);

  drawIndicator((int)(width*0.8), (int)(height*0.25), (int)(height*0.4), aileron, elevator);
  drawIndicator((int)(width*0.25), (int)(height*0.25), (int)(height*0.4), rudder, throttle);
  sendData();
}

void sendData() {
  if (port != null) {
    throttle = clamp(throttle, -1, 1);
    rudder = clamp(rudder, -1, 1);
    aileron = clamp(aileron, -1, 1);
    elevator = clamp(elevator, -1, 1);

    byte[] data= {
      23, 
      (byte) map(throttle, 1, -1, 0, 255), 
      (byte)map(rudder, 1, -1, 0, 255), 
      (byte)map(aileron, 1, -1, 0, 255), 
      (byte)map(elevator, 1, -1, 0, 255)
    };
    port.write(data);
  }
}

// range of posx and posy assumed to be -1 + 1
void drawIndicator(int x, int y, int size, float posx, float posy) {
  PVector pos=new PVector(posx, posy);
  pos.mult(size/2);
  fill(0);
  stroke(255);
  ellipse(x, y, size, size);
  noFill();
  ellipse(x, y, size*0.75, size*0.75);
  ellipse(x, y, size*0.5, size*0.5);
  ellipse(x, y, size*0.25, size*0.25);
  fill(204, 102, 0);
  ellipse(x+pos.x, y+pos.y, size/5, size/5);
}


// sensor reading code: start listening to the sensor on sketch start, stop
// listening on exit, and create a special class that extends the built-in
// SensorEventListener to read the sensor data into an array
void onResume() {
  super.onResume();
  sensorManager = (SensorManager)getSystemService(Context.SENSOR_SERVICE);
  sensorListener = new SensorListener();
  sensorManager.registerListener(sensorListener, sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_NORMAL);  // see top comments for speed options
  sensorManager.registerListener(sensorListener, sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE), SensorManager.SENSOR_DELAY_NORMAL);  // see top comments for speed options
}

void onPause() {
  sensorManager.unregisterListener(sensorListener);
  super.onPause();
}

// This is the stock Android touch event 
boolean surfaceTouchEvent(MotionEvent event) {

  // extract the action code & the pointer ID
  int action = event.getAction();
  int code   = action & MotionEvent.ACTION_MASK;
  int index  = action >> MotionEvent.ACTION_POINTER_ID_SHIFT;

  float x = event.getX(index);
  float y = event.getY(index);
  int id  = event.getPointerId(index);

  // pass the events to the TouchProcessor
  if ( code == MotionEvent.ACTION_DOWN || code == MotionEvent.ACTION_POINTER_DOWN) {
    touch.pointDown(x, y, id);
  }
  else if (code == MotionEvent.ACTION_UP || code == MotionEvent.ACTION_POINTER_UP) {
    touch.pointUp(event.getPointerId(index));
  }
  else if ( code == MotionEvent.ACTION_MOVE) {
    int numPointers = event.getPointerCount();
    for (int i=0; i < numPointers; i++) {
      id = event.getPointerId(i);
      x = event.getX(i);
      y = event.getY(i);
      touch.pointMoved(x, y, id);
    }
  } 

  return super.surfaceTouchEvent(event);
}

class SensorData extends PVector {
  public int readings =0; // How many readings we've accumulated for this sensor since averaging

  // return the average reading since last consuming data 
  public PVector consumeData() {
    if (readings==0) {
      return (PVector)this.get();//.get((PVector)this);
    }
    PVector result = PVector.div(this, readings);
    readings =0;
    return result;
  }

  // Update this sensors accumulated data with a new reading
  public void updateData(float [] values) {
    if (readings==0) {
      this.set(values);//add(new PVector(values[0], values[1], values[2]));
    } else {
      this.add(new PVector(values[0], values[1], values[2]));
    }
    this.readings++;
  }
}

class SensorListener implements SensorEventListener {
  void onSensorChanged(SensorEvent event) {
    if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
      accelData.updateData(event.values);
    } 
    else if (event.sensor.getType() == Sensor.TYPE_GYROSCOPE) {
      gyroData.updateData(event.values);
    }
  }

  void onAccuracyChanged(Sensor sensor, int accuracy) {
    // nothing here, but this method is required for the code to work...
  }
}

