% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Parameters
%PARAMETERS Serializable recipe selecting one polarization algorithm.

    properties (SetAccess=private)
        Algorithm (1,1) string = "FourAngleStokes/1" % Versioned identifier of the selected polarization algorithm.
        Values (1,1) struct = struct() % Effective algorithm-specific parameter values.
    end

    methods

        function obj = Parameters(algorithm,values)
        %PARAMETERS Validate an algorithm ID and capture its parameter values.

            arguments
                algorithm (1,1) string = "FourAngleStokes/1"
                values (1,1) struct = struct()
            end

            definition = oops.analysis.polarization.algorithms(algorithm);
            allowed = strings(0,1);
            resolved = struct();

            if ~isempty(definition.ParameterDefinitions)
                allowed = [definition.ParameterDefinitions.Name]';

                for k = 1:numel(definition.ParameterDefinitions)
                    parameter = definition.ParameterDefinitions(k);
                    resolved.(parameter.Name) = parameter.Default;
                end
            end

            supplied = string(fieldnames(values));

            if any(~ismember(supplied,allowed))
                error('oops:analysis:UnknownPolarizationParameter', ...
                    'Unknown parameter for %s: %s',algorithm, ...
                    supplied(find(~ismember(supplied,allowed),1)));
            end

            for name = supplied'
                resolved.(name) = values.(name);
            end

            obj.Algorithm = definition.ID;
            obj.Values = resolved;
        end

        function tf = matches(obj,other)
        %MATCHES Test whether two recipes select identical algorithms and values.

            tf = obj.Algorithm == other.Algorithm && isequal(obj.Values,other.Values);
        end

        function S = toStruct(obj)
        %TOSTRUCT Return the durable algorithm recipe.

            S = struct('Algorithm',obj.Algorithm,'Values',obj.Values);
        end

    end

    methods (Static)

        function obj = fromStruct(S)
        %FROMSTRUCT Restore a recipe from persistent metadata.

            obj = oops.analysis.polarization.Parameters( ...
                string(S.Algorithm),S.Values);
        end

    end
end
