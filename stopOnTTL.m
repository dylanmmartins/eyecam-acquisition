function stopOnTTL(src, ~)
% expects a signal to be 3.3 V so we will stop if it gets above 3 V
% https://www.mathworks.com/help/daq/acquire-continuous-and-background-data-using-ni-devices.html
    [data, ~, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
    % ^ second arg here can be changed back to "timestamps" if you want to
    % plot live
   
    if any(data >= 3.0)
        disp('Detected high voltage on DAQ')
        % stop continuous acquisitions explicitly
        stop(src)
        %plot(timestamps, data)
        %daqTrig = 1;
    end

end