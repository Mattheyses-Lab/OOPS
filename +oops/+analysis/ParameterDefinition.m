% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ParameterDefinition
%PARAMETERDEFINITION Metadata describing one algorithm-specific parameter.

    properties (SetAccess=private)
        Name (1,1) string = "" % Stable field name used in parameter value structures.
        Label (1,1) string = "" % Human-readable name displayed in the interface.
        Default = [] % Catalog-defined value used before later layers provide one.
        Limits (1,:) double = double.empty(1,0) % Optional numeric lower and upper bounds.
        Adjustable (1,1) logical = false % Whether users may override the effective value.
    end

    methods

        function obj = ParameterDefinition(opts)
        %PARAMETERDEFINITION Validate and store parameter metadata.

            arguments
                opts.Name (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.Default = []
                opts.Limits (1,:) double = double.empty(1,0)
                opts.Adjustable (1,1) logical = false
            end

            if ~isempty(opts.Limits) && numel(opts.Limits) ~= 2
                error('oops:analysis:InvalidParameterLimits', ...
                    'Parameter limits must be empty or contain [minimum maximum].');
            end

            if numel(opts.Limits) == 2 && opts.Limits(1) > opts.Limits(2)
                error('oops:analysis:InvalidParameterLimits', ...
                    'A parameter minimum cannot exceed its maximum.');
            end

            obj.Name = opts.Name;
            obj.Label = opts.Label;
            obj.Default = opts.Default;
            obj.Limits = opts.Limits;
            obj.Adjustable = opts.Adjustable;
        end

    end
end
