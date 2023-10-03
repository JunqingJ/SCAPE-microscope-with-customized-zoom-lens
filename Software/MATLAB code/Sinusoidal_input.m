CenterV=-0.02;
d = daqlist("ni");
deviceInfo = d{1, "DeviceInfo"};
dq = daq("ni");
dq.Rate = 2000;
addoutput(dq, "Dev2", "ao0", "Voltage");
outputSignal1 =centerV+0.5*sin((1:5000)*2*pi/5000);
start(dq,'repeatoutput');
write(dq,outputSignal1');