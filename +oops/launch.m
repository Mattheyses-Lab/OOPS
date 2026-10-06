% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function gui = launch(opts)
%LAUNCH Open OOPS, or focus the existing main window like DesmoSTORM.
% With an output, return the controller for programmatic work with its project.

arguments
    opts.Visible (1,1) matlab.lang.OnOffSwitchState = 'on'
end
try

    if oops.app.hasMainFigure()
        oops.app.focusMainFigure();

        % Existing main figure, if one is already registered.
        fig = oops.app.getMainFigure();

        % Controller for the newly launched application window.
        gui = fig.UserData;
        return;
    end

    oops.setup.setupSearchPath();

    % Setup generation stored in preferences for this MATLAB installation.
    current = oops.Preferences.get("SetupVersion","0.0.0");

    if oops.Version.compare(current,oops.Info.RequiredSetupVersion) < 0
        oops.setup.run(UI=true);
        % Mark only successful setup; a failed migration is retried next launch.
        oops.Preferences.set("SetupVersion",oops.Info.RequiredSetupVersion);
    else
        % MATLAB paths and the Java class path are session-local. Restore them
        % even when a previous session completed the required setup generation.
        oops.setup.matlabx(UI=true);
    end

    gui = oops.app.GUI(Visible=opts.Visible);
catch ME
    oops.Log.EXCEPTION(ME);
    rethrow(ME);
end
end
