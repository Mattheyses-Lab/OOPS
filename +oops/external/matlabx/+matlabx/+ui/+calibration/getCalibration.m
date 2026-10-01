% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function cal = getCalibration(opts)

    arguments
        opts.ForceRecalibrate   (1,1) logical = false
        opts.uipanel            (1,1) logical = true
        opts.uifigure           (1,1) logical = true
    end
    
    persistent cachedCal
    
    if ~opts.ForceRecalibrate ...
            && ~isempty(cachedCal) ...
            && isvalid(cachedCal) ...
            && matlabx.ui.calibration.UICalibration.isStructValid(cachedCal.toStruct())
        cal = cachedCal;
        return
    end

    cachedCal = [];
    
    cached = matlabx.config.MachineState.get('UICalibration', []);
    
    if ~opts.ForceRecalibrate && ~isempty(cached) ...
            && matlabx.ui.calibration.UICalibration.isStructValid(cached)
    
        cal = matlabx.ui.calibration.UICalibration.fromStruct(cached);
        cachedCal = cal;
        return
    end
    
    cal = matlabx.ui.calibration.UICalibration();
    cal.calibrate( ...
        uipanel=opts.uipanel, ...
        uifigure=opts.uifigure ...
        );
    
    matlabx.config.MachineState.set('UICalibration', cal.toStruct());
    cachedCal = cal;
    
end
