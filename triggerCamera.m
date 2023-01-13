function [] = triggerCamera(FrameRate, recording_length, clock, exposure, gain, frames, stimulus, cam, ROI, testimg)
%-------------------------------------------------------------------------%
%   This script triggerts the EyeTracking camera. Run this after you
%   initialize the camera via initializeCamera.
%
%   Based on Tyler Marks's uc480_net_saveAVI_fast.m script.
%
%   Written by WTR 08/15/2022 // Last updated by WTR 08/15/2022
%-------------------------------------------------------------------------%

%% Recording setup
fprintf('Allocating memory for all frames...\n');
%allocate image memory ids for entire recording
for ii = 1:frames
    if mod(ii, 500) == 0
        fprintf('Frame progress: %d\n', ii);
    end
    [~, img.ID(ii)] = cam.Memory.Allocate(true);
end

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
fprintf('Waiting for TTL trigger on DAQ...\n');
dq.ScansAvailableFcnCount = 500;
dq.ScansAvailableFcn = @(src,evt) stopOnTTL(src,evt);
start(dq, "continuous");

while dq.Running
    pause(0.001);
end

% Then, restart and stop aquiring frames as soon as voltage is raised on
% TTL again to signal end of neurotar recording.
%dq.ScansAvailableFcn = @(src,evt) stopOnTTL(src, evt);
recording_time_total = 0;
loop_broken = 0;

startstamp = sprintf('Beginning image acquisition: %s\n', datestr(now, 'HH:MM:SS.FFF'));
for n=1:frames

    startacq = tic;
    % Set active memory index
    cam.Memory.SetActive(n);

    % Acquire image using current memory index
    cam.Acquisition.Freeze(true);

    %control loop execution timing to keep in sync with recording and achieve proper framerate
    while toc(startacq) < (1/FrameRate)
    end
    
    toc(startacq)

    if recording_time_total >= recording_length
        total_frames_collected = n;
        loop_broken = 1;
        break
    end

    recording_time_total = recording_time_total + toc(startacq);
end

endstamp = sprintf('Ending image acquisition: %s\n', datestr(now, 'HH:MM:SS.FFF'));
fprintf(endstamp)
if loop_broken == 0
    total_frames_collected = frames;
end

%% Write images to AVI
fprintf('Extracting data and writing to .avi file. This may take a while...\n');
%   Make VideoWriter
totalmovies = length(dir('*.avi'));
videotitle = sprintf('%s-EyeTracking-%s-%dfps-%fexp-%dclock-%dgain-%d.avi', datestr(now, 'yyyy-mm-dd'),...
    stimulus, FrameRate, exposure, clock, gain, totalmovies+1);
videoObj = VideoWriter(videotitle);
videoObj.FrameRate = FrameRate;

% Open VideoWriter
open(videoObj);

for kk = 1:total_frames_collected
    if mod(kk, 500) == 0
        fprintf('Frame progress: %d%%\n', round((kk/total_frames_collected)*100));
    end
    [~, currByte] = cam.Memory.CopyToArray(img.ID(kk));
    image = reshape(uint8(currByte), [testimg.Width, testimg.Height, testimg.Bits/8]);
    image = imrotate(image, -90);
    %Save Frame to Video
    writeVideo(videoObj,image(ROI(2):ROI(2)+ROI(4), ROI(1):ROI(1)+ROI(3)));
end
%   Close VideoWriter
close(videoObj);
fprintf('Movie successfully saved. Closing camera.\n');
%% Close camera
if ~strcmp(char(cam.Exit), 'SUCCESS')
    error('Could not close camera');
end

%% Save timestamps
Timing.startstamp = startstamp;
Timing.endstamp = endstamp;
Timing.total_frames_collected = total_frames_collected;
Timing.loop_broken = loop_broken;
Timing.recording_time_total = recording_time_total;
Timing.recording_length = recording_length;
Timing.expected_frames = frames;

save(sprintf('%s-Timing.mat', videotitle(1:end-4)), 'Timing')

end