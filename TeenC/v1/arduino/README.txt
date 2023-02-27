Copy the folder "Teensy" to Sketchbook location in Arduino IDE. The location is usually "C:\Users\[UserName]\Documents\Arduino\Library".
For information on installing libraries, see: http://www.arduino.cc/en/Guide/Libraries



**********************************Teensy****************************************
      A helper library for processing data between TeenC_Mex and TeenC.ino
********************************************************************************

This library can be imported into Arduino IDE as "#include <Teensy.h>".

Main Functions

1) readBinary()
Used to read byte array from TeenC_Mex and converts it to Float

2) writeFloatasBinary()
Used to write float value to TeenC_Mex as a byte array. 
IMPORTANT: this function uses Serial.send_now(). Therefore packages will be sent 
without buffering
********************************************************************************


