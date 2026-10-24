% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) ImagesRemoved < event.EventData

    %% Event payload
    properties (SetAccess=private)
        ImageIDs (:,1) string
        GroupID string
    end

    %% Construction
    methods

        function obj = ImagesRemoved(imageIDs,groupID)
        %IMAGESREMOVED Construct the aggregate domain event identity payload.

            obj.ImageIDs = string(imageIDs(:));
            obj.GroupID = groupID;
        end

    end

end
