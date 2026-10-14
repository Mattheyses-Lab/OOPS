% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef AuxiliaryChannelDefinition < handle
%AUXILIARYCHANNELDEFINITION Project-wide semantic identity for an extra channel.

    properties (SetAccess=private)
        ID (1,1) string = ""
        Name (1,1) string = "Channel"
        Color (1,3) double {mustBeFinite,mustBeInRange(Color,0,1)} = [1 1 1]
    end

    methods

        function obj = AuxiliaryChannelDefinition(name,color,id)
        %AUXILIARYCHANNELDEFINITION Construct a stable semantic channel identity.

            arguments
                name (1,1) string
                color (1,3) double {mustBeFinite,mustBeInRange(color,0,1)}
                id (1,1) string = matlabx.utils.text.uniqueID()
            end

            name = strtrim(name);

            if name == ""
                error('oops:model:EmptyChannelName', ...
                    'Auxiliary channel names cannot be empty.');
            end

            obj.ID = id;
            obj.Name = name;
            obj.Color = color;
        end

        function S = toStruct(obj)
        %TOSTRUCT Capture the persistent semantic identity and display color.

            S = struct('ID',obj.ID,'Name',obj.Name,'Color',obj.Color);
        end

    end

    methods (Static)

        function obj = fromStruct(S)
        %FROMSTRUCT Restore a channel definition from a project snapshot.

            obj = oops.model.AuxiliaryChannelDefinition( ...
                string(S.Name),double(S.Color),string(S.ID));
        end

    end

end
