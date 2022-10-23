function [AzimuthOrder,AzimuthAverage] = getAzimuthAverageUsingDipoles(azimuths)

    for i = 1:length(azimuths)
        %Make one dipole per azimuth, parallel with x-y plane
        Dipoles(i) = Dipole3(azimuths(i),90);
    end

    %PlotDipoles(gca,Dipoles);

    % simulate the order factor and azimuth of the dipoles
    [AzimuthOrder,AzimuthAverage] = SimulateOrderFactor3(Dipoles);

    % convert azimuth to degrees
    AzimuthAverage = rad2deg(AzimuthAverage);

    % rescale if necessary to fall in range [-90,90]
    if AzimuthAverage > 90
        AzimuthAverage = AzimuthAverage-180;
        disp("Greater than 90")
    end

end