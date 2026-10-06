% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) ImageRemoved < event.EventData

    %% Event payload
    properties (SetAccess=private)
        ImageID string
        GroupID string
    end

    %% Construction
    methods

        function obj = ImageRemoved(imageID, groupID)
        %IMAGEREMOVED Construct the domain event identity payload.

            obj.ImageID = imageID;
            obj.GroupID = groupID;
        end

    end

end
