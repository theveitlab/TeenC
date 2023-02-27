% Here we test syncing the times of Teensy and MATLAB using a photodiode.
% Pscyhtoolbox is used for stimulus presentation where it flickers the
% screen black and white and the stimulus onset serves as the time that
% both the devices would be synced too.
% Here we emply two approaches to estimating the stimulus onset. Using
% two intersection of lines that are fit to the curve and using the
% builtin risetime function in MATLAB
%
% Please refer to PhotodiodePTBSync.ino for more info. Additonally load
% this file to Teensy for testing
%% Setting Path To Teensy Files
addpath('D:\Lab Files - Prejwal\Results\Final\TeenC\v1');
addpath('D:\Lab Files - Prejwal\Results\Final\TeenC\v1\functions\');
%% Intialising Teensy And Setting Up The Variables
clear mex;
teenC = TeenC('COM3');

% Arrays that store the photodiode measurements
PD_valueArray = zeros(1,100);
PD_timeArray = zeros(1,100);
%% Stimulus Presentation For Syncing

windowPtr=Screen('OpenWindow', 1, 0);
hz = Screen('FrameRate', windowPtr);
topPriorityLevel = MaxPriority(windowPtr);
[ ifi, nrValidSamples, stddev ] = Screen('GetFlipInterval', windowPtr);
Priority(topPriorityLevel);
numSecs = 1;
numFrames = round(numSecs / ifi);

% Here we flip the screen every frame, since we are recording with a very
% low sampling time and teensy can only store 7000 samples. Therefore only a short amount of time can be recorded approx ~70ms 
waitFrames = 1; 
VBLArray = zeros(numFrames,1); % Array storing the vertical blank times
StimuOnsetArray = zeros(numFrames,1); % Array storing the stimulus onset times

Screen('FillRect', windowPtr, 127); % Starting the screen from grey in order to prevent teensy recording the purple start screen.
[VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = Screen('Flip', windowPtr);
% ----------------------------------------------------------------------------------------------------------------------------------
%
% *************Detecting Photodiode Transient************
% ****************Teensy starts recording****************
%
teenC.SyncTime("start");

for frame=1:6
    Screen('FillRect', windowPtr, mod(frame, 2)*255); % Screen is black is at even numbers and white at odd
    [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = Screen('Flip', windowPtr, VBLTimestamp + (waitFrames - 0.5) * ifi);
    VBLArray(frame) = VBLTimestamp;
    StimuOnsetArray(frame) = StimulusOnsetTime;
end

teenC.SyncTime("stop"); % Time at which Teensy stopped recording.

%
% ****************Teensy Stops Recording****************
%
Screen('CloseAll');
% ----------------------------------------------------------------------------------------------------------------------------------
%
% *************Reading Photodiode Data************
%
teenC.SerialWrite(55121168); % NOTE: The INO file was set such that on passing the token 55121168 Teensy would begin transmitting the stored data
% Refer Arduino File: PhotodiodePTBSync.ino, For more info


arrayLen = teenC.SerialRead(1); % Length of the array that stores the voltage read from the photodiode
for x = 1:arrayLen
    val = teenC.SerialRead(1);
    if isempty(val)
        PD_valueArray(x) = 0;
    else
        PD_valueArray(x) = val;
    end

    time = teenC.SerialRead(1);
    if isempty(time)
        PD_timeArray(x) = 0;
    else
        PD_timeArray(x) = time;
    end
end
% ----------------------------------------------------------------------------------------------------------------------------------
%
% *************Experiment Loop************
% Here we measure the round trip latecy while measuring the taken at each
% point of the process
%
trials = 100;
recievedValues = zeros(trials, 1); % This array helps us to verify if we have sent and recieved the correct values
MAIN_timeArray = zeros(trials, 6); % The array that store all the timing data

GetSecs(); % This is called here, since calling GetSecs() for the first time takes quite a large amount of time. Therefore this greatly increases the delay in the measurement.
completionTimes = zeros(trials, 3); % Stores the time taken to complete each trial. Usefull to verify our individual timings

for trial = 1:trials    
    pinValue = trial + 0.1234; % Value that is sent
    completionTimes(trial, 1) = GetSecs; % Recording start of the trial
    
    MAIN_timeArray(trial,1) = GetSecs; % Column 1 of MAIN_timeArray: Time before writing data
    teenC.SerialWrite([55401800, trial]);

    MAIN_timeArray(trial,2) = GetSecs; % Column 2 of MAIN_timeArray: write complete and reading begins
    recievedValues(trial) = teenC.SerialRead(1);

    MAIN_timeArray(trial,6) = GetSecs; % Column 1 of MAIN_timeArray: completion of Read

    completionTimes(trial, 2) = GetSecs; % Completion time for each trial
    completionTimes(trial, 3) = completionTimes(trial, 2) - completionTimes(trial, 1); % Time taken for one trial

    % Gets the times from Teensy
    timeFromTeensy = teenC.SerialRead(3);
    MAIN_timeArray(trial,3:5) = timeFromTeensy;
end
%% Sampling a Small Section to Detect Stimulus Onset
plot(PD_valueArray);
title("Complete Photodiode Signal");

sampleWave = PD_valueArray(4200:5400);
sampleTime = PD_timeArray(4200:5400);

plot(sampleWave);
title("Sampled Photodiode Signal");
%% Finding Stimulus Onset: Approach 1: Bootstrap
line1StartIdx = 4600;
line1EndIdx = 4800;
line2StartIdx = 4950;
line2EndIdx = 5100;
bootstrapEpochs = 100;

% Refer to function DetecStimulusOnset.m and bootstrapLine.m for more info
[estimatedStimOnsetTime_Bootstrap, estimatedStimulusOnsetValue, error] = DetectStimulusOnset(sampleWave, sampleTime, line1StartIdx, line1EndIdx, line2StartIdx, line2EndIdx, bootstrapEpochs);
%% Finding Stimulus Onset: Approach 2: Risetime function
minmaxLevels = statelevels(sampleWave); % Gets the max and minmum value of the wave
[r, x1, x2, y1, y2] = risetime(sampleWave, sampleTime);
slope = (y2 - y1) / (x2 - x1);
estimatedStimOnsetTime_RiseTime = ((minmaxLevels(1) - y1) / slope) + x1; 
%% Normalising Teensy Time To MATLAB Time
eventTimeline = MAIN_timeArray;
eventTimeline(:,3:5) = (eventTimeline(:,3:5) - (estimStimOnsetTime_RiseTime)) * 1e-06;
eventTimeline(:,1:2) = eventTimeline(:,1:2) - StimuOnsetArray(3);
eventTimeline(:,6) = eventTimeline(:,6) - StimuOnsetArray(3);

for i=1:trials
    eventTimeline(i,:) = eventTimeline(i,:) - eventTimeline(i,1);
end