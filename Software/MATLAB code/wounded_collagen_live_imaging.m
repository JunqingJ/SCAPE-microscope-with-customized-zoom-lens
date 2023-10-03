%% Parameter settings (From User input)
exposure=75;%in ms
scanstep=1.5;%in um
scanrange=350;%in um
Duration=24; %Total imaging time in hours
Interval=30; %every x minute for 1 volume
FileName='live_imaging3_DAPI\';

%% Parameter settings (Do not change)
TolV=Duration/(Interval/60)+1; %how many volumes to be acquired
centerV=-0.02;%in V, do not change unless microscope is re-calibrated
lagtime=2;%in ms
conversion=0.003184;%V/um
Offset=0.7;%V
V_step=scanstep*conversion;%Voltage increment needed for each step
StartPoint=centerV+Offset;
EndPoint=StartPoint-scanrange*conversion;
OutputSignal=StartPoint+2*V_step:-V_step:EndPoint-2*V_step;
%  STEP=0.0004*2;
%  StartPoint=-1.35;
%  EndPoint=-0.65;
%  OutputSignal=StartPoint:STEP:EndPoint;
fprintf('Total number of images: %d\n',length(OutputSignal));
mkdir(FileName);

%% Initiate NI DAQ communication

d = daqlist("ni");
deviceInfo = d{1, "DeviceInfo"};
dq = daq("ni");
dq.Rate = 3000;
addoutput(dq, "Dev2", "ao0", "Voltage");

%% Automated scanning
addpath('C:\Program Files\MATLAB\R2021a\toolbox\AndorSDK3')
addpath(convertStringsToChars("C:\Users\MoraesLab\OneDrive\Documents\MATLAB\"+string(FileName)))

N=1;
while N <= TolV
SubFile='Volume'+string(N-1);
mkdir(convertStringsToChars("C:\Users\MoraesLab\OneDrive\Documents\MATLAB\"+string(FileName)),SubFile)
write(dq,StartPoint);

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

filename = char("Volume"+string(N-1)+"_");
frameCount = double(length(OutputSignal));

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
    imwrite(buf2,"C:\Users\MoraesLab\OneDrive\Documents\MATLAB\"+FileName+SubFile+"\"+thisFilename) %saves to desinated directory

    i = i+1;
end
fprintf('Volume %d\n',N);
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
write(dq,1);
N=N+1;
if N > TolV
    break 
end
pause(Interval*60)
end
write(dq,centerV+Offset);