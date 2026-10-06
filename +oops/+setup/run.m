% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function run(opts)
%RUN Orchestrate search paths, matlabx services, and saved settings like DesmoSTORM.
% UI initialization is optional for headless work. Saving the MATLAB search path
% is explicit because test fixtures and temporary sessions also call this API.

    arguments
        opts.BioFormats (1,1) logical = true
        opts.UI (1,1) logical = false
        opts.SavePath (1,1) logical = false
    end
    % Bootstrap first: the application logger is provided by matlabx.
    oops.setup.setupSearchPath();
    try
        oops.Log.INFO("Setting up matlabx for OOPS...");
        oops.setup.matlabx(BioFormats=opts.BioFormats,UI=opts.UI);

        % Create or validate saved defaults without replacing user preferences.
        oops.Log.INFO("Loading OOPS settings...");

        % Saved app defaults loaded temporarily to validate/create the settings file.
        settings = oops.config.Settings.load();
        delete(settings); % setup validates defaults; the project owns its own settings

        % Persist only after matlabx has added its nested dependency paths.
        if opts.SavePath && savepath() ~= 0
            error('oops:setup:SavePathFailed','MATLAB could not save the search path.');
        end

        oops.Log.INFO("OOPS setup completed successfully.");
    catch ME
        oops.Log.EXCEPTION(ME);
        rethrow(ME);
    end
end
