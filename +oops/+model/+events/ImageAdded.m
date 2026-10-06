% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) ImageAdded < event.EventData

    %% Event payload
    properties (SetAccess=private)
        ImageID string
        GroupID string
    end

    %% Construction
    methods

        function obj = ImageAdded(imageID, groupID)
        %IMAGEADDED Construct the domain event identity payload.

            obj.ImageID = imageID;
            obj.GroupID = groupID;
        end

    end

end
