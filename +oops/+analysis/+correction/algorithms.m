% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function definitions = algorithms(id)
%ALGORITHMS Describe available intensity-correction recipes.

arguments
    id (1,1) string = ""
end

definitions = [identityDefinition();flatFieldDefinition()];

if id ~= ""
    definitions = definitions([definitions.ID] == id);

    if isempty(definitions)
        error('oops:analysis:UnknownCorrectionAlgorithm', ...
            'Unsupported correction algorithm: %s',id);
    end
end
end

function definition = identityDefinition()
%IDENTITYDEFINITION Describe the uncorrected input path.
definition = oops.analysis.correction.Algorithm( ...
    ID="Identity/1", ...
    Label="No correction", ...
    Description="Uses the raw detector intensities.", ...
    RunFcn=@identity);
end

function definition = flatFieldDefinition()
%FLATFIELDDEFINITION Describe shared-response normalization and division.
definition = oops.analysis.correction.Algorithm( ...
    ID="GlobalMaximumFlatField/1", ...
    Label="Flat-field correction", ...
    Description="Averages calibration stacks, normalizes by one global maximum, and divides the input response.", ...
    BuildFcn=@oops.analysis.correction.normalizeFlatField, ...
    RunFcn=@oops.analysis.correction.flatField);
end

function corrected = identity(stack,~,~)
%IDENTITY Preserve raw detector values when no correction is assigned.

corrected = stack;
end
