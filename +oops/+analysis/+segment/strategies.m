% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function definitions = strategies(name)
%STRATEGIES Describe supported algorithms and their strategy-specific controls.
% Keep this small catalog independent of graphics. Parameter metadata is shared
% by validation and the controller; implementations remain ordinary functions.

arguments
    name (1,1) string = ""
end

% Metadata defining the puncta threshold control and its valid values.
parameter = struct('Name',"Threshold",'Label',"Threshold", ...
    'Default',[],'Limits',[0 1],'Adjustable',true);

% Strategy catalog pairing names/labels with algorithms and parameter metadata.
definitions = [struct('Name',"Puncta",'Label',"Puncta", ...
    'Algorithm',@oops.analysis.segment.puncta, ...
    'Preview',@(diagnostics,recipe) diagnostics.Enhanced > recipe.Values.Threshold,'Parameters',parameter), ...
    struct('Name',"Filaments",'Label',"Filaments", ...
    'Algorithm',@oops.analysis.segment.filaments,'Preview',[],'Parameters',parameter([]))];
% An empty default means the algorithm determines the value automatically.
if name ~= ""
    definitions = definitions([definitions.Name] == name);

    if isempty(definitions)
        error('oops:analysis:UnknownStrategy','Unsupported segmentation strategy: %s',name);
    end

end

end
