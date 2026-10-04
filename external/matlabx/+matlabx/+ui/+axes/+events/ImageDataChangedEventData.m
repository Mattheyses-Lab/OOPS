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

classdef (ConstructOnLoad) ImageDataChangedEventData < event.EventData
    %IMAGEDATACHANGEDEVENTDATA Payload for ImageAxes ImageData changes.
    %
    %   The payload is deliberately compact for now. It gives listeners a
    %   cheap way to detect image-shape/component-count changes while still
    %   leaving room for richer metadata later.

    properties
        PreviousNumComponents double = []
        CurrentNumComponents double = []
        PreviousSize double = []
        CurrentSize double = []
        Origin string = "ImageAxes"
    end

    methods
        function data = ImageDataChangedEventData(opts)
            %IMAGEDATACHANGEDEVENTDATA Construct image-data event data.
            arguments
                opts.PreviousNumComponents double = []
                opts.CurrentNumComponents double = []
                opts.PreviousSize double = []
                opts.CurrentSize double = []
                opts.Origin string = "ImageAxes"
            end

            data.PreviousNumComponents = opts.PreviousNumComponents;
            data.CurrentNumComponents = opts.CurrentNumComponents;
            data.PreviousSize = opts.PreviousSize;
            data.CurrentSize = opts.CurrentSize;
            data.Origin = opts.Origin;
        end
    end
end
