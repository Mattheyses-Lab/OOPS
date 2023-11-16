function plotMarkers = getPlotMarkers(nMarkers)
%%  GETPLOTMARKERS returns a cell array of plot marker symbols
%
%   INPUT:
%       nMarkers | (1,1) double | the number of plot marker symbols to return (cannot exceed 14)
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    % cell array of char vectors for each possible plot marker
    allMarkers = {...
        'o',... % circle
        's',... % square
        '^',... % upward-pointing triangle
        'h',... % hexagram
        'p',... % pentagram
        'd',... % diamond
        'v',... % downward-pointing triangle
        '>',... % right-pointing triangle
        '<',... % left-pointing triangle
        '+',... % plus sign
        '*',... % asterisk
        'x',... % cross
        '_',... % horizontal line
        '|'...  % vertical line
        };

    % throw error if too many plot markers requested
    if nMarkers > numel(allMarkers)
        error('getPlotMarkers:invalidInput','nMarkers can not be greater than 14')
    end

    % return cell array containing the requested number of plot markers
    plotMarkers = allMarkers(1:nMarkers);

end