# ArduinoQuad

Arduino and Android source code for use with the A1705 chip with an Arduino board.  Control the Hubsan X4 Quad 
with an Android device using the A7105 module as opposed to Bluetooth, Wifi, or other communication method.

## License

The MIT License (MIT)

Copyright (c) 2014 Ankur K. Jain

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Steps

Put together Arduino with A1705

Program Arduino

Program Android 

Build/Buy Quadcopter

Fly
       
### Supplies Needed

Arduino Due

Android Device

A1705 Transceiver Module

Hubsan X4 Quad (or spare parts to build your own w/o controller)

OTG Cable

### Build the Board w/ A1705

1: Identify the 6 pins on your A1705 board that we need, on the
following diagram these are:
  Left hand side:  GND
  Right hand side: SDIO, SCK, SCS, GND, VCC

2: Solder 2 cm lengths of solid core wire too each of these pins.
Once soldered on I pull the insulation off the wires giving me six
legs that I can press into a breadboard.

3: Insert A7105 board into breadboard with the left hand pin on one
side of the central channel, and the right hand pins on the other
side.

4: Attach the 'ground' of your Due to the 'ground' (black) rail on
your breadboard.

5: Attach the '3.3v' of your Due to the 'live' (red) rail on your
breadboard.

6: Wire jumper wires from your live rail to the 'VDD' pin of your a7105

7: Wire 2 jumper wires from your ground rail to the TWO 'GND' pins of
your a7105.

8: Wire the MOSI pin of your Due's SPI header to one end of the
resistor.  See
http://21stdigitalhome.blogspot.co.uk/2013/02/arduino-due-hardware-spi.html
for a diagram of where MOSI is.

9: Wire the other end of your resister to the 'SDIO' pin of the A7105

10: Put an additional wire from the 'SDIO' pin of the A7105 to the
'MISO' pin of the due.

11: Wire 'SCK' on the Due to 'SCK' on the A7105

12: Wire pin 10 on the Due to 'SCS' on the A7105


###To fly 

Power on Quadcopter

Connect Arduino to Android Device via OTG cable, and open application on Android device when prompted

When the lights stop blinking on the quad, it is bound to the a1705 module

Fly
        