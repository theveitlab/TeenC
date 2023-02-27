%% Testing Photodiode Response Between Top And Bottom of The Monitor
% Test to see if there is a temporal difference in the timing measurement 
% of the photdiode between the top and bottom of the screen.
% Code reference: https://peterscarfe.com/accurateTiming.html
%% Setup
% Intializing arrays to store the voltage values and times recorded from top and bottom of the screen
topValueArray = zeros(5000, 5);
topTimeArray = zeros(5000, 5);
bottValueArray = zeros(5000, 5);
bottTimeArray = zeros(5000, 5);

positionNo = 1; % 1=top, 2=bottom; Sets The position you're recording from. Please change the value manually depending on the position of the photodiode on the screen

%% Stimulus For Photodiode With Psychtoolbox
% A series of alternating black and white screens will be presented, where the screens flips every 0.5s.

windowPtr=Screen('OpenWindow', 1, 0);

hz = Screen('FrameRate', windowPtr);
topPriorityLevel = MaxPriority(windowPtr);
[ ifi, nrValidSamples, stddev ] = Screen('GetFlipInterval', windowPtr);
Priority(topPriorityLevel);
numSecs = 1;
numFrames = round(numSecs / ifi);

% Waiting for 0.5s before every screen flip
waitFrames = 30;

VBLArray = zeros(numFrames,1); % Array for the storing the time of when the screen flips (begining of the vertical trace)
StimuOnsetArray = zeros(numFrames,1); % Array to store the estimated stimulus onset from PTB

for trial=1:5

    clear mex; % Clears previous instances of mex. 
    teenC = TeenC('COM3'); % Connects/Reconnects to Teensy
    pause(1);

    Screen('FillRect', windowPtr, 127); % Starting the screen from black in order to prevent teensy recording the purple start screen.
    [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = Screen('Flip', windowPtr); 
    
    % Teensy starts recording
    startTime_TC = teenC.SyncTime("start"); % SyncTime returns the time from Teensy when it starts to record
    pause(0.1); % Pause ensures the Teensy has started to record before the first flip
    
    for frame=1:4        
        Screen('FillRect', windowPtr, mod(frame, 2)*255); % Presents a black screen at every even index, and a white screen at every odd index
        [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = Screen('Flip', windowPtr, VBLTimestamp + (waitFrames - 0.5) * ifi); 
        VBLArray(frame) = VBLTimestamp;
        StimuOnsetArray(frame) = StimulusOnsetTime;
    end
    
    % Stop recording from teensy
    endTime_TC = teenC.SyncTime("stop"); % Time at which Teensy stopped recording.
    
    teenC.SerialWrite(55121168); % NOTE: The INO file was set such that on passing the token 55121168 Teensy would begin transmitting the stored data
    % Refer Arduino File: PDResponseTopAndBottom.ino, For more info

    arrayLen = teenC.SerialRead(1); % Length of the array that stores the voltage read from the photodiode
    midVal = teenC.SerialRead(1); % The half of the peak voltage value from the photodiode
    midTime = teenC.SerialRead(1); % Time at which half-peak was detected
    estimatedTime = teenC.SerialRead(1); % Estimated time when the screen flip was detected. Very close to the value in StimuOnsetArray(3).
    
    % Assigning the voltage and values to for each trial and position
    if positionNo == 1 % Top of the screen
        for i = 1:arrayLen
            val = teenC.SerialRead(1);
            if isempty(val)
                topValueArray(i, trial) = 0;
            else
                topValueArray(i, trial) = val;
            end
    
            val = teenC.SerialRead(1);
            if isempty(val)
                topTimeArray(i, trial) = 0;
            else
                topTimeArray(i, trial) = val;
            end
        end
    
    elseif positionNo == 2 % Bottom of the screen
        for i = 1:arrayLen
            val = teenC.SerialRead(1);
            if isempty(val)
                bottValueArray(i, trial) = 0;
            else
                bottValueArray(i, trial) = val;
            end
    
            val = teenC.SerialRead(1);
            if isempty(val)
                bottTimeArray(i, trial) = 0;
            else
                bottTimeArray(i, trial) = val;
            end
        end    
    end
    
    disp("IMPORTANT: Please Press The Reset Button On Teensy");
    pause(5); % IMPORTANT: Here press the reset button on Teensy to start a fresh trial. This ensures no data is stuck in the serial port.
end

Screen('CloseAll');

topTimeArray = topTimeArray(topTimeArray> 0);
topValueArray= topValueArray(topValueArray> 0);

bottTimeArray= bottTimeArray(bottTimeArray> 0);
bottValueArray= bottValueArray(bottValueArray> 0);

%% Plotting And Analysis
meanBottArray = mean(topValueArray,2);
meanTopArray = mean(bottValueArray, 2);
arrayLabels = ["Top" "Bottom"];
time = (0:length(meanTopArray)-1) * 0.5;

plot(time, meanTopArray);
hold on;
plot(time, meanBottArray);
legend(arrayLabels);
xlabel("Time [ms]");
ylabel("Voltage [AU]");
title("Measuring Photodiode Response At The Top and Bottom of The Screen");