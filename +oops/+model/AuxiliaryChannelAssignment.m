% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef AuxiliaryChannelAssignment < handle
%AUXILIARYCHANNELASSIGNMENT Bind one source component to a semantic channel.

    properties (SetAccess=private)
        ChannelID (1,1) string = ""
        Input (1,1) matlabx.image.Image5D
        ComponentIndex (1,1) double {mustBeInteger,mustBePositive} = 1
        DisplayRange double = []
    end

    methods

        function obj = AuxiliaryChannelAssignment(channelID,input,componentIndex,displayRange)
        %AUXILIARYCHANNELASSIGNMENT Validate a single-plane scalar component.

            arguments
                channelID (1,1) string
                input (1,1) matlabx.image.Image5D
                componentIndex (1,1) double {mustBeInteger,mustBePositive}
                displayRange double = []
            end

            if componentIndex > input.NumComponents
                error('oops:model:InvalidAuxiliaryComponent', ...
                    'Component %d exceeds the source component count.',componentIndex);
            end

            component = input.getComponent(componentIndex);

            if ~component.IsScalar || component.SizeZ ~= 1 || component.SizeT ~= 1
                error('oops:model:InvalidAuxiliaryComponent', ...
                    'Auxiliary channels must be scalar components with one Z and T plane.');
            end

            if ~isempty(displayRange)
                validateattributes(displayRange,{'numeric'}, ...
                    {'real','finite','size',[1 2],'increasing'});
            end

            obj.ChannelID = channelID;
            obj.Input = input;
            obj.ComponentIndex = componentIndex;
            obj.DisplayRange = double(displayRange);
        end

        function delete(obj)
        %DELETE Release resident source pixels when an assignment is discarded.

            for k = 1:numel(obj)

                if ~isempty(obj(k).Input)
                    obj(k).Input.unload();
                end

            end
        end

        function values = getPlane(obj)
        %GETPLANE Read the assigned source component without retaining a full stack.

            values = obj.Input.getPlane(obj.ComponentIndex,1,1);
        end

        function setDisplayRange(obj,value)
        %SETDISPLAYRANGE Store image-local limits for this semantic channel.

            if isempty(value)
                obj.DisplayRange = [];
                return;
            end

            validateattributes(value,{'numeric'}, ...
                {'real','finite','size',[1 2],'increasing'});
            obj.DisplayRange = double(value);
        end

        function S = toStruct(obj,projectFolder)
        %TOSTRUCT Capture the semantic mapping and portable external source reference.

            S = struct( ...
                'ChannelID',obj.ChannelID, ...
                'Source',oops.io.project.sourceReference(obj.Input,projectFolder), ...
                'ComponentIndex',obj.ComponentIndex, ...
                'DisplayRange',obj.DisplayRange);
        end

    end

end
