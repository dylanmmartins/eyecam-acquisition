function stopOnTTL(src, ~)
%-------------------------------------------------------------------------%
% Scan 
%
%
% dq.ScansAvailableFcnCount = 500;
% dq.ScansAvailableFcn = @(src,evt) stopOnTTL(src,evt);
% start(dq, "continuous");
%   
%-------------------------------------------------------------------------%

% expects a signal to be 3.3 V so we will stop if it gets above 3 V
% https://www.mathworks.com/help/daq/acquire-continuous-and-background-data-using-ni-devices.html
    
    [data, ~, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");

   
    if any(data >= 3.0)

        disp('Detected high voltage on DAQ')

        stop(src)

    end

end