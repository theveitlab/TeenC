/*
Necessary functions for communicating with Teensy.
*/

#ifndef Teensy_h
#define Teensy_h

#include "Arduino.h"

class Teensy
{
	public:
		Teensy();
		float readBinary();
		void writeFloatasBinary(float value);
		void _syncAlgo(int* maxValue, int* minValue, int* midValue, unsigned long* midTime, int* voltage, int* prevVoltage, int* idx, int pinNo);
		unsigned long syncTime(int pinNo);

};

#endif
