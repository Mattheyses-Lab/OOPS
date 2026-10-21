% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ChannelDefinition < handle
%CHANNELDEFINITION Project-wide semantic identity shared by image channels.

    properties (SetAccess=private)
        ID (1,1) string = ""
        Name (1,1) string = "Channel"
        Color (1,3) double {mustBeFinite,mustBeInRange(Color,0,1)} = [1 1 1]
        IsPrimary (1,1) logical = false
        IsAuxiliary (1,1) logical = false
    end

    methods

        function obj = ChannelDefinition(name,color,id,roles)
        %CHANNELDEFINITION Construct a stable semantic channel identity.

            arguments
                name (1,1) string
                color (1,3) double {mustBeFinite,mustBeInRange(color,0,1)}
                id (1,1) string = matlabx.utils.text.uniqueID()
                roles (:,1) string = strings(0,1)
            end

            name = strtrim(name);

            if name == ""
                error('oops:model:EmptyChannelName', ...
                    'Channel names cannot be empty.');
            end

            obj.ID = id;
            obj.Name = name;
            obj.Color = color;
            obj.IsPrimary = any(strcmpi(roles,"Primary"));
            obj.IsAuxiliary = any(strcmpi(roles,"Auxiliary"));
        end

        function markPrimary(obj)
        %MARKPRIMARY Record use as a required polarization-input identity.

            obj.IsPrimary = true;
        end

        function markAuxiliary(obj)
        %MARKAUXILIARY Record use in optional single-plane channel assignments.

            obj.IsAuxiliary = true;
        end

        function S = toStruct(obj)
        %TOSTRUCT Capture the persistent semantic identity and display color.

            S = struct( ...
                'ID',obj.ID,'Name',obj.Name,'Color',obj.Color, ...
                'IsPrimary',obj.IsPrimary,'IsAuxiliary',obj.IsAuxiliary);
        end

    end

    methods (Static)

        function obj = fromStruct(S)
        %FROMSTRUCT Restore a channel definition from a project snapshot.

            roles = strings(0,1);

            if logical(S.IsPrimary)
                roles(end+1,1) = "Primary";
            end

            if logical(S.IsAuxiliary)
                roles(end+1,1) = "Auxiliary";
            end

            obj = oops.model.ChannelDefinition( ...
                string(S.Name),double(S.Color),string(S.ID),roles);
        end

    end

end
