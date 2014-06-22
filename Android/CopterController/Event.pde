// Event classes
///////////////////////////////////////////////////////////////////////////////////
class TouchEvent {
  // empty base class to make event handling easier
}

///////////////////////////////////////////////////////////////////////////////////
class DragEvent extends TouchEvent {

  float x; // position
  float y;
  float dx; // movement 
  float dy; 
  int numberOfPoints;

  DragEvent(float x, float y, float dx, float dy, int n) {
    this.x = x;
    this.y = y;
    this.dx = dx;
    this.dy = dy;
    numberOfPoints = n;
  }
}

///////////////////////////////////////////////////////////////////////////////////
class PinchEvent extends TouchEvent {

  float centerX;
  float centerY;
  float amount; // in pixels
  int numberOfPoints;

  PinchEvent(float centerX, float centerY, float amount, int n) {
    this.centerX = centerX;
    this.centerY = centerY;  
    this.amount = amount;
  }
}

///////////////////////////////////////////////////////////////////////////////////
class RotateEvent extends TouchEvent {  

  float centerX;
  float centerY;
  float angle; // delta, in radians
  int numberOfPoints;

  RotateEvent(float centerX, float centerY, float angle, int n) {
    this.centerX = centerX;
    this.centerY = centerY;  
    this.angle = angle;
  }
}


///////////////////////////////////////////////////////////////////////////////////
class TapEvent extends TouchEvent {

  public static final int SINGLE = 0;
  public static final int DOUBLE = 1;

  float x;
  float y;
  int type;

  TapEvent(float x, float y, int type) {
    this.x = x;
    this.y = y;
    this.type = type;
  }  

  boolean isSingleTap() {
    return (type == SINGLE) ? true : false;
  }

  boolean isDoubleTap() {
    return (type == DOUBLE) ? true : false;
  }
}

///////////////////////////////////////////////////////////////////////////////////
class FlickEvent extends TouchEvent { 

  float x;
  float y;
  PVector velocity;

  FlickEvent(float x, float y, PVector velocity) {
    this.x = x; 
    this.y = y;
    this.velocity = velocity;
  }
}


