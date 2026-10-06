% OOPS - MATLAB app for desmosomal plaque protein analysis.
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

classdef Preferences
%PREFERENCES Facade for persistent application preferences.
%
%   Wraps MATLAB's GETPREF/SETPREF APIs behind a oops-specific
%   interface. Intended for storing persistent application state that
%   should survive between MATLAB sessions, such as setup versions,
%   migration status, accepted notices, etc.
%
%   This class is not intended for user-configurable settings. Those
%   belong in the oops.config.Settings system.

    properties (Constant, Access = private)
    %GROUP MATLAB preference group name.
    %
    %   All preferences managed by this class are stored under this
    %   group to avoid collisions with other applications.
        Group = 'oops'
    end

    methods (Static)

        function value = get(name, defaultValue)
        %GET Retrieve a preference value.
        %
        %   VALUE = GET(NAME, DEFAULTVALUE) returns the stored
        %   preference value if it exists. Otherwise, DEFAULTVALUE is
        %   returned.
        %
        %   Example:
        %       v = oops.Preferences.get( ...
        %           "SetupVersion", 0);

            if ispref(oops.Preferences.Group, name)
                value = getpref(oops.Preferences.Group, name);
            else
                value = defaultValue;
            end

        end

        function set(name, value)
        %SET Store a preference value.
        %
        %   SET(NAME, VALUE) stores VALUE under the specified
        %   preference name.
        %
        %   Example:
        %       oops.Preferences.set( ...
        %           "SetupVersion", 1);

            setpref(oops.Preferences.Group, name, value);
        end

        function tf = has(name)
        %HAS Determine whether a preference exists.
        %
        %   TF = HAS(NAME) returns true if the specified preference
        %   exists and false otherwise.
        %
        %   Example:
        %       if oops.Preferences.has("SetupVersion")

            tf = ispref(oops.Preferences.Group, name);
        end

        function remove(name)
        %REMOVE Remove a preference.
        %
        %   REMOVE(NAME) deletes the specified preference if it exists.
        %
        %   Example:
        %       oops.Preferences.remove("SetupVersion");

            if oops.Preferences.has(name)
                rmpref(oops.Preferences.Group, name);
            end

        end

        function prefs = print()
        %PRINT Print all oops preferences.
        %
        %   PRINT() lists every stored preference in the oops
        %   preference group.
        %
        %   PREFS = PRINT() also returns the preferences as a struct.

            % MATLAB preference group used to store OOPS preferences.
            group = oops.Preferences.Group;

            if ~ispref(group)

                % Stored preference values to print, or an empty struct when none exist.
                prefs = struct();
                fprintf('No oops preferences found.\n');
                return
            end

            prefs = getpref(group);

            % Names of the explicitly stored preferences.
            names = fieldnames(prefs);

            if isempty(names)
                fprintf('No oops preferences found.\n');
                return
            end

            matlabx.struct.prettyPrint(prefs);
        end

        function names = names()
        %NAMES Return known oops preference names.
        %
        %   NAMES = oops.Preferences.names() returns the names of
        %   preferences currently understood by oops. A preference
        %   can be known even when it has not been explicitly stored.

            % Known preference definitions, independent of explicitly stored values.
            catalog = oops.Preferences.catalog_();

            % Column string array listing the known preference names from the catalog.
            names = string({catalog.Name})';
        end

        function T = describe()
        %DESCRIBE Describe known oops preferences.
        %
        %   DESCRIBE() prints a table containing known preference names,
        %   dynamic defaults, current effective values, whether each value
        %   is explicitly stored, and a short description.
        %
        %   T = DESCRIBE() returns the same information as a table.

            % Known preferences with categories and descriptions.
            catalog = oops.Preferences.catalog_();

            % Dynamic default values for the current developer/runtime mode.
            defaults = oops.Preferences.defaultValues_();

            % Number of preference definitions to include in the description table.
            n = numel(catalog);

            % Text column containing each preference's name.
            Name = strings(n,1);

            % Text column containing each preference's category.
            Category = strings(n,1);

            % Text column showing each preference's current default.
            Default = strings(n,1);

            % Text column showing the stored value or its default fallback.
            Effective = strings(n,1);

            % Flags indicating whether each preference was explicitly stored.
            Explicit = false(n,1);

            % Text column explaining each known preference.
            Description = strings(n,1);

            % Collect the default, effective value, and description for each known preference.
            for k = 1:n

                % Preference name from the current catalog entry.
                name = string(catalog(k).Name);

                % Dynamic default for the current preference.
                defaultValue = defaults.(name);

                % Stored preference value, falling back to the dynamic default.
                effectiveValue = oops.Preferences.get(name, defaultValue);

                Name(k) = name;
                Category(k) = string(catalog(k).Category);
                Default(k) = oops.Preferences.valueToString_(defaultValue);
                Effective(k) = oops.Preferences.valueToString_(effectiveValue);
                Explicit(k) = oops.Preferences.has(name);
                Description(k) = string(catalog(k).Description);
            end

            % Preference description table assembled from the collected column values.
            T = table(Name, Category, Default, Effective, Explicit, Description);

            if nargout == 0
                disp(T);
                clear T
            end

        end

    end

    methods (Static, Access=private)

        function catalog = catalog_()
        %CATALOG_ Preference metadata for command-line discovery.

            catalog = [
                oops.Preferences.entry_("SetupVersion", "Setup", ...
                    "Last oops setup version applied to this MATLAB preferences group.")
                oops.Preferences.entry_("DeveloperMode", "Runtime", ...
                    "Use developer-oriented runtime defaults, currently focused on logging.")
                oops.Preferences.entry_("AnalysisDebugOutput", "Analysis", ...
                    "Show developer-oriented analysis diagnostics for experimental fitting routines.")
                oops.Preferences.entry_("LoggingLevel", "Logging", ...
                    "Global minimum log level used by sinks that do not define their own level.")
                oops.Preferences.entry_("LoggingDetail", "Logging", ...
                    "Global log formatting detail used by sinks that do not define their own detail.")
                oops.Preferences.entry_("LoggingSourceDetail", "Logging", ...
                    "Source formatting detail: short class/function names or full call paths.")
                oops.Preferences.entry_("LoggingCommandWindowLevel", "Logging", ...
                    "Minimum log level printed to the MATLAB Command Window.")
                oops.Preferences.entry_("LoggingCommandWindowDetail", "Logging", ...
                    "Log formatting detail used for MATLAB Command Window output.")
                oops.Preferences.entry_("LoggingUILevel", "Logging", ...
                    "Minimum log level shown in the GUI log window.")
                oops.Preferences.entry_("LoggingUIDetail", "Logging", ...
                    "Log formatting detail used for the GUI log window.")
                oops.Preferences.entry_("LoggingFileLevel", "Logging", ...
                    "Minimum log level written to the GUI session log file.")
                oops.Preferences.entry_("LoggingFileDetail", "Logging", ...
                    "Log formatting detail written to the GUI session log file.")
                ];
        end

        function entry = entry_(name, category, description)
        %ENTRY_ Construct one catalog entry.

            entry = struct( ...
                "Name", string(name), ...
                "Category", string(category), ...
                "Description", string(description));
        end

        function defaults = defaultValues_()
        %DEFAULTVALUES_ Dynamic defaults for known preferences.

            % Developer-mode preference used to choose logging defaults.
            devMode = logical(oops.Preferences.get("DeveloperMode", false));

            % Logging defaults corresponding to the selected developer mode.
            logging = oops.Log.preferenceDefaults(devMode);

            % Default values for the preferences known to the application.
            defaults = struct( ...
                "SetupVersion", "0.0.0", ...
                "DeveloperMode", false, ...
                "AnalysisDebugOutput", devMode, ...
                "LoggingLevel", logging.Level, ...
                "LoggingDetail", logging.Detail, ...
                "LoggingSourceDetail", logging.SourceDetail, ...
                "LoggingCommandWindowLevel", logging.CommandWindowLevel, ...
                "LoggingCommandWindowDetail", logging.CommandWindowDetail, ...
                "LoggingUILevel", logging.UILevel, ...
                "LoggingUIDetail", logging.UIDetail, ...
                "LoggingFileLevel", logging.FileLevel, ...
                "LoggingFileDetail", logging.FileDetail);
        end

        function s = valueToString_(value)
        %VALUETOSTRING_ Format mixed MATLAB preference values for a table.

            if isstring(value)

                % Readable text representation of a preference value for inspection tables.
                s = strjoin(value, ", ");
            elseif ischar(value)
                s = string(value);
            elseif isnumeric(value) || islogical(value)
                s = string(mat2str(value));
            else
                try
                    s = string(jsonencode(value));
                catch
                    s = strtrim(string(evalc('disp(value)')));
                end
            end

        end

    end

end
