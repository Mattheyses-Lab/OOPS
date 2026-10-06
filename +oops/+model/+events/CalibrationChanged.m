% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef CalibrationChanged < event.EventData
%CALIBRATIONCHANGED Report group assignments without retaining registry handles.

    %% Event payload
    properties (SetAccess=immutable)
        GroupID (1,1) string
        OldIDs (:,1) string
        NewIDs (:,1) string
    end

    %% Construction
    methods

        function obj = CalibrationChanged(groupID,oldIDs,newIDs)
        %CALIBRATIONCHANGED Capture a group's previous and new calibration IDs.

            obj.GroupID = groupID;
            obj.OldIDs = oldIDs;
            obj.NewIDs = newIDs;
        end

    end

end
