%% Testing Round Trip Latency With MATLAB & mexFunction
% The program measures the latency for sending and recieving int8 values
% from Teensy.
% 
% Arduino Files - 1) ino/TestingRoundTripLatency_WithoutSendNow, 2) ino/TestingRoundTripLatency_WithSendNow

%% Setup Code
samples = 1000; % Number of samples to send (No of Trials)
valuesArray = zeros(samples,1); % Array to store the recieved value. Helps to check whether the recieved value is valid
timeArray = zeros(samples,1); % Array to record the latency times.

%% MATLAB


device = serialport("COM3", 128000); %Initializes the connection to the serial port

for i = 1:samples
    val = mod(i,100); % value to send

    % Start measurement
    tic
    write(device, val, 'uint8'); % Writing to Teensy
    val = read(device,1,"uint8"); % Read from Teensy
    timeArray(i) = toc * 1000; % (* 1000) to convert to milliseconds.
    % Stop measurement
    
    valuesArray(i) = val;
end

% Display the average latency
disp(mean(timeArray, 'all'));

%% MexFunction
teenC = TeenC(); % Connect to the serial port via the TeenC library

for i = 1:samples

    % Start measurement
    tic
    teenC.SerialWrite(i); % Writing to Teensy
    val = teenC.SerialRead(1); % Read from Teensy
    timeArray(i) = toc * 1000; % (* 1000) to convert to milliseconds.
    % Stop measurement

    valuesArray(i) = val;
end

% Display the average latency
disp(mean(timeArray, 'all'));