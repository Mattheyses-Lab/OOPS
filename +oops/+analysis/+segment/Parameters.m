% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Parameters
%PARAMETERS Durable inputs controlling one segmentation algorithm run.
% Catalog defaults, image-derived automatic choices, and explicit user
% overrides remain separate so the effective values and their origin are clear.

    properties (SetAccess=private)
        Algorithm (1,1) string = "Puncta/1" % Versioned identifier of the selected segmentation algorithm.
        Filtering (1,1) struct = struct() % Algorithm-independent object-filtering values.
        Defaults (1,1) struct = struct() % Starting values declared by the algorithm definition.
        Automatic (1,1) struct = struct() % Image-dependent values selected by the original algorithm run.
        Manual (1,1) struct = struct() % Explicit user overrides applied after automatic selection.
    end

    properties (Dependent, SetAccess=private)
        Values % Effective algorithm values after applying defaults, automatic choices, and manual overrides.
        Mode % Whether the effective values include any manual overrides.
    end

    methods

        function obj = Parameters(settings)
        %PARAMETERS Capture filtering values and catalog defaults for an algorithm.

            if nargin == 0
                settings = oops.config.Segmentation();
            end

            % Catalog metadata supplying defaults for the selected algorithm.
            definition = oops.analysis.segment.algorithms(settings.Algorithm);
            obj.Algorithm = definition.ID;

            % Post-segmentation component filtering shared by every algorithm.
            obj.Filtering = rmfield(settings.toStruct(),'Algorithm');
            obj.Filtering.Ranking = "MeanIntensity";

            % Catalog-defined starting values keyed by parameter name.
            parameters = definition.ParameterDefinitions;

            for k = 1:numel(parameters)
                obj.Defaults.(parameters(k).Name) = parameters(k).Default;
            end

        end

        function values = get.Values(obj)
        %GET.VALUES Resolve effective values in increasing order of precedence.

            values = obj.mergeValues(obj.Defaults,obj.Automatic);
            values = obj.mergeValues(values,obj.Manual);
        end

        function mode = get.Mode(obj)
        %GET.MODE Report whether explicit user overrides are currently active.

            if isempty(fieldnames(obj.Manual))
                mode = "Automatic";
            else
                mode = "Manual";
            end
        end

        function obj = withAutomatic(obj,values)
        %WITHAUTOMATIC Record image-derived values without changing manual overrides.

            obj.Automatic = values;
        end

        function obj = withParameter(obj,name,value)
        %WITHPARAMETER Validate and store one explicit user override.

            % Algorithm metadata used to validate the requested adjustable parameter.
            definition = oops.analysis.segment.algorithms(obj.Algorithm);

            % Parameter definition matching the requested name and its allowed range.
            parameter = definition.ParameterDefinitions;

            if ~isempty(parameter)
                parameter = parameter([parameter.Name] == string(name));
            end

            if isempty(parameter) || ~parameter.Adjustable
                error('oops:analysis:UnknownParameter', ...
                    'Parameter %s is not adjustable for %s.',name,obj.Algorithm);
            end

            validateattributes(value,{'double'}, ...
                {'scalar','real','finite','>=',parameter.Limits(1), ...
                '<=',parameter.Limits(2)});
            obj.Manual.(name) = value;
        end

        function obj = resetToAutomatic(obj)
        %RESETTOAUTOMATIC Clear overrides while preserving automatic values.

            obj.Manual = struct();
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize the parameter layers without dependent values.

            S = struct('Algorithm',obj.Algorithm, ...
                'Filtering',obj.Filtering, ...
                'Defaults',obj.Defaults, ...
                'Automatic',obj.Automatic, ...
                'Manual',obj.Manual);
        end

    end

    methods (Static)

        function obj = fromStruct(S)
        %FROMSTRUCT Restore a stored segmentation parameter snapshot.

            obj = oops.analysis.segment.Parameters();

            for name = ["Algorithm","Filtering","Defaults","Automatic","Manual"]

                if isfield(S,name)
                    obj.(name) = S.(name);
                end

            end
        end

    end

    methods (Static, Access=private)

        function values = mergeValues(values,overrides)
        %MERGEVALUES Replace matching fields and append newly supplied values.

            names = fieldnames(overrides);

            for k = 1:numel(names)
                values.(names{k}) = overrides.(names{k});
            end
        end

    end
end
