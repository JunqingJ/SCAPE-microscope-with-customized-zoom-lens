d = daqlist("ni");
offset=0.45;
centerV=-0.02;
deviceInfo = d{1, "DeviceInfo"};
dq = daq("ni");
dq.Rate = 1000;
addoutput(dq, "Dev2", "ao0", "Voltage");
write(dq,centerV);% Use this for general purposes
%write(dq,centerV=offset);% Use this before acquisition
display('Galvo setup successfully');