/*
   This file works along with PhotodiodePTBSync.m to test syncing of Teensy with MATLAB.
*/

#include <Teensy.h>
Teensy teensy;

int idx = 0; // Stores the length of the Array. ie: No of samples recorded
int PD_valueArray[7000]; // Array to store the voltage values from photodiode
unsigned long PD_timeArray[7000]; // Array to store the time of photodiode recordings
unsigned long timeArray[3]; // Array that store write and read times performed inside Teensy
unsigned long delayTime; // Helper variable for sampling the data
unsigned int samplingTime = 10; // Sampling time in microseconds (us)

void setup() {
  Serial.begin(115200);
  pinMode(16, INPUT); // Please set the pin no according to your setup. This is the pin which reads the voltage from the photodiode
}

void loop() {
  while (Serial.available() <= 0) {}
  while (Serial.available() > 0) {
    int menuItem = teensy.readBinary();
    /* Recording the stimulus (Screen flickers) using the photodiode. The stimulus onset will be the time used to sync the two devices
      Teensy begins to record voltage values until a value is sent to the serial port. ie: Serial.available > 0*/
    if (menuItem == 55403788)
    {
      while (Serial.available() == 0 && idx <= 7000) // Here 7000 ensures that the array does not overflow and crash teensy when sampling with very small times.
      {
        PD_timeArray[idx] = micros();
        PD_valueArray[idx] = analogRead(16);
        delayTime = PD_timeArray[idx];
        idx++;

        while (micros() - delayTime < samplingTime) {} // Wait until the sampling time is reached
        // If delayMicroseconds()is used the data is then sampled every samplingTime + ~10 us (processing time of the above code).
        // The above approach ensure you're sampling the data uniformly.
      }

    }
    /* Send the recorded photodiode data to MATLAB */
    else if (menuItem == 55121168)
    {
      teensy.writeFloatasBinary((float) idx); // Send length of the array storing the time and voltage values

      // Returning the value and time array for verification
      for (int w = 0; w < idx; w++)
      {
        teensy.writeFloatasBinary((float) PD_valueArray[w]);
        teensy.writeFloatasBinary((float) PD_timeArray[w]);
        Serial.send_now(); // This is redundant but for safety. Since teensy.writeFloatasBinary already has send_now
      }
    }
    /* Experiment Loop: This loop recieves and sends data to MATLAB N times while recording the time taken for each process */
    else if (menuItem == 55401800)
    {
      // These values are stored in MATLAB in the matrix MAIN_timeArray.
      timeArray[0] = micros(); // Column 3 of MAIN_timeArray
      float rxValue = teensy.readBinary();
      timeArray[1] = micros(); // Column 4 of MAIN_timeArray
      teensy.writeFloatasBinary(rxValue);
      timeArray[2] = micros(); // Column 5 of MAIN_timeArray

      // Sending the values to MATLAB
      for (int p = 0; p < 3; p++)
      {
        teensy.writeFloatasBinary((float) timeArray[p]);
        Serial.send_now();
      }
    }
  }
}
