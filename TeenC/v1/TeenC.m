classdef TeenC < handle
    % TeenC
    % TeenC enables serial communication with Teensy using mexFunction (TeenC_Mex)
    % and provides pre-built I/O functionalities. Use the provided "ino/TeenC.ino".
    %
    % TeenC Properties:
    %   connected - If connected to Teensy returns true, else false.
    %   activePins - Gives a struct that contains the list of input and output pins initialised.
    % 
    % TeenC Methods:
    %   InitializePins - Set I/O pins that are connected to Teensy
    %   DigitalWrite - Used to set a pin value to either HIGH or LOW
    %   AnalogWrite - Used to set a pin value to a number between 0 and 1023
    %   ReadPin - Reads the input value from one or multiple pins
    %   ReadAll - Reads the input value from all pins initialized as input using InitializePins
    %   SerialRead - Read a value from the serial port
    %   SerialWrite - Write to the serial port

    properties
        connected = false;
        activePins = struct();     
    end

    properties (Access = private)
        % These tokens are used to access the various functions inside
        % TeenC.ino. See also functions/str2binTokenGenerator.m

        digWriteToken = str2binTokenGenerator(['L','D','W','T']); % Token for DigitalWrite 
        anaWriteToken = str2binTokenGenerator(['L','A','W','T']); % Token for AnalogWrite
        readPinToken = str2binTokenGenerator(['L','R','E','D']); % Token to read from a pin
        readAllToken = str2binTokenGenerator(['L','R','A','L']); % Token to read all input pins
        initializeToken = str2binTokenGenerator(['L','I','N','I']); % Token to initialize the input and output pins
        syncToken = str2binTokenGenerator(['L','S','Y','C']); % Token to perform time syncing (In-developement not fully functional)
    end

    methods
        function obj = TeenC(comPortNo)
            % TeenC     Connect to Teensy      
            % Teensy is initialised with the follwing parameters
            %   a) Baudrate - 128000
            %   b) Bytesize - 8
            %   c) Stopbit - ONESTOPBIT
            %   d) Parity - No Parity
            %   e) Overlapped - No

            if ~obj.connected 
                    TeenC_Mex('I', comPortNo);
                    obj.connected = true;                    
            else 
                    disp("Already Connected To TeenC");
            end
        end

        function returnPins = InitializePins(obj, pinNo, pinValues)
            % InitializePins    Used to set the input and output pins
            % If the I/O pins are used to read or send data to hardware, please use this function to first initialise the I/O pins.
            % 
            % retuns a struct contains the input and output pins.

            if length(pinNo) ~= length(pinValues)
                warning("Please Ensure The Size of pinNo is Equal To Size of pinValues");
            end          
            
            % Creating the struct that will be returned
            obj.activePins.input = pinNo(pinValues == "input"); 
            obj.activePins.output = pinNo(pinValues == "output");
            
            % Teensy requires the input and output variable to be number.
            % See ino/TeenC.ino for more information
            pinValues(pinValues == "input") = 1;
            pinValues(pinValues == "output") = 2;

            % Creating the data package and processing the data to be sent.
            pinValues = str2double(pinValues);
            dataPacket = reshape([pinNo ; pinValues], 1, []); 
            dataPacket = [obj.initializeToken, length(pinNo), dataPacket];

            TeenC_Mex('W', single(dataPacket));
            returnPins = obj.activePins;
        end

        function DigitalWrite(obj, pinNo, pinValues)
            % DigitalWrite      Used to set a digital pin to either HIGH or LOW
            % Ensure that the pinNo and pinValues are equal in length, ie: each
            % pin has a value associated. Please pass the pinValue as either 0 or 1.
            
            if length(pinNo) ~= length(pinValues)
                warning("Please Ensure The Size of pinNo is Equal To Size of pinValues");
            end
            
            dataPacket = reshape([pinNo ; pinValues], 1, []);
            dataPacket = [obj.digWriteToken, length(pinNo), dataPacket];
            TeenC_Mex('W', single(dataPacket));
        end

        function AnalogWrite(obj, pinNo, pinValues)
            % AnalogWrite      Used to write an analog value to a pin
            % Ensure that the pinNo and pinValues are equal in length, ie: each
            % pin has a value associated. AnalogWrite uses PWM wave to
            % write an analog value. Ensure the value of pinValue is
            % between 0 and 1023.

            if length(pinNo) ~= length(pinValues)
                warning("Please Ensure The Size of pinNo is Equal To Size of pinValues");
            end

            dataPacket = reshape([pinNo ; pinValues], 1, []);
            dataPacket = [obj.anaWriteToken, length(pinNo) dataPacket];
            TeenC_Mex('W', single(dataPacket));
        end

        function SyncTime(obj, func)
            % SyncTime      This sync time the Time in Teensy and MATLAB
            % This requires a photodiode to be connected using a
            % transimpedance circuit and sending an input to pin 16 of
            % Teensy. See "Examples/Photodiode_Basic.m" for more info

            if func == "start"
                dataPacket = [obj.syncToken];
                obj.SerialWrite(single(dataPacket));
            elseif func == "stop"
                dataPacket = 0.999;
                obj.SerialWrite(single(dataPacket));
            end
        end

        function readValue = ReadPin(obj, pinNo)
            % ReadPin   Used to read a value from a pin
            % The value recorded at pinNo is read using analogRead.
            % Multiple pins can also be provided in an array. eg: [1,2,3],
            % where 1,2,3 are pin nos of Teensy

            dataPacket = [obj.readPinToken, length(pinNo), pinNo];
            TeenC_Mex('W', single(dataPacket));
            readValue = TeenC_Mex('R', single(length(pinNo)));
        end
        
        function readValues = ReadAll(obj)
            % ReadAll   Reads from all the pins initialised as input
            readValues = TeenC_Mex('R', single(obj.readAllToken));
        end

        function readVal = SerialRead(~, noElementsToRead)
            % SerialRead    Read any data that has been printed onto the serial port
            % See "Examples/SerialComm.m" for more info
            readVal = TeenC_Mex('R', single(noElementsToRead));
        end

        function SerialWrite(~, data)
            % SerialWrite    Write data to the serial port
            % See "Examples/SerialComm.m" for more info
            TeenC_Mex('W', single(data));
        end

    end
end    