%%
% Start reading from DAQ (channel is AI0)
% This should be connected to the neurotar to start/stop TTL triggers
dq = daq("ni");
dq.Rate = 2000;
addinput(dq, "Dev1", "ai0", "Voltage");

% Pause until the 3.3V signal arrives in DAQ poer AI0
% Once the signal is raised fom 0V to 3.3V, we will continue and start
% capturing frames.
% Frames are captured continuously until we capture expected number of
% frames or a stop signal comes in on the daq

%dq.ScansAvailableFcn = @(src,evt) stopOnTTL(src, evt);

%%
fprintf('Waiting for TTL trigger on DAQ...\n');
start(dq, "continuous");

triggered = 0;
while triggered==0
    
    [data, timestamps, ~] = read(dq, dq.ScansAvailableFcnCount, "OutputFormat", "Matrix");

    if any(data >= 3.0)
        triggered = 1;
    end
end

% Wait for start trigger
fprintf('Triggered...\n');