% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function scale = pixelSize(input)
%PIXELSIZE Read independent X/Y physical scales from this stack's OME metadata.
% No project-wide override or heuristic interpretation of camera metadata is used.
% A missing/invalid physical scale falls back to one pixel for that axis.

% Per-axis scale defaults of one pixel, replaced by valid physical metadata.
scale = struct('X',1,'Y',1,'UnitX',"px",'UnitY',"px");
try

    % OME metadata attached to the lazy input source.
    metadata = input.OMEMetadata;

    if ~isstruct(metadata) || ~isfield(metadata,'Basic')
        return;
    end

    % Read and validate the physical-size metadata independently for X and Y.
    for axis = ["X","Y"]

        % Physical-size metadata field for the current X or Y axis.
        key = "PhysicalSize" + axis;

        if ~isfield(metadata.Basic,key)
            continue;
        end

        % Physical-size entry being checked for a valid numeric value and unit.
        value = metadata.Basic.(key);

        if isstruct(value) && isfield(value,'Value') && isfield(value,'Unit') && ...
                isnumeric(value.Value) && isscalar(value.Value) && ...
                isfinite(value.Value) && value.Value > 0 && strlength(string(value.Unit)) > 0
            scale.(axis) = double(value.Value);
            scale.("Unit"+axis) = string(value.Unit);
        end

    end

catch ME
    oops.Log.EXCEPTION(ME);
    oops.Log.WARN("Physical scale metadata could not be read; using pixels.");
end
end
