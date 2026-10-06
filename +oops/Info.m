% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Info
%INFO Central application identity and independently controlled format generations.

    properties (Constant)
        Name (1,1) string = "OOPS"
        Version (1,1) string = "2.0.0" % application release: major.minor.patch
        MainFigureTag (1,:) char = 'oops.main'

        % Bump only when launch must repeat setup, dependency initialization,
        % UI calibration, or installation/settings migration checks.
        RequiredSetupVersion (1,1) string = "2.0.0"

        % Shape/meaning of settings snapshots. Schema migration preserves user
        % values and applies equally to app settings and project snapshots.
        SettingsSchemaVersion (1,1) string = "2.0.0"

        % Intentional updates to app-level defaults during development. These
        % updates never reset settings passed to a project through fromStruct.
        FactoryDefaultsVersion (1,1) string = "2.0.0"

        % Project layout is independent of release/default generations. Project
        % file serialization will use this marker when persistence is added.
        ProjectSchemaVersion (1,1) string = "2.0.0"
    end
end
