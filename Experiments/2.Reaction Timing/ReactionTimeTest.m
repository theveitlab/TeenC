%% Intitialising Teensy
addpath('D:\Lab Files - Prejwal\Results\Final\TeenC\v1');
addpath('D:\Lab Files - Prejwal\Results\Final\TeenC\v1\functions\');
clear mex;
teenC = TeenC('COM3');

% Setting up input and output pins
led = 2; % LED to display stimulus
button = 14; % reading value from a push button with a pull-up resistor
activePins = teenC.InitializePins([led, button], ["output","input"]);
%%
% Generation of random interval time vector
numStim = 5; % Number of stimulations
ansPeriod = 1; % Time to wait to recieve a response in s
intervals = randi([1000,5000], numStim,1)/1000;  % Generating random interval time. between 1 and 5 seconds. in ms
buttonPress_Values = zeros([numStim,500]);  %Vector with the button press values.
buttonPress_Times = zeros([numStim,500]);   %Vector with the button press times.
latencyTimes = zeros([numStim,500]);   %Vector with the io latency time Matlab->write->read->Matlab
%%
% Running experiment
while true
% Start Signal - Switches the LED on 3 times before starting the first
% trial
    for x = 1:3
        tic
        teenC.DigitalWrite(led, 1)
        while toc<.5
        end

        teenC.DigitalWrite(led, 0);
        while toc<1
        end
    end

% Running Experiment
% The stimulus would be presentated at random intervals and after the
% prsentation of stimulus a 1 second reaction window will be present to
% record the subjects reaction time.
    for trial = 1:numStim
        idx=1;    
        disp("*****Trial "+ trial + "*****")

        trialTime = tic;
        while toc(trialTime) < intervals(trial) %Inter-Trial Interval - Waiting time before the next stimulus presentation
        end
        
        disp("Interval Time: " + toc(trialTime));
        disp("");

        ledSwitchedOn = tic;
        teenC.DigitalWrite(led, 1);
        
        samplingTimePerTrial = tic;
        while toc(ledSwitchedOn)< ansPeriod

            pinValue = teenC.ReadPin(button);
            if isempty(pinValue) 
                buttonPress_Values(trial, idx) = 0;
            else
                buttonPress_Values(trial, idx) = pinValue;
            end
            
            buttonPress_Times(trial, idx) = toc(samplingTimePerTrial);
            idx = idx+1;
        end

        teenC.DigitalWrite(led, 0);
    end
    break;
end
%% Saving and Plotting The Data
subject = 3;

[status1, msg, msgID] = mkdir("Data/" + string(subject));

data = struct("Time", buttonPress_Times, "Values", buttonPress_Values);
writematrix(buttonPress_Values,"Data/" + string(subject)+ "/Values.csv");
writematrix(buttonPress_Times, "Data/" + string(subject)+ "/Times.csv");
save("Data/" + string(subject)+ "/Data.mat", "data");

legendLabels = [];
buttonPressOnsets = zeros(1,5);
for x=1:numStim
    plot(buttonPress_Times(x, 1:end-2000), buttonPress_Values(x, 1:end-2000));
    legendLabels = [legendLabels, "Trial" + x];
    buttonPressOnsets(x) = buttonPress_Times(x, find(buttonPress_Values(x,:) < 50 & buttonPress_Values(x,:) ~=0, 1)) ;
    hold on;
end
legend(legendLabels);
disp("Average Reaction Time: " + mean(buttonPressOnsets) *1000 +"ms");
%%
a = zeros(1,numStim);
for x=1:numStim
    a(x) = data.Time(x, find(data.Values(x,:) < 50 & data.Values(x,:) ~=0, 1));
end
disp("Average Reaction Time: " + mean(a) *1000 +"ms");