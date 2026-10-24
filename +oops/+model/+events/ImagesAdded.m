% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) ImagesAdded < event.EventData

    %% Event payload
    properties (SetAccess=private)
        ImageIDs (:,1) string
        GroupID string
    end

    %% Construction
    methods

        function obj = ImagesAdded(imageIDs,groupID)
        %IMAGESADDED Construct the aggregate domain event identity payload.

            obj.ImageIDs = string(imageIDs(:));
            obj.GroupID = groupID;
        end

    end

end
