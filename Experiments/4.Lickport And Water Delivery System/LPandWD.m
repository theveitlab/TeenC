% Please load "\TeenC\v1\ino\TeenC\TeenC.ino" to Teensy
addpath('D:\Lab Files - Prejwal\Results\Final\TeenC\v1');
addpath('D:\Lab Files - Prejwal\Results\Final\TeenC\v1\functions\');
%% Initialising Teensy And Setup
clear mex;
teenC = TeenC('COM3');

% Setting the pins for controling the valve and reading from lickport.
valveConstantPin = 4; % Pin to provide the constant voltage to the driver (L293D Pin: 1 (1,2EN))
valveControlPin = 3; % Pin to control the valve (L293D Pin: 2 (1A))
lickport = 16; % Reads the amplified voltage from the lickport using INA121P
activePins = teenC.InitializePins([valveControlPin, valveConstantPin, lickport], ["output","output","input"]);
%% Saving Mouse Details
mouseNo = "SOM57"; % Name and number of the mouse
sessionID = 1;
%% Setup For The Water Delivery System
teenC.DigitalWrite(valveConstantPin, 1); % Setting the valve constant pin to HIGH
teenC.DigitalWrite(valveControlPin, 1); % Opening the valve to flush the liquid.

% Waiting to fill the lickport syringe with the liquid. This is important
% to ensure no air bubbles are formed since we are not using a pump.
while 1
    disp("Please Flush The Liquid");
    prompt = "Enter 'Y' When Done\n";
    usrInp = input(prompt);
    if usrInp == 'Y'
        disp("");
        teenC.DigitalWrite(valveControlPin, 0); % Closing the valve with user input
        break;
    else
        disp("Please Enter The Correct Character. 'Y'");
    end
end
%% Recording The Data
lickportValues = zeros(1,2000); % Storing the values from lickport to plot the data
lickTimes = zeros(1,2000); % Storing the time when a lick was detected
lickTimeIdx = 1;
lickData = zeros(2,180000); % Array to store the lickport data recorded
lickDataSkipIdx = 0; 
lickDataIdx = 1;
waitTimeForReward = 1.5; % No of seconds to wait before next reward can be given
varianceThreshold = 25; % Here we calculate the variance the lickport signal to detect the licks. This values sets the threshold


figure;
disp("Starting To Record From LickPort");
k = 1;
waitTimer = tic;
valveTimer = tic;
valveOpenTime = 0.05;
valveState = 0; % 0 - closed valve; 1 - open valve;

fig = plot(lickportValues);
tic; % Zero time of the session.

while k
    value = teenC.ReadPin(lickport); % Read value from the lickport
    time = toc; % Sampling time of the lick
    lickportValues = [lickportValues(2:end), value]; % Creating a moving window for plotting

    variance = var(lickportValues(end-10:end)); % Calculating the variance of 20 values. 
    % 20 is choosen since, with the current sampling rate (~5ms, with live
    % plotting) the peaks last for about 40 samples. Hence, 20 samples
    % would contain half of the peak thereby giving a high variance value.
    
    if variance > varianceThreshold && toc(waitTimer) > waitTimeForReward
    % This checks if the variance threshold is crossed (ie: detected a
    % lick) and the we are not in the wait period for next reward the next
    % reward can be triggered.
        teenC.DigitalWrite(valveControlPin, 1); % Opening the valve.
        
        % valveTimer and valveState are used to control how long the valve
        % should be open. ie: How much of reward should be delivered.
        valveTimer = tic;
        valveState = 1;

        waitTimer = tic; % Resetting the reward time
        lickTimes(lickTimeIdx) = valveTimer;
        lickTimeIdx = lickTimeIdx + 1;
    end    
    
    if valveState == 1 && toc(valveTimer) > valveOpenTime
    % This closes the valve once the set amount of reward is delivered
        teenC.DigitalWrite(valveControlPin, 0);
        valveState = 0;
    end
    
    if lickDataSkipIdx == 5
    % Recording every 5th sample of data from the lickport. ie: The saved
    % data will have a sampling rate of ~40Hz
        lickData(1, lickDataIdx) = value;
        lickData(2, lickDataIdx) = time;
        lickDataIdx = lickDataIdx + 1;
        lickDataSkipIdx = 0;
    else
        lickDataSkipIdx = lickDataSkipIdx + 1;
    end
    
    % Updating the live plot
    set(fig, 'YData', lickportValues);
    drawnow;
    set(gcf, 'WindowButtonDownFcn', 'k=0;');
end

%% Saving The Data
recTime = timeofday(datetime('now'));

data = struct("MouseNo",mouseNo, ...
    "SessionID", sessionID, ...
    "VarianceThreshold", varianceThreshold, ...
    "RewardWaitTime", waitTimeForReward, ...
    "RecDate", datetime("today"), ...
    "RecTime", recTime, ...
    "LickportValues", lickData(1,:), ...
    "LickportTimes", lickData(2,:), ...
    "LickTimes", lickTimes);

dateString = string(datetime("today"));

pat = characterListPattern(":");
timeString = replace(string(recTime), pat, "_");

[status1, msg, msgID] = mkdir("Data/" + dateString);

if status1 == 1
    [status2, msg, msgID] = mkdir("Data/" + dateString + "/" + string(mouseNo));
else
    disp("Something went wrong creating the folder");
end

if status2 == 1
    filename = timeString + "_" + "Session_" + sessionID + ".mat";
    savelocation = "Data/" + dateString + "/" + string(mouseNo) + "/" + filename;
    save(savelocation, "data");
else
    disp("Something went wrong creating the folder");    
end
