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

classdef Settings
%MATLABX.SETTINGS Static facade for matlabx user settings.
%
%   Get a setting:
%       value = matlabx.Settings.Logging("Level")
%       settings = matlabx.Settings.get()
%
%   Set a setting on the cached settings object:
%       matlabx.Settings.Logging("Level", "DEBUG")
%       matlabx.Settings.save()
%
%   Discover settings:
%       matlabx.Settings.categories()
%       matlabx.Settings.names("Logging")
%
%   Print settings:
%       matlabx.Settings.print()
%       matlabx.Settings.print("Logging")

    methods (Static)

        function value = Logging(name, value)
        %LOGGING Get or set a Logging setting.
            if nargin == 1
                value = matlabx.Settings.getCategoryValue_("Logging", name);
            else
                matlabx.Settings.setCategoryValue_("Logging", name, value);
            end
        end

        function value = UI(name, value)
        %UI Get or set a UI setting.
            if nargin == 1
                value = matlabx.Settings.getCategoryValue_("UI", name);
            else
                matlabx.Settings.setCategoryValue_("UI", name, value);
            end
        end

        function value = Images(name, value)
        %IMAGES Get or set an Images setting.
            if nargin == 1
                value = matlabx.Settings.getCategoryValue_("Images", name);
            else
                matlabx.Settings.setCategoryValue_("Images", name, value);
            end
        end

        function obj = get()
        %GET Return the cached matlabx.config.Settings object.
            obj = matlabx.config.Settings.get();
        end

        function save()
        %SAVE Save the cached settings object to disk.
            matlabx.config.Settings.saveActive();
        end

        function obj = reload()
        %RELOAD Reload settings from disk and return the settings object.
            obj = matlabx.config.Settings.reload();
        end

        function clear()
        %CLEAR Clear the cached settings object.
            matlabx.config.Settings.clear();
        end

        function restore()
        %RESTORE Restore defaults and save them to disk.
            matlabx.config.Settings.restore();
        end

        function names = categories()
        %CATEGORIES Return available top-level setting categories.
            obj = matlabx.Settings.get();
            names = string(properties(obj)).';
        end

        function names = names(category)
        %NAMES Return setting names for a category.
            category = matlabx.Settings.validateCategory_(category);
            obj = matlabx.Settings.get();
            names = string(properties(obj.(category))).';
        end

        function tf = has(category, name)
        %HAS True if a category setting exists.
            try
                category = matlabx.Settings.validateCategory_(category);
                matlabx.Settings.validateName_(category, name);
                tf = true;
            catch
                tf = false;
            end
        end

        function txt = print(category)
        %PRINT Print current settings, optionally limited to one category.
        %
        %   matlabx.Settings.print() prints all setting categories.
        %   matlabx.Settings.print("Logging") prints only Logging settings.
        %   txt = matlabx.Settings.print(...) returns the formatted text.

            if nargin < 1
                S = matlabx.Settings.toStruct_();
            else
                category = matlabx.Settings.validateCategory_(category);
                obj = matlabx.Settings.get();
                S = obj.(category).toStruct();
            end

            if nargout == 0
                matlabx.struct.prettyPrint(S);
            else
                txt = matlabx.struct.prettyPrint(S);
            end
        end

    end

    methods (Static, Access=private)

        function S = toStruct_()
            obj = matlabx.Settings.get();
            categories = matlabx.Settings.categories();

            S = struct();
            for k = 1:numel(categories)
                category = char(categories(k));
                S.(category) = obj.(category).toStruct();
            end
        end

        function value = getCategoryValue_(category, name)
            category = matlabx.Settings.validateCategory_(category);
            name = matlabx.Settings.validateName_(category, name);

            obj = matlabx.Settings.get();
            value = obj.(category).(name);
        end

        function setCategoryValue_(category, name, value)
            category = matlabx.Settings.validateCategory_(category);
            name = matlabx.Settings.validateName_(category, name);

            obj = matlabx.Settings.get();
            obj.(category).(name) = value;
        end

        function category = validateCategory_(category)
            category = string(category);

            if ~isscalar(category)
                error('matlabx:Settings:InvalidCategory', ...
                    'Setting category must be a text scalar.');
            end

            category = char(category);
            obj = matlabx.Settings.get();

            if ~isprop(obj, category)
                error('matlabx:Settings:UnknownCategory', ...
                    'Unknown settings category "%s".', category);
            end
        end

        function name = validateName_(category, name)
            name = string(name);

            if ~isscalar(name)
                error('matlabx:Settings:InvalidName', ...
                    'Setting name must be a text scalar.');
            end

            name = char(name);
            obj = matlabx.Settings.get();

            if ~isprop(obj.(category), name)
                error('matlabx:Settings:UnknownName', ...
                    'Unknown %s setting "%s".', category, name);
            end
        end

    end

end
