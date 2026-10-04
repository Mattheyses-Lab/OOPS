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

classdef Settings < handle
    properties
        UI      matlabx.config.UI
        Images  matlabx.config.Images
        Logging matlabx.config.Logging
    end

    methods
        function obj = Settings()
            obj.UI = matlabx.config.UI();
            obj.Images = matlabx.config.Images();
            obj.Logging = matlabx.config.Logging();
        end

        function S = toStruct(obj)
            S.Version = "0.1.0";
            S.UI = obj.UI.toStruct();
            S.Images = obj.Images.toStruct();
            S.Logging = obj.Logging.toStruct();
        end

        function fromStruct(obj,S)
            [S,~] = matlabx.config.Settings.migrate(S);

            if isfield(S,'UI'), obj.UI.fromStruct(S.UI); end
            if isfield(S,'Images'), obj.Images.fromStruct(S.Images); end
            if isfield(S,'Logging'), obj.Logging.fromStruct(S.Logging); end
        end

        function save(obj,file)
            if nargin < 2
                file = matlabx.internal.Paths.settingsFile();
            end

            folder = fileparts(file);
            if ~isfolder(folder)
                mkdir(folder);
            end

            txt = jsonencode(obj.toStruct(), PrettyPrint=true);
            fid = fopen(file,'w');
            assert(fid > 0, 'Could not open settings file for writing.');
            c = onCleanup(@() fclose(fid));
            fwrite(fid, txt, 'char');
        end
    end

    methods (Static)
        function obj = get()
        %GET Return cached user settings, loading them on first access.
            obj = matlabx.config.Settings.cache_();

            if isempty(obj) || ~isvalid(obj)
                obj = matlabx.config.Settings.load();
                matlabx.config.Settings.cache_(obj);
            end
        end

        function clear()
        %CLEAR Clear cached settings. Next get() reloads from disk.
            matlabx.config.Settings.cache_([]);
        end

        function obj = reload()
        %RELOAD Force settings reload from disk.
            obj = matlabx.config.Settings.load();
            matlabx.config.Settings.cache_(obj);
        end

        function saveActive(file)
        %SAVEACTIVE Save cached settings, if present, otherwise load defaults first.
            obj = matlabx.config.Settings.get();

            if nargin < 1
                obj.save();
            else
                obj.save(file);
            end
        end

        function obj = load(file)
            if nargin < 1
                file = matlabx.internal.Paths.settingsFile();
            end

            obj = matlabx.config.Settings();

            if isfile(file)
                S = jsondecode(fileread(file));
                if ~isfield(S,'Version')
                    S.Version = "0.0.0";
                end
                obj.fromStruct(S);
            else
                obj.save(file);
            end
        end

        function [S,migrated] = migrate(S)
            migrated = false;

            if ~isfield(S,'Version')
                S.Version = "0.0.0";
                migrated = true;
            end

            % future migrations go here
        end

        function restore(file)
            if nargin < 1
                file = matlabx.internal.Paths.settingsFile();
            end
            obj = matlabx.config.Settings();
            obj.save(file);
            matlabx.config.Settings.cache_(obj);
        end
    end

    methods (Static, Access=private)
        function obj = cache_(newObj)
            persistent cachedSettings

            if nargin > 0
                cachedSettings = newObj;
            end

            obj = cachedSettings;
        end
    end
end
