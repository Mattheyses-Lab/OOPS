% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function corrected = apply(stack,model,parameters)
%APPLY Dispatch one correction recipe against its prepared model.

arguments
    stack (:,:,:) double
    model = []
    parameters (1,1) oops.analysis.correction.Parameters = ...
        oops.analysis.correction.Parameters()
end

definition = oops.analysis.correction.algorithms(parameters.Algorithm);
corrected = definition.RunFcn(stack,model,parameters.Values);
validateattributes(corrected,{'double'}, ...
    {'real','size',size(stack)});
end
