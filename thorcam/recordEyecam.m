fun
%%

rec_minutes = 5;

[cam, params] = initializeCamera(5*60);

recording_length = 5*60; % seconds of recording
frames = recording_length*FrameRate;

triggerCamera(cam, params);

cam.Exit;
clear;
