/* Testing Photodiode Response At The Top and Bottom of The Screen  
 * 
 * Place the photodiode at the top or bottom of the screen and run PDResponseTopAndBottom.m file.
 * The algorithm to calculate the estimated onset time of the screen flip has been integrated into the Teensy.h library
 * To use the function use: teensy.syncTime(pinNo); pinNo - The pin reading the voltage from the photodiode
 * 
 */

#include <Teensy.h>
Teensy teensy; 

unsigned long estimatedStimOnsetTime; 
int maxValue = 0;
int minValue = 1023;
int midValue = 0;
unsigned long midTime;
int voltage;
int prevVoltage[5] = {0,0,0,0,0};
int idx = 0;
int i = 0;
unsigned long tempTime;

int valueArray[6000];
unsigned long timeArray[6000];
unsigned long startTime;


// Algorithm finding the screen flip time by keeping a running buffer of voltage values
void SyncAlgo(int *maxValue, int *minValue, int *midValue, unsigned long *midTime, int *voltage, int *prevVoltage, int *idx, int *i)
{
  int average = 0;
  
  // Reading the voltage from pin and time in teensy
  *voltage = analogRead(16);
  tempTime = micros();
  
  // Finding The Max Value using a buffer.
  if (*voltage > *maxValue && *idx >= 4) // Wait for the buffer to be filled before computing the max/min value
  {
    prevVoltage[*idx] = *voltage;
    for (int x=0; x<5; x++) 
    {
      average = average + prevVoltage[x]; // Takes the average of the previous 4 values to calculate the max value. 
      //This provides a normalized max value this is done since the voltage response from the photodiode is noisy.
      }
    
    *maxValue = (average/5);

  if ((maxValue - minValue) > 7) 
  // Updates the 50% of peak value everytime the max/min is updated.
  {
    *midValue = *maxValue - ((*maxValue - *minValue) / 2);
    }
    }

  // Finding The Min Value using a buffer. Similar to calculating max value.  
  else if (*voltage < *minValue && *idx >= 4) 
  {
    prevVoltage[*idx] = *voltage;
    for (int x=0; x<5; x++) 
    {
      average = average + prevVoltage[x];
      }
    
    *minValue = (average/5);

    if ((maxValue - minValue) > 7) 
    {
      *midValue = *maxValue - ((*maxValue - *minValue) / 2);
      }    
    }
  else {
    prevVoltage[*idx] = *voltage; // Updating the buffer
    }    
    
  // When the voltage is +/- 1 the midvalue the time is recorded.
  if ((*voltage == *midValue) || (*voltage == *midValue+1) || (*voltage == *midValue-1)) 
  {
    *midTime = tempTime; // Assign the time when the voltage was reached
    }

  // Case to update the index for the buffer
  if (*idx == 4) 
  {
    *idx = 0;
    }
  else 
    {
      *idx = *idx+1;
      }      

  // Voltage values from the photodiode and the times are stored to verify the algorithm. This is not necessary the for 
  // the functioning of SyncAlgo. This is used to verify the times and values detected.
  valueArray[*i] = *voltage;
  timeArray[*i] = micros();
  *i = *i+1;
  }

void setup() {
  Serial.begin(115200);
  pinMode(16, INPUT);
}

void loop() {
  while(Serial.available() <= 0) {}
  while(Serial.available() > 0) {
    int menuItem = teensy.readBinary();
    
    if (menuItem == 55403788) 
    {
      // When this case is entered. Teensy begins to record voltage values until a value is sent to the serial port. ie: Serial.available > 0
      while(Serial.available() == 0) 
      {
        SyncAlgo(&maxValue, &minValue, &midValue, &midTime, &voltage, prevVoltage, &idx, &i);
        delayMicroseconds(10);
        }
      
      }
      else if (menuItem == 55121168) 
      {
        // This case returns the recorded values to MATLAB
        teensy.writeFloatasBinary((float) i); // length of the array storing the time and voltage values
        teensy.writeFloatasBinary((float) midValue); // Half-max of the photodiode voltage peak
        teensy.writeFloatasBinary((float) midTime); // Time at which half max was detected.
        teensy.writeFloatasBinary((float) (midTime - 4000)); // Since the rise time is around 8ms (Response Time of monitor), 
                                                             //taking 4ms before halfmax will give the estimated stimulus onset

        // Returning the value and time array for verification
        for (int w=0; w<i; w++) 
        {
          teensy.writeFloatasBinary((float) valueArray[w]);
          teensy.writeFloatasBinary((float) timeArray[w]);
          Serial.send_now();
          }
        }
    }
  
}
