function [FrameRate, clock, exposure, gain, cam, img, ROI] = initializeCamera(RecordingLength, FrameRate, ClockRate, Exposure, Gain, SelectROI)
%   This script initializes the EyeTracking camera. Run this before you
%   trigger the recording via triggerCamera.
%
%   Inputs are all optional
%
%   Recording length is a length of time (in sec). try to be an integer
%
%   Based on Tyler Marks's uc480_net_saveAVI_fast.m script
%   Written by WTR 08/15/2022 // Last updated by WTR 08/15/2022
%
%   Rewritten 



%--------------------------------------------------------------------------
% Default values

% Frame rate in frames per second (FPS).
% The camera can go up to 180 FPS, but it requires the camera to downsample
% the image significantly.
if ~exist('FrameRate', 'var')
    FrameRate = 60;
end

% Set the rate that the camera sensor communication speed (in MHz)
% High value will result in more dropped frames
% Low value will limit how quickly the camera can aquire
% ClockRate = 35 is the max value for aquiring at 60 FPS
if ~exist('ClockRate', 'var')
    ClockRate = 30;
end

% Putative milliseconds
if ~exist('Exposure', 'var')
    Exposure = 5;
end

% Putative milliseconds
if ~exist('Gain', 'var')
    Gain = 350;
end

if ~exist('SelectROI', 'var')
    SelectROI = false;
end


%--------------------------------------------------------------------------
% Create a struct of parameters
params = struct;
params.FrameRate = FrameRate;
params.ClockRate = ClockRate;
params.RecordingLength = RecordingLength;
params.FrameLength



% Need to subsample the images if the frame rate is high.
if FrameRate==60
    doSubsample = True;
end

params.NumFrames = int(ceil(FrameRate*RecordingLength));


%--------------------------------------------------------------------------
% Camera initialization and setup

% Initialize the camera
fprintf('Initializing camera...\n');
asm = System.AppDomain.CurrentDomain.GetAssemblies;

% Read in the camera library
% This is the file: "uc480DotNet.dll"
path = untitled();
splitPath = split(path,'\');
basePath = join(splitPath(1:end-1),'\');
libraryPath = string(join([basePath 'uc480DotNet.dll'], '\'));

if ~any(arrayfun(@(n) strncmpi(char(asm.Get(n-1).FullName), ...
            'uc480DotNet', length('uc480DotNet')), 1:asm.Length))
    NET.addAssembly(libraryPath);
end

% Create camera object
cam = uc480.Camera;

% Open first available camera
if ~strcmp(char(cam.Init), 'SUCCESS')
    error('Could not initialize camera');
end

% Set subsampling
if doSubsample
    cam.Size.Subsampling.Set(uc480.Defines.SubsamplingMode.Horizontal2X)
    cam.Size.Subsampling.Set(uc480.Defines.SubsamplingMode.Horizontal2X)
end

% Set frame rate
cam.Timing.Framerate.Set(FrameRate);

% Set display mode to bitmap
if ~strcmp(char(cam.Display.Mode.Set(uc480.Defines.DisplayMode.DiB)), ...
        'SUCCESS')
    error('Could not set display mode');
end

% Set colormode to 8-bit RAW
if ~strcmp(char(cam.PixelFormat.Set(uc480.Defines.ColorMode.SensorRaw8)), ...
        'SUCCESS')
    error('Could not set pixel format');
end

% Set trigger mode to software (single image acquisition)
if ~strcmp(char(cam.Trigger.Set(uc480.Defines.TriggerMode.Software)), 'SUCCESS')
    error('Could not set trigger format');
end

% Remaining parameters
cam.Timing.PixelClock.Set(clock);
cam.Timing.Exposure.Set(exposure);
cam.Gain.Hardware.Boost.SetEnable(true);
cam.Gain.Hardware.Factor.SetMaster(gain);


%--------------------------------------------------------------------------
% Take test image to confirm camera initialization
fprintf('Testing image acquisition...\n');

% Allocate image memory
[ErrChk, initID] = cam.Memory.Allocate(true);
if ~strcmp(char(ErrChk), 'SUCCESS')
    error('Could not allocate memory');
end

% Obtain image information
[ErrChk, img.Width, img.Height, img.Bits, img.Pitch] ...
    = cam.Memory.Inquire(initID);
if ~strcmp(char(ErrChk), 'SUCCESS')
    error('Could not get image information');
end

% Acquire image
if ~strcmp(char(cam.Acquisition.Freeze(true)), 'SUCCESS')
    cam.Exit
    error('Could not acquire image');
end

% Extract image
[ErrChk, tmp] = cam.Memory.CopyToArray(initID);
if ~strcmp(char(ErrChk), 'SUCCESS')
    error('Could not obtain image data');
end

% Reshape image
testimage = reshape(uint8(tmp), [img.Width, img.Height, img.Bits/8]);
testimage = imrotate(testimage, -90);

% Draw image and ROI
if (SelectROI==true)
    fprintf('Draw ROI...\n');
    himg = imshow(testimage, 'Border', 'tight');
    rect = imrect;
    ROI = rect.getPosition;
    close
end

end