% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Parameters
%PARAMETERS Value snapshot of the recipe that produced an image's final mask.
% Project settings are defaults for new runs. A stored recipe never changes
% when those defaults change, and contains no numerical image buffers or UI.

    properties (SetAccess=private)
        Strategy (1,1) string = "Puncta"
        Common (1,1) struct = struct()
        Values (1,1) struct = struct()
        AutomaticParameters (1,1) struct = struct()
        Mode (1,1) string = "Automatic"
        CandidateCount (1,1) double = 0
        RetainedCount (1,1) double = 0
        Ranking (1,1) string = "MeanIntensity"
    end

    methods

        function obj = Parameters(settings)
        %PARAMETERS Capture common filters and strategy-specific initial values.

            if nargin == 0
                settings = oops.config.Segmentation();
            end

            % Catalog metadata supplying initial values for the selected segmentation strategy.
            definition = oops.analysis.segment.strategies(settings.Strategy);
            obj.Strategy = definition.Name;
            obj.Common = rmfield(settings.toStruct(),'Strategy');

            % Copy each catalog parameter's initial value into this recipe snapshot.
            for p = definition.Parameters
                obj.Values.(p.Name) = p.Default;
            end

        end

        function obj = withAutomatic(obj,values)
        %WITHAUTOMATIC Record algorithm choices without overwriting manual values.

            obj.AutomaticParameters = values;

            if obj.Mode == "Automatic"
                obj.Values = values;
            end

        end

        function obj = withParameter(obj,name,value)
        %WITHPARAMETER Validate an adjustable parameter and explicitly mark manual use.

            % Strategy metadata used to validate the requested adjustable parameter.
            definition = oops.analysis.segment.strategies(obj.Strategy);

            % Parameter definition matching the requested name and its allowed range.
            p = definition.Parameters;

            if ~isempty(p)
                p = p([p.Name] == string(name));
            end

            if isempty(p) || ~p.Adjustable
                error('oops:analysis:UnknownParameter','Parameter %s is not adjustable for %s.',name,obj.Strategy);
            end

            validateattributes(value,{'double'},{'scalar','real','finite','>=',p.Limits(1),'<=',p.Limits(2)});
            obj.Values.(name) = value;
            obj.Mode = "Manual";
        end

        function obj = automatic(obj)
        %AUTOMATIC Restore algorithm-derived values while retaining the recipe snapshot.

            obj.Values = obj.AutomaticParameters;
            obj.Mode = "Automatic";
        end

        function obj = withCounts(obj,candidates,retained)
        %WITHCOUNTS Record the effect of component filtering for inspection/export.

            obj.CandidateCount = candidates;
            obj.RetainedCount = retained;
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize only the small recipe and its provenance.

            % Serializable recipe snapshot containing common filters, values, and provenance.
            S = struct('Strategy',obj.Strategy,'Common',obj.Common, ...
                'Values',obj.Values,'AutomaticParameters',obj.AutomaticParameters, ...
                'Mode',obj.Mode,'CandidateCount',obj.CandidateCount, ...
                'RetainedCount',obj.RetainedCount,'Ranking',obj.Ranking);
        end

    end
end
