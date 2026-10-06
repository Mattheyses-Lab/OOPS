% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Paths
    %PATHS Paths for the new implementation; independent of the current folder.

    methods (Static)

        function p = root()
        %ROOT Return the repository root independently of the working folder.

            % Repository root derived from this package file's location.
            p = fileparts(fileparts(mfilename('fullpath')));
        end

        function p = external(varargin)
        %EXTERNAL Resolve a bundled dependency path.

            % Bundled dependency path beneath the repository-level external directory.
            p = fullfile(oops.Paths.root(), 'external', varargin{:});
        end

        function p = settingsFile()
        %SETTINGSFILE Return the JSON app-default settings location.

            % User settings JSON path beneath the repository's user directory.
            p = fullfile(oops.Paths.root(), 'user', 'settings.json');
        end

        function p = logFile()
        %LOGFILE Generate a distinct session log path under the repository.

            % Timestamp used in the session log filename.
            stamp = string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));

            % Unique suffix distinguishing sessions started at the same time.
            id = matlabx.utils.text.uniqueID();

            % Full path of the new session's log file.
            p = fullfile(oops.Paths.root(),'logs',"oops_" + stamp + "_" + extractBefore(id,9) + ".log");
        end

    end
end
