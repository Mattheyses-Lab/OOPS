% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function input = readInput(file,opts)
%READINPUT Open a lazy, file-backed four-angle input without changing intensities.

    arguments
        file (1,1) string
        opts.SeriesIndex (1,1) double {mustBeInteger,mustBePositive} = 1
    end
    try
        oops.Log.DEBUG("Opening four-angle input metadata: " + file);

        % Lazy Image5D source opened from the requested file and image series.
        input = matlabx.image.Image5D.fromFile(file,SeriesIndex=opts.SeriesIndex);
        oops.io.fourAngleLocations(input);
        oops.Log.DEBUG("Opened four-angle input: " + file);
    catch ME
        oops.Log.EXCEPTION(ME);
        rethrow(ME);
    end
end
