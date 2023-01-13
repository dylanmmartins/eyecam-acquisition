function [FrameRate, clock, exposure, gain, stimulus, cam, img, ROI] = initializeCamera(set_frate, stim_name)
%-------------------------------------------------------------------------%
%   This script initializes the EyeTracking camera. Run this before you
%   trigger the recording via triggerCamera.
%
%   Based on Tyler Marks's uc480_net_saveAVI_fast.m script.
%
%   Written by WTR 08/15/2022 // Last updated by WTR 08/15/2022
%-------------------------------------------------------------------------%
%% Camera settings
% Set frame rate of camera. You may need to change the pixel clock for
% faster framerates.
FrameRate = set_frate;                     %frames per second. WARNING: for higher exposure times, framerate needs to be decreased to be accurate. 10 fps should be sufficient for most settings.                   
clock = 30;                         %higher values may result in more dropped frames. Beyond 35 sees a significant increase in this number
exposure = 5;                       %putative milliseconds
gain = 400;                         %higher values don't work. Maximum has not been empirically tested. 400 should work. 300 definitely works. 
stimulus = stim_name;

%% Camera initialization and setup
fprintf('Initializing camera...\n');
%   Add NET assembly if it does not exist
%   May need to change specific location of library
asm = System.AppDomain.CurrentDomain.GetAssemblies;
if ~any(arrayfun(@(n) strncmpi(char(asm.Get(n-1).FullName), ...
        'uc480DotNet', length('uc480DotNet')), 1:asm.Length))
    NET.addAssembly(...
        'C:\Users\Goard Lab\Dropbox\Dylan\Eyetracking\uc480DotNet.dll');%'D:\Tyler\Eyetracking\DCx_Camera_Interfaces_2018_09\DCx_Camera_SDK\Develop\DotNet\uc480DotNet.dll');
end
%   Create camera object handle
cam = uc480.Camera;
%   Open 1st available camera
%   Returns if unsuccessful
if ~strcmp(char(cam.Init), 'SUCCESS') %if ~strcmp(char(cam.Init(0)), 'SUCCESS') CHANGED WTR 08/09/2022
    error('Could not initialize camera');
end
%   Set display mode to bitmap (DiB)
if ~strcmp(char(cam.Display.Mode.Set(uc480.Defines.DisplayMode.DiB)), ...
        'SUCCESS')
    error('Could not set display mode');
end
%   Set colormode to 8-bit RAW
if ~strcmp(char(cam.PixelFormat.Set(uc480.Defines.ColorMode.SensorRaw8)), ...
        'SUCCESS')
    error('Could not set pixel format');
end
%   Set trigger mode to software (single image acquisition)
if ~strcmp(char(cam.Trigger.Set(uc480.Defines.TriggerMode.Software)), 'SUCCESS')
    error('Could not set trigger format');
end
cam.Timing.PixelClock.Set(clock);
cam.Timing.Exposure.Set(exposure);
cam.Gain.Hardware.Boost.SetEnable(true);
cam.Gain.Hardware.Factor.SetMaster(gain);

%% Take test image to confirm camera initialization
fprintf('Testing image acquisition...\n');
%   Allocate image memory
[ErrChk, initID] = cam.Memory.Allocate(true);
if ~strcmp(char(ErrChk), 'SUCCESS')
    error('Could not allocate memory');
end
%   Obtain image information
[ErrChk, img.Width, img.Height, img.Bits, img.Pitch] ...
    = cam.Memory.Inquire(initID);
if ~strcmp(char(ErrChk), 'SUCCESS')
    error('Could not get image information');
end
%   Acquire image
if ~strcmp(char(cam.Acquisition.Freeze(true)), 'SUCCESS')
    cam.Exit
    error('Could not acquire image');
end
%   Extract image
[ErrChk, tmp] = cam.Memory.CopyToArray(initID);
if ~strcmp(char(ErrChk), 'SUCCESS')
    error('Could not obtain image data');
end
%   Reshape image
testimage = reshape(uint8(tmp), [img.Width, img.Height, img.Bits/8]);
testimage = imrotate(testimage, -90);

%   Draw image and ROI
fprintf('Draw ROI...\n');
himg = imshow(testimage, 'Border', 'tight');
rect = imrect;
ROI = rect.getPosition;
close

% cam.Trigger.Set(uc480.Defines.TriggerMode.Hi_Lo_Sync);

end