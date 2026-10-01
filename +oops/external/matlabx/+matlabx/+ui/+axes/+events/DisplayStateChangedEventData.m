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

classdef (ConstructOnLoad) DisplayStateChangedEventData < event.EventData
    %DISPLAYSTATECHANGEDEVENTDATA Payload for ImageAxes display-state changes.
    %
    %   This event data is intentionally small. It identifies which
    %   display-facing property changed and, when known, which component
    %   indices were affected. Listeners that need complete current state
    %   should query the ImageAxes object when they receive the event.

    properties
        Property string = ""
        ComponentIdx double = []
        PreviousValue = []
        CurrentValue = []
        Origin string = "ImageAxes"
    end

    methods
        function data = DisplayStateChangedEventData(opts)
            %DISPLAYSTATECHANGEDEVENTDATA Construct display-state event data.
            arguments
                opts.Property string = ""
                opts.ComponentIdx double = []
                opts.PreviousValue = []
                opts.CurrentValue = []
                opts.Origin string = "ImageAxes"
            end

            data.Property = opts.Property;
            data.ComponentIdx = opts.ComponentIdx;
            data.PreviousValue = opts.PreviousValue;
            data.CurrentValue = opts.CurrentValue;
            data.Origin = opts.Origin;
        end
    end
end
