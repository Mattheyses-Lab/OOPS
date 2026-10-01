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

function sc = getScreenCenter(units)
%GETSCREENCENTER Returns center (x,y) of usable area of screen in pixels

    arguments
        units (1,:) char {mustBeMember(units,{'pixels','inches','points'})} = 'pixels'
    end

    UIcal = matlabx.UICal.get();
    
    left = UIcal.uifigureMaximizedOuterPositionLeftPx;
    bottom = UIcal.uifigureMaximizedOuterPositionBottomPx;
    width = UIcal.uifigureMaximizedOuterPositionWidthPx;
    height = UIcal.uifigureMaximizedOuterPositionHeightPx;
    
    sc = [left + width/2, bottom + height/2];
    
    switch units
        case 'pixels'
            return
        case 'inches'
            sc = sc / UIcal.PixelsPerInch;
        case 'points'
            sc = sc / UIcal.PixelsPerPoint;
    end

end