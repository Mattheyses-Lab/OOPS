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

classdef Registry
    % Directory/runtime colormap registry.
    %
    % File-backed maps live in assets/colormaps/<Category>/*.mat. The MATLAB
    % category is generated at runtime from MATLAB's built-in colormap
    % functions so matlabx does not redistribute MathWorks colormap data.
    % Values are matlabx.colors.maps.Colormap objects.

    methods (Static)
        function refresh()
            S = struct();
            S.BYKEY         = containers.Map('KeyType','char','ValueType','any');   % "cat|name" -> Colormap
            S.BYCAT         = containers.Map('KeyType','char','ValueType','any');   % cat(lower) -> {Colormap,...}
            S.BYNAME_UNIQUE = containers.Map('KeyType','char','ValueType','any');   % name(lower) -> Colormap (if unique)
            nameCount       = containers.Map('KeyType','char','ValueType','double');

            root = matlabx.colors.maps.Registry.rootDir();
            if ~isfolder(root)
                matlabx.colors.maps.Registry.state('set', S);
                return
            end

            % get colormap categories (names of folders in assets/colormaps)
            cats = matlabx.utils.files.getFolderNames(root);

            for i = 1:numel(cats)
                % get the name of the category folder
                category = string(cats{i});
                % get the full path to the category folder
                folder   = fullfile(root, category);
                % get the mat files in the category folder
                mats = dir(fullfile(folder,'*.mat'));

                % number of colormaps in this category
                nMaps = numel(mats);

                % category key used to index BYCAT map
                catKey = char(category);

                % preallocate the cell array used to hold Colormap objects for this category
                mapCell = cell(nMaps,1);

                for k = 1:numel(mats)
                    % get colormap name (filename without extension)
                    [~, base] = fileparts(mats(k).name);
                    name = string(base);
                    % full path to the colormap
                    path = fullfile(folder, name);

                    % create Colormap object
                    obj  = matlabx.colors.maps.Colormap(name, category, path);

                    % build a new key using the colormap name and category
                    key  = matlabx.colors.maps.Registry.mkKey(name, category);

                    % add Colormap object to BYKEY map
                    S.BYKEY(key) = obj;

                    % add Colormap obj to Colormap cell
                    mapCell{k} = obj;

                    % nameCount (case-sensitive)
                    nameKey = char(name);

                    if ~isKey(nameCount, nameKey)
                        nameCount(nameKey) = 1;
                    else
                        nameCount(nameKey) = nameCount(nameKey)+1;
                    end

                    % add Colormap object to BYNAME_UNIQUE
                    S.BYNAME_UNIQUE(nameKey) = obj;

                end

                % add Colormap cell to BYCAT map
                S.BYCAT(catKey) = mapCell;

            end

            matlabx.colors.maps.Registry.addMatlabBuiltins_(S, nameCount);
            matlabx.colors.maps.Registry.removeDuplicateShortNames_(S, nameCount);

            matlabx.colors.maps.Registry.state('set', S);
        end

        function cats = categories()
            S = matlabx.colors.maps.Registry.getOrInit();
            if isempty(S) || ~isfield(S,'BYCAT') || isempty(S.BYCAT)
                cats = matlabx.string.empty(); return
            end
            cats = string(keys(S.BYCAT));
            cats = sort(cats);
        end

        function list = names(category)
            S = matlabx.colors.maps.Registry.getOrInit();
            % return names for each category if category not provided
            if nargin==0 || strlength(category)==0
                cats = cellstr(matlabx.colors.maps.Registry.categories());
                % return empty string if no cats found
                if isempty(cats), list = matlabx.string.empty(); return; end
                % empty struct with cats as fieldnames
                list = matlabx.struct.fromFieldnames(cats);
                % add string array of names for each category
                for i = 1:numel(cats)
                    list.(cats{i}) = matlabx.colors.maps.Registry.names(cats{i});
                end
                return
            end

            key = char(category);

            if isempty(S) || ~isfield(S,'BYCAT') || ~isKey(S.BYCAT, key)
                list = matlabx.string.empty(); return
            end
            arr = S.BYCAT(key);                       % cell array of Colormap
            list = string(cellfun(@(o)o.Name, arr, 'UniformOutput', false));
            list = sort(list);
        end

        function tf = has(name, category)
            S = matlabx.colors.maps.Registry.getOrInit();
            if nargin == 1
                tf = ~isempty(S) && isfield(S,'BYNAME_UNIQUE') && isKey(S.BYNAME_UNIQUE, name);
            else
                tf = ~isempty(S) && isfield(S,'BYKEY') && isKey(S.BYKEY, matlabx.colors.maps.Registry.mkKey(name, category));
            end
        end

        function obj = get(name, category)
            S = matlabx.colors.maps.Registry.getOrInit();
            if nargin == 1
                % get key to look up colormap in BYNAME_UNIQUE
                key = name;
                % make sure S is non-empty and the key exists
                assert(~isempty(S) && isKey(S.BYNAME_UNIQUE, key), ...
                    ['Colormap "%s" not found or is not unique. ' ...
                    'If there are multiple colormaps named "%s", ' ...
                    'try specifying a category.'], name, name);
                % get the Colormap object
                obj = S.BYNAME_UNIQUE(key);
            else
                k = matlabx.colors.maps.Registry.mkKey(name, category);
                assert(~isempty(S) && isKey(S.BYKEY, k), 'Colormap not found: %s (%s)', name, category);
                obj = S.BYKEY(k);
            end
        end

        function p = fileFor(name, category)
            obj = matlabx.colors.maps.Registry.get(name, category);
            p = obj.Path;
        end

        function cat = categoryOf(name)
            obj = matlabx.colors.maps.Registry.get(name); % must be unique
            cat = obj.Category;
        end

        function M = map(name, category)
            if nargin == 1
                obj = matlabx.colors.maps.Registry.get(name);
            else
                obj = matlabx.colors.maps.Registry.get(name, category);
            end
            M = obj.getMap();
        end
    end

    methods (Static, Access=public)
        function root = rootDir()
            root = matlabx.internal.Paths.assets('colormaps');
        end
        function key = mkKey(name, category)
            key = char(category + "|" + name);
        end

        % ---- single persistent store for the whole class ----
        function S = state(op, val)
            persistent STATE
            if nargin==0 || (nargin==1 && strcmp(op,'get'))
                S = STATE; return
            elseif nargin==2 && strcmp(op,'set')
                STATE = val; S = STATE; return
            else
                S = STATE;  % no-op fallback
            end
        end

        function S = getOrInit()
            S = matlabx.colors.maps.Registry.state('get');
            if isempty(S)
                matlabx.colors.maps.Registry.refresh();
                S = matlabx.colors.maps.Registry.state('get');
            end
        end
    end

    methods (Static, Access=private)
        function removeDuplicateShortNames_(S, nameCount)
        %REMOVEDUPLICATESHORTNAMES_ Keep one-argument lookup only for unique names.
            nameKeys = keys(nameCount);
            for t = 1:numel(nameKeys)
                if nameCount(nameKeys{t}) > 1
                    warning('Duplicate colormap name found: %s',nameKeys{t})
                    if isKey(S.BYNAME_UNIQUE, nameKeys{t})
                        S.BYNAME_UNIQUE.remove(nameKeys{t});
                    end
                end
            end
        end

        function addMatlabBuiltins_(S, nameCount)
        %ADDMATLABBUILTINS_ Register MATLAB colormap functions at runtime.
            category = "MATLAB";
            names = matlabx.colors.maps.Registry.matlabBuiltinNames_();
            mapCell = {};

            for i = 1:numel(names)
                name = names(i);
                if exist(char(name), 'file') ~= 2 && exist(char(name), 'builtin') ~= 5
                    continue
                end

                obj = matlabx.colors.maps.Colormap(name, category, "builtin:" + name);
                key = matlabx.colors.maps.Registry.mkKey(name, category);
                nameKey = char(name);

                S.BYKEY(key) = obj;
                mapCell{end+1,1} = obj; %#ok<AGROW>

                if ~isKey(nameCount, nameKey)
                    nameCount(nameKey) = 1;
                else
                    nameCount(nameKey) = nameCount(nameKey) + 1;
                end

                S.BYNAME_UNIQUE(nameKey) = obj;
            end

            if ~isempty(mapCell)
                S.BYCAT(char(category)) = mapCell;
            end
        end

        function names = matlabBuiltinNames_()
        %MATLABBUILTINNAMES_ Built-in MATLAB colormap functions exposed by matlabx.
            names = ["autumn","bone","cool","copper","gray","hot","hsv", ...
                "jet","parula","pink","sky","spring","summer","turbo","winter"];
        end
    end
end
