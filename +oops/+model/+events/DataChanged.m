% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef (ConstructOnLoad) DataChanged < event.EventData

    %% Event payload
    properties (SetAccess=private)
        ImageID (1,1) string
        Name (1,1) string
        ObjectID (1,1) string = ""
    end

    %% Construction
    methods

        function obj = DataChanged(imageID,name,objectID)
        %DATACHANGED Identify the changed data and an optional owning object.

            obj.ImageID = imageID;
            obj.Name = name;

            if nargin >= 3
                obj.ObjectID = objectID;
            end

        end

    end

end
