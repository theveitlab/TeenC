/* TeenC v1.0
 * Created: 08/02/2023
 * By: The Veit Lab
 * A framework that enables serial communication with MATLAB using mexFunction. Please refer to [GitHub Link] for more information
 */

// Import the Teensy library to enable easier datatype conversion for sending and recieving the data from TeenC_Mex
#include <Teensy.h>
Teensy teensy;

int inputPins[25]; // Array that stores the input pin number. This populated when InitializePins function is called
int outputPins[25]; // Array that stores the input pin number. This populated when InitializePins function is called
int inpPinIdx = 0; // Index is used to access the inputPins array. When inputPins array is populated this value will contain the total number of elements in inputPins array. 
int outPinIdx = 0; // Same purpose as above expect this is used for outputPins array

void setup() {
  Serial.begin(128000);
}

void loop() {
  while(Serial.available() <= 0)
  {
    /*
     * Waiting to recieve serial data
     */
  }
    
  while(Serial.available() > 0) 
  {
    int functionMode; // The unique token generated from MATLAB is stored here. The value of functionMode is used to access the various functions in the switch case block.
    functionMode = (int) teensy.readBinary();
    
    switch(functionMode) 
    {
      case 52771108:
      /*IntializePins - Function initializes input and output pins using pinMode*/
      {
        int pinNo;
        int modeNo;
        int len;
        
        /* IMPORTANT: On every call of IntializePins function the inputPins and outputPins array are reinitialsed. 
         * Therefore, if IntializePins is called for the seconds time, the pins number previously stored are deleted. 
         */
        inpPinIdx = 0;  
        outPinIdx = 0;
        memset(inputPins, 0, sizeof(inputPins));
        memset(outputPins, 0, sizeof(outputPins));

        // The length of the array of pins and values provided from TeenC_Mex. 
        //This is used to iterate through the list of pin numbers and values
        len = (int) teensy.readBinary();

        // TeenC_Mex passes the pin no and pin mode (input or output) for each iteration. 
        //Therefore, it is important pinNo and pinValue at InitializePins function in TeenC_Mex are of the same size.
        for (int i=0; i<len; i++) 
        {
          pinNo = (int) teensy.readBinary(); // reads the pin number
          modeNo = (int) teensy.readBinary(); // reads whether the pin is input or output

          // Here 1 for input and 2 for output is used as a convention. 
          if (modeNo == 1) 
          {
            pinMode(pinNo, INPUT);
            inputPins[inpPinIdx] = pinNo;
            inpPinIdx++;
            }
          else if (modeNo == 2) 
          {
            pinMode(pinNo, OUTPUT);
            outputPins[outPinIdx] = pinNo;
            outPinIdx++;
            } 
          }
        break;
      }

      
      case 51469648:
      /*DigitalWrite - Function to set the value of a pin to HIGH(1) or LOW(0)*/
      { 
        int pinNo;
        int pinValue;
        int len;

        // DigitalWrite can recieve arrays as well to set the values of multiple pins in a single write
        len = (int) teensy.readBinary();
        
        for (int i=0; i<len; i++) 
        {        
        pinNo = (int) teensy.readBinary();
        pinValue = (int) teensy.readBinary();
        digitalWrite(pinNo, pinValue);
        }
        break;
      }

      
      case 50683216:
      /*AnalogWrite - Function to set the value of a pin between 0 and 1023*/
      { 
        int pinNo;
        int pinValue;
        int len;
        
        len = (int) teensy.readBinary();
        
        for (int i=0; i<len; i++) 
        {        
        pinNo = (int) teensy.readBinary();
        pinValue = (int) teensy.readBinary();
        analogWrite(pinNo, pinValue);
        }
        break;
      }

      case 55121168:
      /*ReadPin - Function reads the value (voltage) at a given pin and prints it to the serial port*/
      {
        int pinNo;
        int len;
        
        len = (int) teensy.readBinary();        
        for (int i=0; i<len; i++) 
        {        
        pinNo = (int) teensy.readBinary();
        teensy.writeFloatasBinary(analogRead(pinNo));
        }         
        break;  
      }
      
      case 55117104:
      /*ReadAll - Function reads the value (voltage) from all the input pin initialised and prints it to the serial port*/
      {        
        for (int i=0; i<inpPinIdx; i++) 
        {
        int pinNo = inputPins[i];                  
        teensy.writeFloatasBinary(analogRead(pinNo));
        }         
        break;  
      }
    } 
  }
}
