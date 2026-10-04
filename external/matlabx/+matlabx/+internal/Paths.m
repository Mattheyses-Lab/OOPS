% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

classdef Paths
%PATHS Helper class for locating file paths

    methods(Static)

        function r = root()
            % This file lives in some_path/+matlabx/+internal/Paths.m → go up 3 times to folder containing +matlabx
            r = mfilename('fullpath');
            for i = 1:3, r = fileparts(r); end
        end


        % --- assets ---

        function p = assets(varargin)
            p = fullfile(matlabx.internal.Paths.root(), 'assets', varargin{:});
        end

        function p = icons(varargin)
            p = matlabx.internal.Paths.assets('icons', varargin{:});
        end

        function p = colormaps(varargin)
            p = matlabx.internal.Paths.assets('colormaps', varargin{:});
        end


        % --- external ---

        function p = external(varargin)
            p = fullfile(matlabx.internal.Paths.root(), 'external', varargin{:});
        end

        % --- shortcuts ---

        function p = shortcuts(varargin)
            p = fullfile(matlabx.internal.Paths.root(), 'shortcuts', varargin{:});
        end


        % --- config, settings, user prefs ---

        function p = prefRoot(varargin)
            p = fullfile(prefdir, 'matlabx', varargin{:});
        end

        function p = settingsFile()
            p = matlabx.internal.Paths.prefRoot('settings.json');
        end

        function p = machineStateFile()
            p = matlabx.internal.Paths.prefRoot('machineState.json');
        end

    end

end