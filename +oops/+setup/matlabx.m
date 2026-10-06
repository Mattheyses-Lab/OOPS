% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function matlabx(opts)
%MATLABX Initialize matlabx paths and optional services for this MATLAB session.
% Delegate each service to matlabx while retaining OOPS's headless switches.
% The cached UICal entry point avoids recalibrating on every application launch.

    arguments
        opts.BioFormats (1,1) logical = true
        opts.UI (1,1) logical = false
    end
    oops.setup.setupSearchPath();
    try
        matlabx.setup.searchPath();

        if opts.BioFormats
            matlabx.setup.bioFormats();
        end

        if opts.UI
            matlabx.UICal.get();
        end

    catch ME
        oops.Log.EXCEPTION(ME);
        rethrow(ME);
    end
end
