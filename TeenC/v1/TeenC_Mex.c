#include "mex.h"
#include "matrix.h"
#include <stdio.h>
#include <windows.h>

static HANDLE _serialPort = NULL; // Handle that stores the serial port object. This is used to access all serial port properties.
char* strComPort;

bool TeensyConnect(char* ComPortNo)
// TeensyConnect is used to connect to the Teensy. This is intialized on when TeenC_Mex process is intialised. See function DLLMain for more info.    
{
    HANDLE serialPort;
    DCB dcbSerialParameters = { 0 };

    serialPort = CreateFileA((LPCSTR) ComPortNo,
        GENERIC_READ | GENERIC_WRITE,
        0,                            
        NULL,                         
        OPEN_EXISTING,
        0,            
        NULL);


    if (serialPort == INVALID_HANDLE_VALUE) {   
        printf("******ERROR******\n");
    }

    if (!GetCommState(serialPort, &dcbSerialParameters)) {
        printf("ERROR in getting DCB parameters\n");
        mexErrMsgTxt("Please ensure you Teensy is connected or you've entered the correct COM port number. Eg: 'COM3'\n");
        return 0;
    }
    else {
        // Properties that the Teensy is connected with
        dcbSerialParameters.BaudRate = CBR_128000;
        dcbSerialParameters.ByteSize = 8;
        dcbSerialParameters.StopBits = ONESTOPBIT;
        dcbSerialParameters.Parity = NOPARITY;
        dcbSerialParameters.fDtrControl = DTR_CONTROL_ENABLE;

        if (!SetCommState(serialPort, &dcbSerialParameters)) {
            printf("DCB Parameters Could Not Be Set\n");
            return 0;
        }
        else {
            PurgeComm(serialPort, PURGE_RXCLEAR | PURGE_TXCLEAR);
        }
    }

    COMMTIMEOUTS timeouts = { 0, //interval timeout. 0 = not used
                              0, // read multiplier
                             5, // read constant (milliseconds); Specifies the time to wait to read a value from Teensy.
                              0, // Write multiplier
                              0  // Write Constant
    };


    SetCommTimeouts(serialPort, &timeouts);

    _serialPort = serialPort;
    printf("******Successfully Connected To Teensy******\n\n");
    return 1;
}

void TeensyDisconnect()
// Closes the serial port connection when the process is terminated. Runs when "clear mex" is called on MATLAB.
{
    CloseHandle(_serialPort);
    printf("******Disconnected From Teensy******\n\n");
}

void Float2Bytes(float val, byte* bytes_array) {
// Convert float values to byte[4] array.    
    union {
        float float_variable;
        byte temp_array[4];
    } u;
    u.float_variable = val;
    memcpy(bytes_array, u.temp_array, 4);
}

float Bytes2Float(float f, byte* b) {
// Converts byte[4] array to a float value
    memcpy(&f, &b, sizeof(f));
    return f;
}


byte* GetByteArray(float *tempData, int lenTempData) 
// Used before sending any value since the WriteFile function requires a byte array. This ensure no conversion of datatype is required at Teensy. 
{
    byte dataPacket[512];
    
    for (int x = 0; x < lenTempData; x++) {
        byte bytes[4];        
        Float2Bytes(tempData[x], bytes);
        memcpy(dataPacket + (x * 4), bytes, 4);
    }
    return dataPacket;
}

float* GetFloatArray(byte *lpBuffer, int bytesRead)
// Used to convert the byte array recieved from Teensy to a floating point array.
{
    float ans[512]; 

    for (int x = 0 ; x<bytesRead; x++) 
    {
        byte temp[4];
        memcpy(temp, lpBuffer + (4 * x), 4);

        ans[x] = *(float*)&temp;
    }
    return ans;
}

