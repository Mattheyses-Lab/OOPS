% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) ObjectsChanged < event.EventData

    %% Event payload
    properties (SetAccess=private)
        ImageID string
        NewIDs string
        OldIDs string
    end

    %% Construction
    methods

        function obj = ObjectsChanged(imageID, newIDs, oldIDs)
        %OBJECTSCHANGED Construct the domain event identity payload.

            obj.ImageID = imageID;
            obj.NewIDs = newIDs;
            obj.OldIDs = oldIDs;
        end

    end

end
