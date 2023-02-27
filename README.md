# TeenC  v1.0
## Introduction
TeenC is a library written in C and interfaced with MATLAB using mexFunction for serial communication. The code was tested and implemented on Teensy 3.2. This code provides a basic foundation for building more complex applications that require low-latency, real-time communication between a computer and a Teensy microcontroller.

## Installation
### Pre-Requisite
Please follow the instructions at [Teensy's](https://www.pjrc.com/teensy/tutorial.html) official page to install [Arduino IDE](https://www.arduino.cc/en/software) and [Teensyduino](https://www.pjrc.com/teensy/td_download.html). 

### Getting Started
1. Add ```TeenC/v1/arduino/Teensy``` to your Arduino IDE library. This is usually located under ```Documents/Arduino/libraries```. Please refer [here](https://support.arduino.cc/hc/en-us/articles/5145457742236-Add-libraries-to-Arduino-IDE) for more information on this.
2. Upload the sketch ```/TeenC/v1/ino/TeenC.ino``` to your Teensy.
3. In MATLAB, add the following folders to your path.
```MATLAB
addpath('[Location of this folder]/TeenC/v1');
addpath('[Location of this folder]/TeenC/v1/functions');
```
4. Find the COM port number your Teensy is connected too. If your Teensy is connected it can be found in the Arduino IDE, under Tools>Port>[Your COM port number] (Teensy 3.x).
5. You're all set to GO !!

## Examples
All the tests performed and MATLAB files can be found at [Experiments](Experiments/).
Here is a basic run down of commands and workflow of using TeenC.

### 1. Blink The On-Board LED
This example allow for the control for the on-board LED on Teensy on MATLAB.
```MATLAB
%The TeenC class is called here. 
%And the COM port number is part passed as a string. Eg: 'COM1', 'COM5', etc.. 
teenC = TeenC('COM3'); 

% Intialize the pins that Teensy will be using. 
%This uses the pinMode of Arduino to initialize the input and output pins
% teenC.InitializePins returns a struct that shows the input and output pins you've set.
activePins = teenC.InitializePins(13,"output"); % The onboard LED is at pin 13 in Teensy 3.2

% Now you're ready to go.
teenC.DigitalWrite(13,1); %This turns on the LED. DigitalWrite takes in (pinNo, pinValue).
teenC.DigitalWrite(13,0); %This switches the LED off.

%Now Let's blink the LED on and off 3 times.
for i=1:3
	teenC.DigitalWrite(13,1);
	pause(0.5);
	teenC.DigitalWrite(13,0);
	pause(0.5);
end

% Once you're done disconnect from Teensy.
clear mex;
``` 
### 2. Read Input From a Pin
Let's say you want to read from a particular device connected to your Teensy from pin 16.
```MATLAB
%Initialize TeenC and your pins
teenC = TeenC('COM3');
activePins = teenC.InitializePins(16,"input");

% Now let's read a value from the pin. 
valueFromPin = teenC.ReadPin(16); %ReadPin takens in the PinNo you want to read from.
%ReadPin utilizes analogRead from Arduino to read the voltage at pin.

%In case you're reading from multiple pins
activePins = teenC.InitializePins([2,11,16],"input");

%You can read from all the pin at once.
valueFromPins = teenC.ReadPin([2,11,16]);
%OR
valueFromPins = teenC.ReadAll(); %Reads the voltage from all the pins
``` 
You can check out [Reaction Time Test](Experiments/) for an example of setting up a MATLAB script that displays a stimuli and recording the subject's response.
