%% Parameter settings (From User input)
exposure=100;%in ms
scanstep=2;%in um
scanrange=250;%in um (maximum is 350-400)
FolderName='TW1_Ecad\';

%% Parameter settings (Do not change)
centerV=-0.02;%in V, do not change unless microscope is re-calibrated
lagtime=2;%in ms
conversion=0.003184;%V/um
Offset=0.5;%V
V_step=scanstep*conversion;%Voltage increment needed for each step
StartPoint=centerV+Offset;
EndPoint=StartPoint-scanrange*conversion;
OutputSignal=StartPoint+2*V_step:-V_step:EndPoint-2*V_step;
%  STEP=0.0004*2;
%  StartPoint=-1.35;
%  EndPoint=-0.65;
%  OutputSignal=StartPoint:STEP:EndPoint;
fprintf('Total number of images: %d\n',length(OutputSignal));
mkdir(FolderName);

%% Initiate NI DAQ communication

d = daqlist("ni");
deviceInfo = d{1, "DeviceInfo"};
dq = daq("ni");
dq.Rate = 3000;
addoutput(dq, "Dev2", "ao0", "Voltage");
write(dq,StartPoint);

%% Automated scanning
addpath('C:\Program Files\MATLAB\R2021a\toolbox\AndorSDK3')
disp('Andor SDK3 Kinetic Series Example');
[rc] = AT_InitialiseLibrary();
AT_CheckError(rc);
[rc,hndl] = AT_Open(0);
AT_CheckError(rc);
disp('Camera initialized');
[rc] = AT_SetFloat(hndl,'ExposureTime',exposure/1000);
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'CycleMode','Fixed');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'TriggerMode','Internal');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'SimplePreAmpGainControl','16-bit (low noise & high well capacity)');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'PixelEncoding','Mono16');
AT_CheckWarning(rc);


prompt = {'Enter Acquisition name','Enter number of images'};
dlg_title = 'Configure acquisition';
num_lines = 1;
def = {'acquisition','10'};
answer = inputdlg(prompt,dlg_title,num_lines,def);


filename = cell2mat(answer(1));
frameCount = str2double(cell2mat(answer(2)));

[rc] = AT_SetInt(hndl,'FrameCount',frameCount);
AT_CheckWarning(rc);

[rc,imagesize] = AT_GetInt(hndl,'ImageSizeBytes');
AT_CheckWarning(rc);
[rc,height] = AT_GetInt(hndl,'AOIHeight');
AT_CheckWarning(rc);
[rc,width] = AT_GetInt(hndl,'AOIWidth');  
AT_CheckWarning(rc);
[rc,stride] = AT_GetInt(hndl,'AOIStride'); 
AT_CheckWarning(rc);
for X = 1:10
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
end
disp('Starting acquisition...');
[rc] = AT_Command(hndl,'AcquisitionStart');
AT_CheckWarning(rc);

i=0;
while(i<frameCount)
    % Move Galvo to target position
    write(dq, OutputSignal(i+1));
    pauses(lagtime/1000);
    
    % Capture image
    [rc,buf] = AT_WaitBuffer(hndl,1000);
    AT_CheckWarning(rc);
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
    [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    AT_CheckWarning(rc);
    
    thisFilename = strcat(filename, num2str(i+1), '.tiff');
    disp(['Writing Image ', num2str(i+1), '/',num2str(frameCount),' to disk']);
    imwrite(buf2,"C:\Users\MoraesLab\OneDrive\Documents\MATLAB\"+FolderName+thisFilename) %saves to desinated directory

    i = i+1;
end
disp('Acquisition complete');
[rc] = AT_Command(hndl,'AcquisitionStop');
AT_CheckWarning(rc);
[rc] = AT_Flush(hndl);
AT_CheckWarning(rc);
[rc] = AT_Close(hndl);
AT_CheckWarning(rc);
[rc] = AT_FinaliseLibrary();
AT_CheckWarning(rc);
disp('Camera shutdown');
write(dq,centerV+Offset);