% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [result,parameters] = analyze(stack,parameters)
%ANALYZE Dispatch and validate one polarization-analysis recipe.

arguments
    stack (:,:,:) double
    parameters (1,1) oops.analysis.polarization.Parameters = ...
        oops.analysis.polarization.Parameters()
end

definition = oops.analysis.polarization.algorithms(parameters.Algorithm);
result = definition.RunFcn(stack,parameters.Values);

outputs = definition.Outputs;

for k = 1:numel(outputs)
    output = outputs(k);
    if ~isfield(result,output.Name)
        error('oops:analysis:MissingPolarizationOutput', ...
            '%s did not return %s.',definition.ID,output.Name);
    end

    validateattributes(result.(output.Name),{'numeric'}, ...
        {'real','size',[size(stack,1),size(stack,2)]});
end
end
