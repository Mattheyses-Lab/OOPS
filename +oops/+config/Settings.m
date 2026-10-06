% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Settings < handle
%SETTINGS Nested project-wide settings with app-default JSON persistence.
% Root listeners retain the same generic/domain-specific event payloads as
% DesmoSTORM. Child handles are read-only so subscriptions cannot go stale.

    properties (SetAccess=private)
        View oops.config.View
        Segmentation oops.config.Segmentation
        LocalBackground oops.config.LocalBackground
        Display oops.config.Display
        IO oops.config.IO
        Colormaps oops.config.Colormaps
        Palettes oops.config.Palettes
        AzimuthDisplay oops.config.AzimuthDisplay
        ObjectDisplay oops.config.ObjectDisplay
        ObjectSelection oops.config.ObjectSelection
        ObjectIntensityProfile oops.config.ObjectIntensityProfile
        PolarHistogram oops.config.PolarHistogram
        ScatterPlot oops.config.ScatterPlot
        SwarmPlot oops.config.SwarmPlot
        Clustering oops.config.Clustering
    end

    properties (Access=private, Transient)
        Listeners event.listener = event.listener.empty()
    end

    events
        Changed
        ViewChanged
        SegmentationChanged
        LocalBackgroundChanged
        DisplayChanged
        IOChanged
        ColormapsChanged
        PalettesChanged
        AzimuthDisplayChanged
        ObjectDisplayChanged
        ObjectSelectionChanged
        ObjectIntensityProfileChanged
        PolarHistogramChanged
        ScatterPlotChanged
        SwarmPlotChanged
        ClusteringChanged
    end

    methods

        function obj = Settings()
        %SETTINGS Construct typed subsettings and forward their change events.

            obj.View = oops.config.View();
            obj.Segmentation = oops.config.Segmentation();
            obj.LocalBackground = oops.config.LocalBackground();
            obj.Display = oops.config.Display();
            obj.IO = oops.config.IO();
            obj.Colormaps = oops.config.Colormaps();
            obj.Palettes = oops.config.Palettes();
            obj.AzimuthDisplay = oops.config.AzimuthDisplay();
            obj.ObjectDisplay = oops.config.ObjectDisplay();
            obj.ObjectSelection = oops.config.ObjectSelection();
            obj.ObjectIntensityProfile = oops.config.ObjectIntensityProfile();
            obj.PolarHistogram = oops.config.PolarHistogram();
            obj.ScatterPlot = oops.config.ScatterPlot();
            obj.SwarmPlot = oops.config.SwarmPlot();
            obj.Clustering = oops.config.Clustering();

            % Subscribe to generic and domain-specific changes for every subsettings object.
            for domain = obj.domains()

                % Typed subsettings object for the current event/persistence domain.
                child = obj.(domain);
                obj.Listeners(end+1) = addlistener(child,'Changed', ...
                    @(~,e) notify(obj,'Changed',e));

                % Domain-specific event name to forward through the root settings object.
                eventName = char(domain + "Changed");
                obj.Listeners(end+1) = addlistener(child,eventName, ...
                    @(~,e) obj.forwardDomain(e));
            end

        end

        function delete(obj)
        %DELETE Release forwarded event subscriptions.

            for k = 1:numel(obj)
                delete(obj(k).Listeners);
            end

        end

        function S = toStruct(obj)
        %TOSTRUCT Snapshot every settings domain without runtime listeners.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('Version',char(oops.Info.Version), ...
                'SettingsSchemaVersion',char(oops.Info.SettingsSchemaVersion), ...
                'FactoryDefaultsVersion',char(oops.Info.FactoryDefaultsVersion));

            % Copy each settings domain into the plain persistence snapshot.
            for domain = obj.domains()
                S.(domain) = obj.(domain).toStruct();
            end

        end

        function fromStruct(obj,S)
        %FROMSTRUCT Apply available domains; omitted domains retain defaults.

            try
                % Project snapshots get schema migration, never factory resets.
                [S,~] = oops.config.Settings.migrate(S,ApplyFactoryDefaults=false);

                % Apply each saved domain to its existing typed settings object.
                for domain = obj.domains()

                    if isfield(S,domain)
                        obj.(domain).fromStruct(S.(domain));
                    end

                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function save(obj,file)
        %SAVE Write a UTF-8 JSON settings snapshot to disk.

            if nargin < 2
                file = obj.defaultFile();
            end

            try

                % UTF-8 JSON representation of the complete settings snapshot.
                json = jsonencode(obj.toStruct(),'PrettyPrint',true);

                % Destination directory to create before opening the settings file.
                folder = fileparts(file);

                if strlength(string(folder)) > 0 && ~isfolder(folder)
                    mkdir(folder);
                end

                % Writable file identifier checked before emitting JSON.
                fid = fopen(file,'w','n','UTF-8');

                if fid < 0
                    error('oops:config:WriteFailed','Cannot open settings file: %s',file);
                end

                % Cleanup guard that closes the file even if writing fails.
                cleaner = onCleanup(@() fclose(fid));

                % Number of characters written, checked for a failed/empty write.
                count = fprintf(fid,'%s',json);

                if count <= 0
                    error('oops:config:WriteFailed','Cannot write settings file: %s',file);
                end

                oops.Log.INFO("Saved settings: " + string(file));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    methods (Access=private)

        function forwardDomain(obj,e)
        %FORWARDDOMAIN Preserve a child's original domain event payload.

            notify(obj,char(e.Domain + "Changed"),e);
        end

    end

    methods (Static)

        function names = domains()
        %DOMAINS List subsettings participating in events and persistence.

            names = ["View" ...
                "Segmentation" ...
                "LocalBackground" ...
                "Display" ...
                "IO" ...
                "Colormaps" ...
                "Palettes" ...
                "AzimuthDisplay" ...
                "ObjectDisplay" ...
                "ObjectSelection" ...
                "ObjectIntensityProfile" ...
                "PolarHistogram" ...
                "ScatterPlot" ...
                "SwarmPlot" ...
                "Clustering"];
        end

        function file = defaultFile()
        %DEFAULTFILE Return the app-default JSON settings path.

            file = oops.Paths.settingsFile();
        end

        function obj = load(file)
        %LOAD Restore app defaults, creating the defaults file on first use.

            if nargin < 1
                file = oops.config.Settings.defaultFile();
            end

            try

                % Fresh settings tree receiving saved values or factory defaults.
                obj = oops.config.Settings();

                if isfile(file)

                    % Original JSON snapshot retained while migration constructs an updated version.
                    saved = jsondecode(fileread(file));

                    % Migrated snapshot and flag indicating whether it needs writing back to disk.
                    [S,migrated] = oops.config.Settings.migrate(saved,ApplyFactoryDefaults=true);
                    obj.fromStruct(S);

                    if migrated
                        % Keep the original file before an opinionated default refresh.
                        % A migration error never overwrites the source file.

                        % Previous factory-default generation, initially unknown for older
                        % snapshots.
                        previous = "0.0.0";

                        if isfield(saved,'FactoryDefaultsVersion') && ~isempty(saved.FactoryDefaultsVersion)
                            previous = string(saved.FactoryDefaultsVersion);
                        end

                        if oops.Version.compare(previous,oops.Info.FactoryDefaultsVersion) < 0

                            % Backup path retaining the original defaults before a generation
                            % refresh.
                            backup = string(file)+".before-"+oops.Info.FactoryDefaultsVersion+".bak";

                            if ~isfile(backup)
                                copyfile(file,backup);
                            end

                        end

                        obj.save(file);
                    end

                    oops.Log.INFO("Loaded settings: " + string(file));
                else
                    obj.save(file);
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function [S,migrated] = migrate(S,opts)
        %MIGRATE Upgrade schemas and optionally apply versioned app-default changes.
        % Factory defaults are opt-in here and enabled by load for app JSON files.

            arguments
                S
                opts.ApplyFactoryDefaults (1,1) logical = false
            end
            try
                validateattributes(S,{'struct'},{'scalar'});

                % Schema-upgraded snapshot and flag indicating a structural change.
                [S,migrated] = oops.config.Settings.migrateSchema_(S);

                if opts.ApplyFactoryDefaults

                    % Factory-updated snapshot and flag indicating a defaults-generation change.
                    [S,changed] = oops.config.Settings.migrateFactoryDefaults_(S);
                    migrated = migrated || changed;
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function restore(file)
        %RESTORE Replace saved defaults with a fresh factory settings snapshot.

            if nargin < 1
                file = oops.config.Settings.defaultFile();
            end

            % Fresh factory settings tree used to overwrite the app defaults file.
            obj = oops.config.Settings();
            obj.save(file);
        end

    end

    methods (Static, Access=private)

        function [S,migrated] = migrateSchema_(S)
        %MIGRATESCHEMA_ Fill missing fields without resetting stored user values.

            % Untouched input snapshot used to detect any migration changes.
            original = S;

            if ~isfield(S,'Version') || isempty(S.Version)
                S.Version = '0.0.0';
            end

            if ~isfield(S,'SettingsSchemaVersion') || isempty(S.SettingsSchemaVersion)
                S.SettingsSchemaVersion = S.Version;
            end

            if ~isfield(S,'FactoryDefaultsVersion') || isempty(S.FactoryDefaultsVersion)
                S.FactoryDefaultsVersion = '0.0.0';
            end

            % Schema version stored in the supplied snapshot.
            old = string(S.SettingsSchemaVersion);

            % Schema version supported by the current OOPS application.
            target = oops.Info.SettingsSchemaVersion;

            if oops.Version.compare(old,target) > 0
                error('oops:config:NewerSchema', ...
                    'Settings schema %s is newer than supported schema %s.',old,target);
            end

            % Validate metadata even if this stage does not interpret defaults.
            oops.Version.compare(S.Version,oops.Info.Version);
            oops.Version.compare(S.FactoryDefaultsVersion,oops.Info.FactoryDefaultsVersion);

            % Temporary factory settings used to fill missing domains and fields.
            defaults = oops.config.Settings();

            % Cleanup guard releasing that temporary settings tree.
            cleaner = onCleanup(@() delete(defaults));

            % Create any missing settings domains before migrating their fields.
            for domain = defaults.domains()

                if ~isfield(S,domain) || isempty(S.(domain))
                    S.(domain) = struct();
                end

                validateattributes(S.(domain),{'struct'},{'scalar'});
            end

            if oops.Version.compare(old,"2.0.0") < 0
                % Development snapshots once used one colormap category for all
                % domains. Preserve valid name/category pairs when splitting it.

                % Saved colormap settings being migrated to independent domain categories.
                maps = S.Colormaps;

                % Preserve valid map/category pairs for each independently configured domain.
                for domain = ["Intensity","Order","Azimuth"]

                    % Per-domain colormap category field introduced by the 2.0 schema.
                    category = domain+"Category";

                    if ~isfield(maps,category) && isfield(maps,'Category') && ...
                            isfield(maps,domain) && matlabx.colors.maps.Registry.has(maps.(domain),maps.Category)
                        maps.(category) = maps.Category;
                    end

                end

                if isfield(maps,'Category')
                    maps = rmfield(maps,'Category');
                end

                S.Colormaps = maps;

                if isfield(S,'Analysis')
                    S = rmfield(S,'Analysis');
                end

            end

            % Domains currently contain scalar structs of settings fields. Add
            % newly introduced fields, including independent order auto-scaling.

            % Read factory values for each settings domain.
            for domain = defaults.domains()

                % Factory values for the current settings domain, used only for missing fields.
                values = defaults.(domain).toStruct();

                % Fill only fields missing from the saved domain.
                for name = string(fieldnames(values))'

                    if ~isfield(S.(domain),name)
                        S.(domain).(name) = values.(name);
                    end

                end

            end

            S.Version = char(oops.Info.Version);
            S.SettingsSchemaVersion = char(target);

            % Whether the upgraded snapshot differs from the original supplied struct.
            migrated = ~isequaln(S,original);

            if oops.Version.compare(old,target) < 0
                oops.Log.INFO(sprintf('Migrating settings schema from %s to %s.',old,target));
            end

        end

        function [S,migrated] = migrateFactoryDefaults_(S)
        %MIGRATEFACTORYDEFAULTS_ Apply intentional changes only to app settings.
        % Add explicit generation blocks here when FactoryDefaultsVersion changes;
        % simply releasing an application patch must not reset user preferences.

            % Change flag, initially false until a factory-default update is applied.
            migrated = false;

            % Factory-default generation recorded in the saved settings.
            old = string(S.FactoryDefaultsVersion);

            % Factory-default generation required by this application version.
            target = oops.Info.FactoryDefaultsVersion;

            % Version ordering used to skip current/newer defaults or apply an update.
            comparison = oops.Version.compare(old,target);

            if comparison > 0
                error('oops:config:NewerFactoryDefaults', ...
                    'Factory-default generation %s is newer than supported generation %s.',old,target);
            elseif comparison == 0
                return;
            end

            if oops.Version.compare(old,"2.0.0") < 0
                % First 2.0 generation follows DesmoSTORM: refresh tunable defaults
                % while retaining the user's machine-specific import folder.

                % User's import directory retained across the factory-default refresh.
                folder = S.IO.DefaultFolder;

                % Temporary settings tree supplying the refreshed tunable defaults.
                defaults = oops.config.Settings();

                % Cleanup guard releasing that temporary settings tree.
                cleaner = onCleanup(@() delete(defaults));

                % Replace tunable settings domains with this factory generation's defaults.
                for domain = defaults.domains()
                    S.(domain) = defaults.(domain).toStruct();
                end

                S.IO.DefaultFolder = folder;
            end

            S.FactoryDefaultsVersion = char(target);
            migrated = true;
            oops.Log.WARN(sprintf('Updating app settings factory defaults from %s to %s.',old,target));
        end

    end
end
