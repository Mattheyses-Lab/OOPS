% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef NavigationChanged < event.EventData
%NAVIGATIONCHANGED Describe ID state changes without carrying child handles.

    %% Event payload
    properties (SetAccess=immutable)
        Domain (1,1) string
        OwnerID (1,1) string
        Name (1,1) string
        OldIDs (:,1) string
        NewIDs (:,1) string
    end

    %% Construction
    methods

        function obj = NavigationChanged(domain,ownerID,name,oldIDs,newIDs)
        %NAVIGATIONCHANGED Preserve the owner and the previous/new ID values.

            obj.Domain = domain;
            obj.OwnerID = ownerID;
            obj.Name = name;
            obj.OldIDs = oldIDs;
            obj.NewIDs = newIDs;
        end

    end

end
