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

function out = niceLimitsAndTicks(dataLim,opts)
%NICELIMITSANDTICKS Compute readable axes limits/ticks with optional headroom.
%
% out = matlabx.ui.niceLimitsAndTicks(dataLim)
% out = matlabx.ui.niceLimitsAndTicks(dataLim,Name=Value)
%
% Returns clean tick limits around dataLim, plus optional display limits that
% reserve extra space above the final tick without adding misleading ticks.

arguments
    dataLim (1,2) double
    opts.TargetTicks (1,1) double {mustBeInteger,mustBePositive} = 5
    opts.IncludeZero (1,1) logical = false
    opts.PaddingFraction (1,1) double {mustBeNonnegative} = 0
    opts.ExtendTopFraction (1,1) double {mustBeNonnegative} = 0
end
    
    dataLim = sort(dataLim);
    
    if any(isnan(dataLim)) || any(isinf(dataLim))
        error("matlabx:ui:niceLimitsAndTicks:InvalidLimits", ...
            "dataLim must contain finite numeric values.");
    end
    
    if dataLim(1) == dataLim(2)
        if dataLim(1) == 0
            dataLim = [-0.5 0.5];
        else
            delta = abs(dataLim(1))*0.1;
            dataLim = dataLim + [-delta delta];
        end
    end
    
    if opts.IncludeZero
        dataLim(1) = min(dataLim(1),0);
        dataLim(2) = max(dataLim(2),0);
    end
    
    dataSpan = diff(dataLim);
    if opts.PaddingFraction > 0
        dataLim = dataLim + dataSpan*opts.PaddingFraction*[-1 1];
    end
    
    tickSpan = diff(dataLim);
    rawStep = tickSpan / max(opts.TargetTicks - 1,1);
    tickStep = localNiceStep(rawStep);
    
    tickLim = [
        floor(dataLim(1)/tickStep)*tickStep, ...
        ceil(dataLim(2)/tickStep)*tickStep];
    
    ticks = tickLim(1):tickStep:tickLim(2);
    
    % Avoid tiny floating-point grit in display labels.
    precision = max(0,ceil(-log10(tickStep)) + 2);
    ticks = round(ticks,precision);
    tickLim = round(tickLim,precision);
    
    displayLim = tickLim;
    if opts.ExtendTopFraction > 0
        displaySpan = diff(tickLim);
        displayLim(2) = tickLim(2) + displaySpan*opts.ExtendTopFraction;
        displayLim = round(displayLim,precision);
    end
    
    out = struct( ...
        "DataLim",dataLim, ...
        "TickLim",tickLim, ...
        "DisplayLim",displayLim, ...
        "Ticks",ticks, ...
        "TickStep",tickStep);
end


function step = localNiceStep(rawStep)
%LOCALNICESTEP Round a raw step to a readable 1/2/2.5/5/10 x 10^n step.
    
    if rawStep <= 0 || ~isfinite(rawStep)
        step = 1;
        return
    end
    
    exponent = floor(log10(rawStep));
    fraction = rawStep / 10^exponent;
    
    niceFractions = [1 2 2.5 5 10];
    idx = find(fraction <= niceFractions,1,"first");
    if isempty(idx)
        idx = numel(niceFractions);
    end
    
    step = niceFractions(idx) * 10^exponent;
end