
%%

[FrameRate, clock, exposure, gain, stimulus, cam, img, ROI] = initializeCamera(20, 'NeurotarEyecam');

%%
recording_length = 5*60; % seconds of recording
frames = recording_length*FrameRate;

triggerCamera(FrameRate, recording_length, clock, exposure, 300, frames, stimulus, cam, ROI, img);

%% 

cam.Exit;
clear;