bool SerialRead(mxArray* plhs[], int len)
// Used to read any value sent from Teensy using Serial.write or Teensy.sendFloatasBinary.
{
    int noBytesToRead = 4*len; // Length of the array expected to be read. 4* is used since ReadFile is recieving binary data where each element is 4 bytes.
    byte lpBuffer[512]; // Buffer that will store the recieved data
    DWORD bytesRead; // Gives the number of bytes read by ReadFile. Useful for debugging to see if all the expected data is read.
    bool readStatus = 0; // If 1. the read was successfull. Else 0.
    float *y; // Pointer to the array that will be sent to MATLAB
    
    // Recieving the data from Teensy
    readStatus = ReadFile(_serialPort, lpBuffer, noBytesToRead, &bytesRead, NULL);

    // Since the data is recieved as a byte array this is converted to float array before sending it to MATLAB
    float recievedData[512];
    memcpy(recievedData, GetFloatArray(lpBuffer, (int) bytesRead), (int) bytesRead);

    // Assigning the pointers that will store the value to sent to MATLAB. This is necessary to convert the C float array to the type of MATLAB matrix.
    plhs[0] = mxCreateNumericMatrix(1, (int) bytesRead/4, mxSINGLE_CLASS, mxREAL); // Setting the output to be a MATLAB matrix
    y  = (float *) mxGetData(plhs[0]); // y points to the output matrix
    memcpy(y, recievedData, (int) bytesRead); // The values recieved from Teensy (recievedData) is copied to y. Therefore, the *y will have stored values
    return readStatus;
}

bool SerialWrite(float *tempData, int lenTempData) 
// Used to write values to the serial port. This value can be recived on Teensy by Serial.read or Teensy.readBinary.
{
    int noBytesToWrite = 4 * lenTempData; // Length of the array expected to be read. 4* is used since ReadFile is recieving binary data where each element is 4 bytes.
    DWORD numBytesWritten; // Gives the number of bytes written by WriteFile. Useful for debugging to see if all the expected data is written.
    byte dataPacket[512]; // Buffer that will store the recieved data
    bool writeStatus; // If 1. the read was successfull. Else 0.

    // Converting the float values to a byte array this is done to ensure Teensy recives the values sent as expected.
    memcpy(dataPacket,GetByteArray(tempData, lenTempData), sizeof(GetByteArray(tempData, lenTempData)));

    // Writing the data to Teensy
    writeStatus = WriteFile(_serialPort, dataPacket, noBytesToWrite, &numBytesWritten, NULL);
    return writeStatus;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
// This controls the calling of above function and helps in exchange of information between MATLAB and C.
{
    char functionMode; // Used to navigate between the various function defined below.
    char* functionModePtr;
    float *pinPtr;
    float *lenPtr;
    int len;

    if (nrhs != 0) 
    {
        functionModePtr = mxArrayToString(prhs[0]);
        functionMode = *functionModePtr;
    }
    else 
    {
        mexErrMsgTxt("Please Provide A Valid Input ('W','R','I', or 'S')");
    }

    switch (functionMode)
    // Navigate between the different functions defined. New function can be defined by adding another case with a character.
    {
        case 'I':
            {
            // Called when the TeenC object is initialized in MATLAB.
            if (nrhs != 2) {
                mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs", "Two input required.");
            }
        
            if (!mxIsChar(prhs[1])) {
                mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notString", "Input must be a string.");
            }
        
            strComPort = mxArrayToString(prhs[1]);
            TeensyConnect(strComPort);
            break;
            }
        case 'S':
            // Setting I/O to pins
            if (nrhs < 2) 
            {
                mexErrMsgTxt("Please Provide Valid Inputs ('S', arrayofPins, arrayofInputModes)\n");
            }

            pinPtr = (float*) mxGetData(prhs[1]);
            len = mxGetNumberOfElements(prhs[1]);
            SerialWrite(pinPtr, len);
            break;
        
        case 'W':
            // Serial Write
            pinPtr = (float*) mxGetData(prhs[1]);
            len = mxGetNumberOfElements(prhs[1]);
            SerialWrite(pinPtr, len);
            break;            


        case 'R':
            //Serial Read
            if (nrhs < 1) 
            {
                mexErrMsgTxt("Please Provide Valid Inputs\n");
            }
            lenPtr = (float*) mxGetData(prhs[1]);
            SerialRead(plhs, (int) *lenPtr);
            break;       
    }

    // Runs when 'clear mex' is called from MATLAB. This disconnect the handle to the serial port. Ensure to call everytime you establish a new connection.
    mexAtExit(TeensyDisconnect);
}