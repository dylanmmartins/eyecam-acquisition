%%

dq = daq("ni");
dq.Rate = 2000;
addinput(dq, "Dev1", "ai0", "Voltage");
start(dq, "continuous");

[data, timestamps, ~] = read(dq, 50000, "OutputFormat", "Matrix");