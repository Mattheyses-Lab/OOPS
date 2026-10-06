% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) ActiveImageChanged < event.EventData

    %% Event payload
    properties (SetAccess=private)
        NewID string
        OldID string
    end

    %% Construction
    methods

        function obj = ActiveImageChanged(newID, oldID)
        %ACTIVEIMAGECHANGED Construct the domain event identity payload.

            obj.NewID = newID;
            obj.OldID = oldID;
        end

    end

end
