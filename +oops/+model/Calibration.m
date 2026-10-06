% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Calibration < handle
%CALIBRATION Project-owned four-angle input shared by group ID references.

    %% Identity and input source
    properties
        Name (1,1) string = "Calibration"
    end

    properties (SetAccess=private)
        ID (1,1) string = ""
        Input (:,1) matlabx.image.Image5D = matlabx.image.Image5D.empty(0,1)
        FrameLocations (4,3) double
    end

    %% Lifecycle
    methods

        function obj = Calibration(input,name)
        %CALIBRATION Validate the four-angle source without loading its full buffer.

            arguments
                input (1,1) matlabx.image.Image5D
                name (1,1) string = "Calibration"
            end
            obj.FrameLocations = oops.io.fourAngleLocations(input);
            obj.ID = matlabx.utils.text.uniqueID();
            obj.Input = input;
            obj.Name = name;
        end

        function delete(obj)
        %DELETE Release resident buffers when project ownership ends.

            % Unload the resident input buffer of each calibration being destroyed.
            for k = 1:numel(obj)

                if ~isempty(obj(k).Input)
                    obj(k).Input.unload();
                end

            end

        end

    end

end
