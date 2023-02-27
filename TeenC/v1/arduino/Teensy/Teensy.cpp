#include "Arduino.h"
#include "Teensy.h"

Teensy::Teensy() {}

float Teensy::readBinary() 
// Function that reads binary data from MATLAB and converts it to float value
{
  	float data[4];
  	float val;
  	static byte i = 0;
	
  	union u_tag {
    	byte b[4];
    	float fval;
  	} u;
  	
	while(i<4) {
    		data[i] = Serial.read(); 
    		i++;
  	}

  	u.b[0] = data[0];
  	u.b[1] = data[1];
  	u.b[2] = data[2];
  	u.b[3] = data[3];

  	val = u.fval;
	i = 0;
	return val;  
}

void Teensy::writeFloatasBinary(float value) 
// Function used to write float values as byte array
{
    byte* b = (byte*)&value;
    Serial.write(b, 4);
    Serial.send_now();
}

void Teensy::_syncAlgo(int* maxValue, int* minValue, int* midValue, unsigned long* midTime, int* voltage, int* prevVoltage, int* idx, int pinNo)
// Alogrithm for syncing PC and Teensy time using photodiode. 
// See "Experiments\3.Calibration With Photodiode\ino\PDResponseTopAndBottom\PDResponseTopAndBottom.ino" for more details.
{

    int average = 0;
    *voltage = analogRead(pinNo);

    if (*voltage > *maxValue && *idx >= 4)
    {
        prevVoltage[*idx] = *voltage;
        for (int x = 0; x < 5; x++)
        {
            average = average + prevVoltage[x];
        }

        *maxValue = (average / 5);
    }
   
    else if (*voltage < *minValue && *idx >= 4)
    {
        prevVoltage[*idx] = *voltage;
        for (int x = 0; x < 5; x++)
        {
            average = average + prevVoltage[x];
        }

        *minValue = (average / 5);

    }

    if ((*maxValue - *minValue) > 7)
    {
        *midValue = *maxValue - ((*maxValue - *minValue) / 2);
    }

    prevVoltage[*idx] = *voltage; 

    if ((*voltage == *midValue) || (*voltage == *midValue + 1) || (*voltage == *midValue - 1))
    {
        *midTime = micros();
    }


    if (*idx == 4)
    {
        *idx = 0;
    }
    else
    {
        *idx = *idx + 1;
    }
}

unsigned long Teensy::syncTime(int pinNo) {
    unsigned long estimatedStimOnsetTime;
    int maxValue = 0;
    int minValue = 1023;
    int midValue = 0;
    unsigned long startTime;
    unsigned long midTime;
    int voltage;
    int prevVoltage[5] = { 0,0,0,0,0 };
    int idx = 0;

    startTime = micros();
    Teensy::writeFloatasBinary(startTime);

    while (Serial.available() == 0)
    {
        Teensy::_syncAlgo(&maxValue, &minValue, &midValue, &midTime, &voltage, prevVoltage, &idx, pinNo);
        delayMicroseconds(100);
    }

    estimatedStimOnsetTime = midTime - 4000;
    return estimatedStimOnsetTime;
}

