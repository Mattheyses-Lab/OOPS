% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) GroupAdded < event.EventData

    %% Event payload
    properties (SetAccess=private)
        GroupID string
    end

    %% Construction
    methods

        function obj = GroupAdded(groupID)
        %GROUPADDED Construct the domain event identity payload.

            obj.GroupID = groupID;
        end

    end

end
