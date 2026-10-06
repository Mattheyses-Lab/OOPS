% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function setupSearchPath()
%SETUPSEARCHPATH Add OOPS and bundled dependency roots, independently of pwd.
% Bootstrap matlabx before using the Log facade; nested dependency paths are
% initialized by oops.setup.matlabx. Path persistence belongs to setup.run.

    try

        % Repository root containing the +oops package, resolved independently of pwd.
        root = oops.Paths.root();

        % Bundled matlabx root that must exist before logger/setup services can load.
        dependency = oops.Paths.external('matlabx');

        if ~isfolder(dependency)
            error('oops:setup:MissingMatlabx', ...
                'The bundled matlabx subtree is missing: %s',dependency);
        end

        addpath(root,dependency);
    catch ME
        % A missing dependency may make the logger unavailable. Preserve the
        % original bootstrap error instead of replacing it with a logger error.
        if ~isempty(which('matlabx.logging.Logger'))
            oops.Log.EXCEPTION(ME);
        end

        rethrow(ME);
    end
end
