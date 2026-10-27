% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef GUI < handle
%GUI First OOPS controller: navigation, settings, two viewers, and session logging.
% The model owns ID state; this controller interprets it and owns all graphics.

    properties (SetAccess=private)
        Project (:,1) oops.model.Project = oops.model.Project.empty(0,1)
        Settings (:,1) oops.config.Settings = oops.config.Settings.empty(0,1)
        Fig (:,1) matlab.ui.Figure = matlab.ui.Figure.empty(0,1)
        SettingsAccordion
        GroupsTree
        ImagesTree
        ObjectsTree
        LabelsTree
        CommandRouter matlabx.ui.interaction.CommandRouter
        SummaryDomain
        SummaryTable
        LeftViewer
        RightViewer
        LeftPlotAxes matlabx.ui.axes.PlotAxes
        RightPlotAxes matlabx.ui.axes.PlotAxes
        ObjectViewerGrid
        ObjectNavigationGrid
        ObjectViewerPanels
        ObjectViewers cell = {}
        ObjectViewerBoundaryContents cell = {}
        ObjectViewerBoundaryTools cell = {}
        ObjectViewerOrientationFields cell = {}
        ObjectViewerOrientationTools cell = {}
        ObjectViewerMidlineContents cell = {}
        ObjectViewerMidlineTools cell = {}
        OrientationFields cell = {}
        OrientationFieldTools cell = {}
        ObjectBoundaryCollections cell = {}
        ScatterRenderer matlabx.ui.axes.plot.ScatterRenderer
        SwarmRenderer matlabx.ui.axes.plot.ViolinRenderer
        PolarHistogramRenderer oops.plot.PolarHistogramRenderer
        ViewerPanels
        LogTextArea
        ColormapTree
        ColormapDomain
        ColormapChannel
        ColormapMode
        ColormapColor
        ColormapPreview
        ColormapTypeLabel
        ColormapChannelLabel
        ColormapModeLabel
        ColormapAppearanceLabel
        SettingsUI struct = struct()
        SegmentationUI struct = struct()
        DisplayLimitUI struct = struct()
        ImageInfoWindow
        RuntimeStatusWindow
    end

    properties (Access=private)
        Grid
        LeftPane
        RightPane
        ViewerGrids cell = {}
        Listeners event.listener = event.listener.empty()
        Logger
        UICal
        OwnsProject (1,1) logical = false
        OwnsLogger (1,1) logical = false
        Refreshing (1,1) logical = false
        SyncingOverlays (1,1) logical = false
        Resizing (1,1) logical = false
        Processing (1,1) logical = false
        MenuUI struct = struct()
        Closing (1,1) logical = false
        ViewerKeys (1,2) string = ["",""]
        PanelContentNames (1,2) string = ["",""]
        ObjectViewerKey (1,1) string = ""
        LabelHotkeys (1,:) string = string.empty(1,0)
        ViewerListeners event.listener = event.listener.empty()
        AccordionListeners event.listener = event.listener.empty()
        SyncingViewerDisplay (1,1) logical = false
        ObjectsTreeDirty (1,1) logical = true
    end

    methods

        function obj = GUI(opts)
        %GUI Construct the controller and bind model/config events after building UI.

            arguments
                opts.Project (:,1) oops.model.Project = oops.model.Project.empty(0,1)
                opts.Visible (1,1) matlab.lang.OnOffSwitchState = 'on'
                opts.WriteLogFile (1,1) logical = true
            end
            try

                if oops.app.hasMainFigure()
                    error('oops:app:AlreadyOpen','Use oops.launch() to focus the existing window.');
                end

                if isempty(opts.Project)
                    obj.Settings = oops.config.Settings.load();
                else
                    validateattributes(opts.Project,{'oops.model.Project'},{'scalar'});
                    obj.Project = opts.Project;
                    obj.Settings = opts.Project.Settings;
                end

                if opts.WriteLogFile
                    obj.Logger = oops.Log.startSession();
                    obj.OwnsLogger = true;
                else
                    obj.Logger = oops.Log.get();
                end

                obj.UICal = matlabx.UICal.get();
                obj.buildWindow();
                oops.app.centerDialog(obj.Fig);
                obj.CommandRouter = matlabx.ui.interaction.CommandRouter('Parent',obj.Fig);
                obj.buildAccordion();
                obj.buildViewers();
                obj.buildObjectViewers();
                obj.buildPlots();
                obj.buildMenus();
                if ~isempty(obj.Project)
                    obj.bindEvents();
                    obj.reconcileActive();
                    obj.refreshNavigation();
                    obj.refreshViewers(true);
                else
                    obj.refreshEmptyProject();
                end
                obj.Logger.setUISink(@(lines) obj.appendLog(lines));
                obj.Fig.UserData = obj; % retains the controller when launch has no output
                obj.Fig.Visible = opts.Visible;
                drawnow;
                obj.resizeViewers();
                oops.Log.INFO("OOPS is ready. Check nodes for batch selection; highlight one to activate it.");
            catch ME
                oops.Log.EXCEPTION(ME);
                delete(obj);
                rethrow(ME);
            end
        end

        function images = addFiles(obj,files)
        %ADDFILES Import four-angle inputs into the active group without UI interaction.
        % The file chooser is only a thin wrapper around this programmatic method.

            % Column string array of input paths to process in file order.
            files = string(files(:));

            % Imported image handles collected for activation after the file batch.
            images = oops.model.Image.empty(0,1);

            if isempty(files)
                return;
            end

            % Active import destination, created when the project has no active group.
            group = obj.Project.ActiveGroup;

            if isempty(group)
                group = obj.addGroup("Group " + (numel(obj.Project.Groups)+1));
            end

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog("Loading four-angle inputs..."); %#ok<ASGLU>

            % Validated sources remain staged until their semantic primary-channel
            % mappings have been reviewed and committed together.
            inputs = matlabx.image.Image5D.empty(0,1);
            imageNames = strings(0,1);

            % Open each chosen input independently so a bad file does not stop later imports.
            for k = 1:numel(files)

                % Filename stem used as the imported image's initial name.
                [~,name] = fileparts(files(k));
                oops.runtime.updateProgress(progress, ...
                    sprintf('Image %d/%d: %s\nLoading four-angle input...',k,numel(files),name), ...
                    (k-1)/numel(files));
                try

                    % Lazy four-angle input opened from the current path.
                    input = oops.io.readInput(files(k));

                    inputs(end+1,1) = input; %#ok<AGROW>
                    imageNames(end+1,1) = string(name); %#ok<AGROW>
                catch ME
                    oops.Log.EXCEPTION(ME);
                    % One invalid file must not prevent importing later valid files.
                end
            end

            if isempty(inputs)
                return;
            end

            % Visible imports let the user distinguish acquisition metadata from
            % the semantic project channel assigned to each polarization input.
            if strcmp(obj.Fig.Visible,'on')
                delete(cleanupProgress);
                plan = oops.app.primaryChannelImportDialog( ...
                    obj.Fig,inputs,imageNames,obj.Project.Channels);
            else
                plan = defaultPrimaryChannelPlan( ...
                    inputs,imageNames,obj.Project.Channels);
            end

            if isempty(plan)
                return;
            end

            % Commit model membership and correction as one guarded batch so
            % collection/data events produce one final interface refresh.
            [progress,cleanupProgress] = obj.createProgressDialog( ...
                "Importing primary images..."); %#ok<ASGLU>
            names = string({plan.ImageName})';
            channels = oops.model.ChannelDefinition.empty(0,1);

            for k = 1:numel(plan)
                channels(k,1) = obj.Project.Channels.findOrAdd( ...
                    plan(k).ChannelName,plan(k).ChannelColor);
            end

            obj.Processing = true;
            refreshGuard = onCleanup(@() obj.endProcessing());
            images = group.addImages(vertcat(plan.Input),names,channels);
            oops.analysis.Analyzer.correctImages(images,Progress=progress);
            obj.Project.setActiveImage(images(1));
            oops.runtime.updateProgress(progress,"Updating interface...",1);

        end

        function newProject(obj,name)
        %NEWPROJECT Close the current model and create an empty owned project.

            arguments
                obj
                name (1,1) string = "Untitled"
            end

            settings = obj.Settings;

            if ~isempty(obj.Project)
                if ~obj.closeProject()
                    return;
                end
                settings = obj.Settings;
            end

            project = oops.model.Project(name,settings);
            obj.attachProject(project,true);
            oops.Log.INFO("Created project: " + name);
        end

        function closed = closeProject(obj)
        %CLOSEPROJECT Detach the current project while keeping the application open.

            closed = false;

            if isempty(obj.Project)
                closed = true;
                return;
            end

            if ~obj.confirmSaveIfDirty()
                return;
            end

            project = obj.Project;
            owned = obj.OwnsProject;

            if owned
                settings = obj.Settings;
            else
                settings = oops.config.Settings();
                settings.fromStruct(obj.Settings.toStruct());
            end

            delete(obj.Listeners);
            obj.Listeners = event.listener.empty();
            obj.Project = oops.model.Project.empty(0,1);
            obj.OwnsProject = false;
            obj.Settings = settings;

            if owned
                delete(project);
            end

            obj.refreshEmptyProject();
            closed = true;
            oops.Log.INFO("Closed project.");
        end

        function saved = saveProject(obj,file)
        %SAVEPROJECT Write the current project to an explicitly chosen path.

            saved = false;

            if isempty(obj.Project)
                error('oops:app:NoProject','Create or open a project before saving.');
            end

            oops.io.project.save(obj.Project,string(file));
            obj.updateProjectUIState();
            saved = true;
        end

        function resolution = openProject(obj,file,opts)
        %OPENPROJECT Load a project and replace the current controller model.

            arguments
                obj
                file (1,1) string
                opts.SearchRoot (1,1) string = ""
            end

            % Operation progress dialog retained through model attachment and UI refresh.
            [progress,cleanupProgress] = obj.createProgressDialog("Reading project file..."); %#ok<ASGLU>
            [project,resolution] = oops.io.project.load( ...
                file,SearchRoot=opts.SearchRoot,Progress=progress);
            oops.runtime.updateProgress(progress,"Updating project interface...",.995);
            obj.attachProject(project,true);
            oops.runtime.updateProgress(progress,"Project loaded",1);
        end

        function calibrations = registerCalibrations(obj,files)
        %REGISTERCALIBRATIONS Add reusable files without assigning any group.

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog("Importing calibration stacks..."); %#ok<ASGLU>
            calibrations = obj.registerCalibrationFiles(files,progress);
            obj.warnCalibrationState();
        end

        function calibrations = loadCalibrations(obj,files,groups)
        %LOADCALIBRATIONS Register shared files and assign them to target groups.

            % Project whose hierarchy supplies the navigation/operation targets.
            p = obj.Project;

            if nargin < 3
                groups = p.Groups(ismember(oops.model.internal.ids(p.Groups),p.SelectedGroupIDs));
            else
                oops.model.internal.validateIDs(groups,p.Groups,'oops:model:UnknownGroup',false);
            end

            if isempty(groups)
                error('oops:app:NoGroupsSelected','Select at least one group to receive calibration stacks.');
            end

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog("Loading calibration stacks..."); %#ok<ASGLU>
            calibrations = obj.registerCalibrationFiles(files,progress);

            if isempty(calibrations)
                return;
            end

            obj.Processing = true;

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() obj.endProcessing());
            oops.analysis.Analyzer.assignCalibrations(p,groups,oops.model.internal.ids(calibrations),Progress=progress);
            oops.runtime.updateProgress(progress,"Updating viewers...",[]);
            obj.Processing = false;
            obj.refreshNavigation();
            obj.refreshViewers(true);
            obj.warnCalibrationState();
        end

        function group = addGroup(obj,name,color)
        %ADDGROUP Create and activate a user-defined group; leave checked sets alone.

            arguments
                obj
                name (1,1) string
                color double = []
            end

            % Active/target group supplying its owned images and bookmarks.
            if isempty(color)
                group = obj.Project.addGroup(name);
            else
                group = obj.Project.addGroup(name,color);
            end

            obj.Project.setActiveGroup(group.ID);
        end

        function delete(obj)
        %DELETE Detach sinks/listeners before destroying graphics and owned model data.

            % Detach each controller's subscriptions and sinks before destroying its window.
            for k = 1:numel(obj)

                if obj(k).Closing
                    continue;
                end

                obj(k).Closing = true;
                delete(obj(k).Listeners);
                delete(obj(k).ViewerListeners);
                delete(obj(k).AccordionListeners);

                % Detach renderers before deleting their independently owned graphics.
                if ~isempty(obj(k).LeftPlotAxes) && isvalid(obj(k).LeftPlotAxes)
                    obj(k).LeftPlotAxes.clear();
                end

                if ~isempty(obj(k).RightPlotAxes) && isvalid(obj(k).RightPlotAxes)
                    obj(k).RightPlotAxes.clear();
                end

                if ~isempty(obj(k).ScatterRenderer) && isvalid(obj(k).ScatterRenderer)
                    delete(obj(k).ScatterRenderer);
                end

                if ~isempty(obj(k).SwarmRenderer) && isvalid(obj(k).SwarmRenderer)
                    delete(obj(k).SwarmRenderer);
                end

                if ~isempty(obj(k).PolarHistogramRenderer) && isvalid(obj(k).PolarHistogramRenderer)
                    delete(obj(k).PolarHistogramRenderer);
                end

                if ~isempty(obj(k).ImageInfoWindow) && isvalid(obj(k).ImageInfoWindow)
                    delete(obj(k).ImageInfoWindow);
                end

                if ~isempty(obj(k).RuntimeStatusWindow) && isvalid(obj(k).RuntimeStatusWindow)
                    delete(obj(k).RuntimeStatusWindow);
                end

                % Application tools unregister their toolbar/menu contributions
                % while the ImageAxes graphics hierarchy is still alive.
                for tool = obj(k).OrientationFieldTools
                    if ~isempty(tool{1}) && isvalid(tool{1})
                        delete(tool{1});
                    end
                end

                % Active-object viewer tools own only application-overlay UI.
                objectViewerTools = [ ...
                    obj(k).ObjectViewerBoundaryTools, ...
                    obj(k).ObjectViewerOrientationTools, ...
                    obj(k).ObjectViewerMidlineTools];

                for tool = objectViewerTools
                    if ~isempty(tool{1}) && isvalid(tool{1})
                        delete(tool{1});
                    end
                end

                % Batched boundary renderers release their logical overlays and
                % shared graphics while the ImageAxes hierarchy is still alive.
                for collection = obj(k).ObjectBoundaryCollections
                    if ~isempty(collection{1}) && isvalid(collection{1})
                        delete(collection{1});
                    end
                end

                % Application-owned content removes its passive mount next.
                for field = obj(k).OrientationFields
                    if ~isempty(field{1}) && isvalid(field{1})
                        delete(field{1});
                    end
                end

                % Passive object-view contents dispose their own primitives.
                objectViewerContents = [ ...
                    obj(k).ObjectViewerBoundaryContents, ...
                    obj(k).ObjectViewerOrientationFields, ...
                    obj(k).ObjectViewerMidlineContents];

                for content = objectViewerContents
                    if ~isempty(content{1}) && isvalid(content{1})
                        delete(content{1});
                    end
                end

                if ~isempty(obj(k).Logger) && isvalid(obj(k).Logger)
                    obj(k).Logger.flush();
                    obj(k).Logger.setUISink(@(~) [],false);

                    if obj(k).OwnsLogger

                        % Logger currently held by the facade, checked before closing the owned
                        % session.
                        active = oops.Log.get();

                        if active == obj(k).Logger
                            oops.Log.close();
                        end

                    end

                end

                if ~isempty(obj(k).Fig) && isvalid(obj(k).Fig)
                    obj(k).Fig.CloseRequestFcn = [];
                    obj(k).Fig.UserData = [];
                    delete(obj(k).Fig);
                end

                if obj(k).OwnsProject
                    settings = obj(k).Settings;
                    delete(obj(k).Project);
                    delete(settings);
                end

                if isempty(obj(k).Project) && ~isempty(obj(k).Settings)
                    delete(obj(k).Settings);
                end

            end

        end

    end

    methods (Static)

        function fig = findGUI()
        %FINDGUI Locate the main window independently of controller construction.

            % Main figure matching the application tag, reduced to the first match.
            fig = findall(groot,'Type','figure','Tag',oops.Info.MainFigureTag);

            if isempty(fig)
                fig = matlab.ui.Figure.empty(0,1);
            else
                fig = fig(1);
            end

        end

    end

    methods (Access=private)

        function attachProject(obj,project,owned)
        %ATTACHPROJECT Replace the model and rebuild its controller subscriptions.

            oldProject = obj.Project;
            oldSettings = obj.Settings;
            oldOwned = obj.OwnsProject;
            delete(obj.Listeners);
            obj.Listeners = event.listener.empty();
            obj.Project = project;
            obj.Settings = project.Settings;
            obj.OwnsProject = owned;

            if oldOwned && ~isempty(oldProject)
                delete(oldProject);
                delete(oldSettings);
            elseif isempty(oldProject) && ~isempty(oldSettings) && oldSettings ~= obj.Settings
                delete(oldSettings);
            end

            obj.bindEvents();
            % Project channels must populate variable dropdowns before saved
            % channel-backed selections are copied into their Value properties.
            obj.refreshMeasurementControls();
            obj.refreshSettingsControls();
            % Image Display owns custom model-backed controls outside SettingsUI;
            % rebuild their channel choices against the newly attached project.
            obj.refreshColormapControls();
            obj.reconcileActive();
            obj.refreshNavigation();
            obj.refreshLabels();
            obj.ViewerKeys(:) = "";
            obj.ObjectViewerKey = "";
            obj.refreshViewers(true);
            obj.updateProjectUIState();
        end

        function refreshSettingsControls(obj)
        %REFRESHSETTINGSCONTROLS Copy a newly attached settings tree into bound controls.

            domains = string(fieldnames(obj.SettingsUI));

            for domain = domains'

                if ~isprop(obj.Settings,domain)
                    continue;
                end

                names = string(fieldnames(obj.SettingsUI.(domain)));

                for name = names'
                    control = obj.SettingsUI.(domain).(name);

                    if isvalid(control) && isprop(control,'Value') && ...
                            isprop(obj.Settings.(domain),name)
                        control.Value = obj.Settings.(domain).(name);
                        obj.refreshPairedColorControl(control);
                    end

                end

            end
        end

        function refreshEmptyProject(obj)
        %REFRESHEMPTYPROJECT Clear model-backed controls for an empty application session.

            obj.deleteTreeNodes(obj.GroupsTree.Children);
            obj.deleteTreeNodes(obj.ImagesTree.Children);
            obj.deleteTreeNodes(obj.ObjectsTree.Children);
            obj.deleteTreeNodes(obj.LabelsTree.Children);

            for key = obj.LabelHotkeys
                obj.CommandRouter.removeHotkey(key);
            end

            obj.LabelHotkeys = string.empty(1,0);
            obj.SummaryTable.Data = table();
            obj.ViewerKeys(:) = "";
            obj.PanelContentNames(:) = "";
            obj.ObjectViewerKey = "";
            obj.refreshColormapControls();

            viewers = {obj.LeftViewer,obj.RightViewer};

            for k = 1:numel(viewers)
                viewers{k}.CData = [];
                viewers{k}.ImageVisible = 'off';
                viewers{k}.AxesVisible = 'off';
            end

            for k = 1:numel(obj.ViewerPanels)
                obj.ViewerPanels(k).Title = 'No project';
            end

            obj.updateProjectUIState();
        end

        function updateProjectUIState(obj)
        %UPDATEPROJECTUISTATE Synchronize content, commands, and window title.

            hasProject = ~isempty(obj.Project);
            state = matlab.lang.OnOffSwitchState(hasProject);

            % Match DesmoSTORM's empty-session behavior: retain the figure
            % menubar while hiding all project-specific application content.
            obj.Grid.Visible = state;

            for name = ["Close","Save","SaveAs","LoadImages","Calibration", ...
                    "AuxiliaryChannels","Export","Edit","Run","View","Objects","RuntimeStatus"]

                if isfield(obj.MenuUI,name)
                    obj.MenuUI.(name).Enable = state;
                end

            end

            if hasProject
                dirtyMarker = "";

                if obj.Project.HasUnsavedChanges
                    dirtyMarker = "*";
                end

                marker = "";

                if obj.Project.SourcePath ~= ""
                    marker = " — " + obj.Project.SourcePath;
                end

                obj.Fig.Name = char("OOPS — " + obj.Project.Name + dirtyMarker + marker);
            else
                obj.Fig.Name = 'OOPS — No project';
            end
        end

        function proceed = confirmSaveIfDirty(obj)
        %CONFIRMSAVEIFDIRTY Resolve unsaved project changes before replacement.

            proceed = true;

            if isempty(obj.Project) || ~obj.Project.HasUnsavedChanges
                return;
            end

            % Hidden controller instances cannot present a modal decision. They are
            % used by programmatic workflows that already own their model lifecycle.
            if isempty(obj.Fig) || ~isvalid(obj.Fig) || strcmp(obj.Fig.Visible,'off')
                return;
            end

            answer = uiconfirm(obj.Fig, ...
                "Save changes to " + obj.Project.Name + "?", ...
                'Unsaved project changes', ...
                'Options',{'Save','Discard','Cancel'}, ...
                'DefaultOption','Save','CancelOption','Cancel','Icon','warning');

            switch answer
                case 'Save'
                    proceed = obj.chooseProjectSave(false);
                case 'Discard'
                    proceed = true;
                otherwise
                    proceed = false;
            end
        end

        function requestApplicationClose(obj)
        %REQUESTAPPLICATIONCLOSE Confirm dirty state before destroying the app.

            if obj.confirmSaveIfDirty()
                delete(obj);
            end
        end

        function chooseProject(obj)
        %CHOOSEPROJECT Prompt for a saved project and optionally locate moved sources.

            [file,folder] = uigetfile({'*.oops.mat;*.mat','OOPS projects'}, ...
                'Open OOPS project');
            obj.focusWindow();

            if isequal(file,0)
                return;
            end

            path = string(fullfile(folder,file));

            if ~obj.confirmSaveIfDirty()
                return;
            end

            try
                resolution = obj.openProject(path);
                obj.notifyRelinkedSources(resolution);
            catch ME

                if ~strcmp(ME.identifier,'oops:project:MissingSources')
                    rethrow(ME);
                end

                answer = uiconfirm(obj.Fig, ...
                    string(ME.message) + newline + newline + ...
                    "Choose a folder to search recursively for moved files?", ...
                    'Missing project sources', ...
                    'Options',{'Choose Folder','Cancel'}, ...
                    'DefaultOption','Choose Folder','CancelOption','Cancel');

                if ~strcmp(answer,'Choose Folder')
                    return;
                end

                root = uigetdir(folder,'Locate project image files');
                obj.focusWindow();

                if isequal(root,0)
                    return;
                end

                resolution = obj.openProject(path,SearchRoot=string(root));
                obj.notifyRelinkedSources(resolution);
            end
        end

        function notifyRelinkedSources(obj,resolution)
        %NOTIFYRELINKEDSOURCES Report successful path changes and recommend saving.

            if ~isfield(resolution,'Relinked') || isempty(resolution.Relinked)
                return;
            end

            count = numel(resolution.Relinked);
            message = string(count) + " project source";

            if count ~= 1
                message = message + "s were";
            else
                message = message + " was";
            end

            message = message + " relinked to new file locations." + ...
                newline + newline + ...
                "Save the project to preserve the updated source paths.";

            if ~isempty(obj.Fig) && isvalid(obj.Fig) && strcmp(obj.Fig.Visible,'on')
                uialert(obj.Fig,message,'Project sources relinked','Icon','warning');
            end
        end

        function saved = chooseProjectSave(obj,saveAs)
        %CHOOSEPROJECTSAVE Always confirm the destination before writing a project.

            saved = false;

            if isempty(obj.Project)
                return;
            end

            suggested = obj.Project.Name + ".oops.mat";

            if ~saveAs && obj.Project.SourcePath ~= ""
                suggested = obj.Project.SourcePath;
            elseif obj.Project.SourcePath ~= ""
                suggested = fullfile(fileparts(obj.Project.SourcePath),suggested);
            end

            [file,folder] = uiputfile({'*.oops.mat','OOPS project'}, ...
                'Save OOPS project',char(suggested));
            obj.focusWindow();

            if isequal(file,0)
                return;
            end

            saved = obj.saveProject(string(fullfile(folder,file)));
        end

        function exportSummaryTables(obj)
        %EXPORTSUMMARYTABLES Collect a destination and write the project workbook.

            if isempty(obj.Project)
                return;
            end

            [progress,cleanupProgress] = obj.createProgressDialog( ...
                "Preparing summary-table export..."); %#ok<ASGLU>
            success = oops.export.Exporter.exportSummaryTables( ...
                obj.Project,Progress=progress);
            obj.focusWindow();

            if ~success
                oops.Log.INFO("Summary-table export cancelled.");
            end
        end

        function buildWindow(obj)
        %BUILDWINDOW Use a fixed settings column and a non-scrolling viewer/log grid.

            obj.Fig = uifigure('Name','OOPS','Tag',oops.Info.MainFigureTag, ...
                'Visible','off','AutoResizeChildren','off','Position',[80 80 1400 850],'Color',[.12 .12 .12], ...
                'CloseRequestFcn',@(~,~) obj.requestApplicationClose());
            obj.Grid = uigridlayout(obj.Fig,[1 2],'ColumnWidth',{300,'1x'}, ...
                'RowHeight',{'1x'},'Padding',5,'ColumnSpacing',5, ...
                'BackgroundColor',[.12 .12 .12]);
            obj.LeftPane = uigridlayout(obj.Grid,[1 1],'ColumnWidth',{'1x'}, ...
                'RowHeight',{'fit'},'Padding',0,'Scrollable','on', ...
                'BackgroundColor',[.12 .12 .12]);
            obj.LeftPane.Layout.Column = 1;
            obj.RightPane = uigridlayout(obj.Grid,[2 2],'ColumnWidth',{'1x','1x'}, ...
                'RowHeight',{550,'1x'},'Padding',0,'ColumnSpacing',5,'RowSpacing',5, ...
                'Scrollable','off','BackgroundColor',[.12 .12 .12]);
            obj.RightPane.Layout.Column = 2;
        end

        function buildAccordion(obj)
        %BUILDACCORDION Match DesmoSTORM item styling and compact five-pixel spacing.

            obj.SettingsAccordion = matlabx.ui.container.Accordion(obj.LeftPane, ...
                'ItemSpacing',5,'BorderWidth',0,'BorderColor',[.18 .18 .18], ...
                'Padding',0,'BackgroundColor',[.12 .12 .12]);

            % Ordered item titles for navigation and settings sections.
            titles = ["Groups","Images","Objects","Labels", ...
                "Display Limits","Image Display","View","Object Selection", ...
                "Mask","Scatterplot","Swarmplot","Polar histogram", ...
                "Orientation Lines","Summary"];

            % Create the accordion items in their intended display order.
            for title = titles
                obj.SettingsAccordion.addItem(Title=title,BorderColor=[.49 .49 .49], ...
                    TitleBackgroundColor=[.12 .12 .12],HoverTitleBackgroundColor=[.3 .3 .3], ...
                    PaneBackgroundColor=[.18 .18 .18],FontColor=[.85 .85 .85], ...
                    BorderWidth=1,ExpandedBorderWidth=1,TitlePadding=1);
            end

            obj.GroupsTree = obj.buildTree("Groups",140);
            obj.ImagesTree = obj.buildTree("Images",200);
            obj.ObjectsTree = obj.buildTree("Objects",200);
            objectsItem = obj.SettingsAccordion.getItem("Objects");
            obj.AccordionListeners(end+1) = addlistener(objectsItem,'expanded','PostSet', ...
                @(~,~) obj.runCallback(@() obj.onObjectsAccordionExpanded()));
            obj.buildLabels();
            obj.buildSummary();

            % Object overlay geometry and appearance settings.
            obj.addSetting("Object Selection","Shape","ObjectSelection", ...
                "BoxType",["Boundary","Box"]);
            obj.addModeColorSetting("Object Selection","Base color", ...
                "ObjectSelection","ColorMode","Color", ...
                ["Label","Custom"],"Custom");
            obj.addSetting("Object Selection","Base width", ...
                "ObjectSelection","LineWidth");
            obj.addModeColorSetting("Object Selection","Active color", ...
                "ObjectSelection","ActiveColorMode","ActiveColor", ...
                ["Auto","Custom"],"Custom");
            obj.addSetting("Object Selection","Active width", ...
                "ObjectSelection","ActiveLineWidth");
            obj.addModeColorSetting("Object Selection","Selected color", ...
                "ObjectSelection","SelectedColorMode","SelectedColor", ...
                ["Auto","Custom"],"Custom");
            obj.addSetting("Object Selection","Selected width", ...
                "ObjectSelection","SelectedLineWidth");
            obj.addModeColorSetting("Object Selection","Hover color", ...
                "ObjectSelection","HoverColorMode","HoverColor", ...
                ["Auto","Custom"],"Custom");
            obj.addSetting("Object Selection","Hover width", ...
                "ObjectSelection","HoverLineWidth");
            obj.addSetting("Object Selection","Show active when selected", ...
                "ObjectSelection","ShowActiveWhenSelected");

            % Axial orientation-field appearance and spatial sampling controls.
            obj.addSetting("Orientation Lines","Color by","AzimuthDisplay", ...
                "ColorMode",["Direction","Magnitude","Mono"]);
            obj.addColorSetting("Orientation Lines","Mono color", ...
                "AzimuthDisplay","Color");
            obj.addSetting("Orientation Lines","Line width", ...
                "AzimuthDisplay","LineWidth");
            obj.addSetting("Orientation Lines","Opacity", ...
                "AzimuthDisplay","LineAlpha");
            obj.addSetting("Orientation Lines","Length scale", ...
                "AzimuthDisplay","LineScale");
            obj.addSetting("Orientation Lines","Sampling interval", ...
                "AzimuthDisplay","ScaleDownFactor");
            obj.addSetting("Orientation Lines","Restrict to objects", ...
                "AzimuthDisplay","ObjectMask");

            % Image source choices supported by both viewer dropdowns.
            sources = oops.config.View.sources();
            obj.addSetting("View","Left","View","LeftSource",sources(sources ~= "Objects"));
            obj.addSetting("View","Right","View","RightSource",sources);
            labels = oops.config.View.sourceLabels(sources);
            obj.SettingsUI.View.LeftSource.Items = cellstr(labels(sources ~= "Objects"));
            obj.SettingsUI.View.RightSource.Items = cellstr(labels);

            % Segmentation catalog used to populate the algorithm selector and controls.
            definitions = oops.analysis.segment.algorithms();
            obj.addSetting("Mask","Algorithm","Segmentation","Algorithm",[definitions.ID]);
            obj.SettingsUI.Segmentation.Algorithm.Items = cellstr([definitions.Label]);
            obj.addSetting("Mask","Connectivity","Segmentation","Connectivity",[4 8]);
            obj.buildSegmentationAdjustments(definitions);
            obj.addSectionLabel("Mask","Object filtering");
            obj.addSetting("Mask","Minimum area","Segmentation","MinimumArea");
            obj.addSetting("Mask","Maximum objects","Segmentation","MaxObjects");
            obj.SettingsUI.Segmentation.MaxObjects.Tooltip = 'Keep the brightest objects by mean input intensity; 0 means unlimited.';
            obj.addSetting("Mask","Border width","Segmentation","BorderWidth");
            obj.buildScatterPlotControls();
            obj.buildSwarmPlotControls();
            obj.buildPolarHistogramControls();
            obj.buildColormapControls();
            obj.buildDisplayLimits();

            % Expand the three navigation sections for initial use.
            for title = ["Groups","Images","Objects","Labels"]
                obj.SettingsAccordion.getItem(title).expand();
            end

        end

        function buildScatterPlotControls(obj)
        %BUILDSCATTERPLOTCONTROLS Bind scatter variables and appearance settings.

            variables = oops.model.ObjectMeasurements.plottableNames(obj.Project);
            obj.addSetting("Scatterplot","X variable","ScatterPlot","XVariable",variables);
            obj.addSetting("Scatterplot","Y variable","ScatterPlot","YVariable",variables);

            % Show readable labels while retaining model property names as values.
            labels = oops.model.ObjectMeasurements.labels(variables,obj.Project);
            obj.SettingsUI.ScatterPlot.XVariable.Items = cellstr(labels);
            obj.SettingsUI.ScatterPlot.YVariable.Items = cellstr(labels);

            % Data selection and grouping.
            obj.addSetting("Scatterplot","Group points by","ScatterPlot","GroupingType",["Group","Label"]);
            obj.addSetting("Scatterplot","Color points by","ScatterPlot","ColorMode",["Group","Label","Magnitude"]);

            % Point-marker visibility and appearance.
            obj.addSetting("Scatterplot","Marker mode","ScatterPlot","MarkerMode",["single","multi","auto"]);
            obj.addSetting("Scatterplot","Marker size","ScatterPlot","MarkerSize");
            obj.addSetting("Scatterplot","Marker line width","ScatterPlot","MarkerLineWidth");
            obj.addModeColorSetting("Scatterplot","Marker face color","ScatterPlot", ...
                "MarkerFaceColorMode","MarkerFaceColor",["Auto","Custom"],"Custom");
            obj.addSetting("Scatterplot","Marker face alpha","ScatterPlot","MarkerFaceAlpha");
            obj.addModeColorSetting("Scatterplot","Marker edge color","ScatterPlot", ...
                "MarkerEdgeColorMode","MarkerEdgeColor",["Auto","Custom"],"Custom");
            obj.addSetting("Scatterplot","Marker edge alpha","ScatterPlot","MarkerEdgeAlpha");

            % Optional group hulls and their appearance.
            obj.addSetting("Scatterplot","Show hulls","ScatterPlot","HullVisible");
            obj.addSetting("Scatterplot","Hull type","ScatterPlot","HullType",["concave","convex"]);
            obj.addSetting("Scatterplot","Hull line width","ScatterPlot","HullLineWidth");
            obj.addModeColorSetting("Scatterplot","Hull face color","ScatterPlot", ...
                "HullFaceColorMode","HullFaceColor",["auto","Custom"],"Custom");
            obj.addSetting("Scatterplot","Hull face alpha","ScatterPlot","HullFaceAlpha");
            obj.addModeColorSetting("Scatterplot","Hull edge color","ScatterPlot", ...
                "HullEdgeColorMode","HullEdgeColor",["auto","Custom"],"Custom");
            obj.addSetting("Scatterplot","Hull edge alpha","ScatterPlot","HullEdgeAlpha");

            % Data-tip detail applies to every plotted point.
            obj.addSetting("Scatterplot","Data-tip detail","ScatterPlot", ...
                "DataTipDetail",["Compact","Verbose"]);

            % General axes and legend appearance.
            obj.addSetting("Scatterplot","Show legend","ScatterPlot","LegendVisible");
            obj.addColorSetting("Scatterplot","Background","ScatterPlot","BackgroundColor");
            obj.addColorSetting("Scatterplot","Foreground","ScatterPlot","ForegroundColor");
        end

        function buildSwarmPlotControls(obj)
        %BUILDSWARMPLOTCONTROLS Bind violin grouping, variable, and appearance settings.

            variables = oops.model.ObjectMeasurements.plottableNames(obj.Project);
            obj.addSetting("Swarmplot","Y variable","SwarmPlot","YVariable",variables);

            % Show readable labels while retaining model property names as values.
            labels = oops.model.ObjectMeasurements.labels(variables,obj.Project);
            obj.SettingsUI.SwarmPlot.YVariable.Items = cellstr(labels);

            % Data selection and grouping.
            obj.addSetting("Swarmplot","Group points by","SwarmPlot","GroupingType",["Group","Label","Both"]);
            obj.addSetting("Swarmplot","Color points by","SwarmPlot","ColorMode",["Group","Label","Magnitude"]);

            % Point visibility followed by all marker-related appearance.
            obj.addSetting("Swarmplot","Show points","SwarmPlot","PointsVisible");
            obj.addSetting("Swarmplot","Marker size","SwarmPlot","MarkerSize");
            obj.addSetting("Swarmplot","Marker line width","SwarmPlot","MarkerLineWidth");
            obj.addSetting("Swarmplot","Jitter width","SwarmPlot","XJitterWidth");
            obj.addModeColorSetting("Swarmplot","Marker face color","SwarmPlot", ...
                "MarkerFaceColorMode","MarkerFaceColor",["Auto","Custom"],"Custom");
            obj.addSetting("Swarmplot","Marker face alpha","SwarmPlot","MarkerFaceAlpha");
            obj.addModeColorSetting("Swarmplot","Marker edge color","SwarmPlot", ...
                "MarkerEdgeColorMode","MarkerEdgeColor",["Auto","Custom"],"Custom");
            obj.addSetting("Swarmplot","Marker edge alpha","SwarmPlot","MarkerEdgeAlpha");

            % Violin visibility followed by fill and outline appearance.
            obj.addSetting("Swarmplot","Show violins","SwarmPlot","ViolinOutlinesVisible");
            obj.addSetting("Swarmplot","Violin line width","SwarmPlot","ViolinLineWidth");
            obj.addModeColorSetting("Swarmplot","Violin face color","SwarmPlot", ...
                "ViolinFaceColorMode","ViolinFaceColor",["auto","Custom"],"Custom");
            obj.addModeColorSetting("Swarmplot","Violin edge color","SwarmPlot", ...
                "ViolinEdgeColorMode","ViolinEdgeColor",["auto","Custom"],"Custom");
            obj.addSetting("Swarmplot","Violin edge alpha","SwarmPlot","ViolinEdgeAlpha");

            % Error-bar visibility followed by summary statistics and appearance.
            obj.addSetting("Swarmplot","Show error bars","SwarmPlot","ErrorBarsVisible");
            obj.addSetting("Swarmplot","Central statistic","SwarmPlot", ...
                "CentralStatistic",["mean","median"]);
            obj.addSetting("Swarmplot","Error statistic","SwarmPlot", ...
                "ErrorStatistic",["std","sem","iqr"]);
            obj.addSetting("Swarmplot","Central line width","SwarmPlot","CentralStatLineWidth");
            obj.addSetting("Swarmplot","Error-bar line width","SwarmPlot","ErrorBarsLineWidth");
            obj.addModeColorSetting("Swarmplot","Error-bar color","SwarmPlot", ...
                "ErrorBarsColorMode","ErrorBarsColor",["auto","Custom"],"Custom");

            % Data-tip detail applies to each visible swarm point.
            obj.addSetting("Swarmplot","Data-tip detail","SwarmPlot", ...
                "DataTipDetail",["Compact","Verbose"]);

            % General axes appearance.
            obj.addColorSetting("Swarmplot","Background","SwarmPlot","BackgroundColor");
            obj.addColorSetting("Swarmplot","Foreground","SwarmPlot","ForegroundColor");
        end

        function buildPolarHistogramControls(obj)
        %BUILDPOLARHISTOGRAMCONTROLS Bind scope, angular data, and appearance.

            item = "Polar histogram";
            domain = "PolarHistogram";
            variables = ["AzimuthMean","MidlineRelativeAzimuthMean", ...
                "NormalRelativeAzimuthMean","MidlineOrientationMean"];

            obj.addSetting(item,"Data",domain,"DataSource",["Group","Image"]);
            obj.addSetting(item,"Variable",domain,"Variable",variables);
            obj.SettingsUI.PolarHistogram.Variable.Items = cellstr( ...
                oops.model.ObjectMeasurements.labels(variables));
            obj.addSetting(item,"Number of bins",domain,"BinCount",[12 24 48 96]);

            % Wedge fill followed by wedge outline appearance.
            obj.addModeColorSetting(item,"Face color",domain, ...
                "WedgeFaceColorMode","WedgeFaceColor",["flat","interp","custom"],"custom");
            obj.addSetting(item,"Face alpha",domain,"WedgeFaceAlpha");
            obj.addModeColorSetting(item,"Edge color",domain, ...
                "WedgeEdgeColorMode","WedgeEdgeColor",["flat","interp","custom"],"custom");
            obj.addSetting(item,"Wedge line width",domain,"WedgeLineWidth");

            % Grid, label, circle, and axes appearance.
            obj.addColorSetting(item,"Gridlines",domain,"GridlinesColor");
            obj.addSetting(item,"Gridline width",domain,"GridlinesLineWidth");
            obj.addColorSetting(item,"Labels",domain,"LabelsColor");
            obj.addColorSetting(item,"Circle background",domain,"CircleBackgroundColor");
            obj.addColorSetting(item,"Circle edge",domain,"CircleColor");
            obj.addColorSetting(item,"Background",domain,"BackgroundColor");
        end

        function addColorSetting(obj,title,label,domain,name)
        %ADDCOLORSETTING Add a native RGB picker with the standard config binding.

            pane = obj.SettingsAccordion.getItem(title).Pane;

            if isempty(pane.Children)
                set(pane,'ColumnWidth',{'fit','1x'},'RowHeight',{}, ...
                    'Padding',[5 5 5 5],'ColumnSpacing',5,'RowSpacing',5);
            end

            row = numel(pane.RowHeight)+1;
            pane.RowHeight{row} = 'fit';

            text = uilabel(pane,'Text',label,'FontColor',[.85 .85 .85]);
            text.Layout.Row = row;
            text.Layout.Column = 1;

            control = uicolorpicker(pane, ...
                'Value',obj.Settings.(domain).(name), ...
                'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onSettingEdited(src)));
            control.Layout.Row = row;
            control.Layout.Column = 2;
            control.UserData = struct('Domain',domain,'Name',name);
            obj.SettingsUI.(domain).(name) = control;
        end

        function addModeColorSetting(obj,title,label,domain,modeName,colorName,choices,customValue)
        %ADDMODECOLORSETTING Place a color mode and its picker on one row.

            pane = obj.SettingsAccordion.getItem(title).Pane;

            if ~isfield(obj.SettingsUI,domain)
                obj.SettingsUI.(domain) = struct();
            end

            if isempty(pane.Children)
                set(pane,'ColumnWidth',{'fit','1x'},'RowHeight',{}, ...
                    'Padding',[5 5 5 5],'ColumnSpacing',5,'RowSpacing',5);
            end

            % One labeled row whose value cell contains the mode and picker.
            row = numel(pane.RowHeight)+1;
            pane.RowHeight{row} = 'fit';

            text = uilabel(pane,'Text',label,'FontColor',[.85 .85 .85]);
            text.Layout.Row = row;
            text.Layout.Column = 1;

            controls = uigridlayout(pane,[1 2], ...
                'RowHeight',{'fit'},'ColumnWidth',{'1x','fit'}, ...
                'Padding',0,'ColumnSpacing',5,'BackgroundColor',[.18 .18 .18]);
            controls.Layout.Row = row;
            controls.Layout.Column = 2;

            mode = uidropdown(controls, ...
                'Items',cellstr(string(choices)), ...
                'ItemsData',cellstr(string(choices)), ...
                'Value',obj.Settings.(domain).(modeName), ...
                'ValueChangedFcn',@(src,~) obj.runCallback( ...
                    @() obj.onPairedColorModeEdited(src)));
            mode.Layout.Column = 1;
            mode.BackgroundColor = [.3 .3 .3];
            mode.FontColor = [.9 .9 .9];

            color = uicolorpicker(controls, ...
                'Value',obj.Settings.(domain).(colorName), ...
                'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onSettingEdited(src)));
            color.Layout.Column = 2;

            mode.UserData = struct('Domain',domain,'Name',modeName, ...
                'ColorControl',color,'CustomValue',string(customValue));
            color.UserData = struct('Domain',domain,'Name',colorName);
            obj.SettingsUI.(domain).(modeName) = mode;
            obj.SettingsUI.(domain).(colorName) = color;
            obj.refreshPairedColorControl(mode);
        end

        function buildLabels(obj)
        %BUILDLABELS Display the project label registry and its active shortcut target.

            % Accordion item grid containing the project label list.
            pane = obj.SettingsAccordion.getItem("Labels").Pane;
            set(pane,'RowHeight',{140},'ColumnWidth',{'1x'},'Padding',0);

            % Plain tree selection chooses the active label; object checks remain separate.
            obj.LabelsTree = uitree(pane,'checkbox','Tag','oops.labels', ...
                'BackgroundColor',[.18 .18 .18],'FontColor',[.9 .9 .9], ...
                'SelectionChangedFcn',@(~,~) obj.runCallback(@() obj.onLabelSelected()), ...
                'CheckedNodesChangedFcn',@(~,~) obj.runCallback(@() obj.onLabelChecksChanged()));
            obj.LabelsTree.Tooltip = ...
                'Highlight to activate a label; check labels for merge operations.';
            obj.LabelsTree.ContextMenu = obj.labelMenu("");
            obj.refreshLabels();
        end

        function tree = buildTree(obj,title,height)
        %BUILDTREE Highlight one active child; check any number of batch children.

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem(title).Pane;
            set(pane,'RowHeight',{height},'ColumnWidth',{'1x'},'Padding',0);

            % Checkbox tree separating highlighted active state from checked batch state.
            tree = uitree(pane,'checkbox','Tag',char("oops."+lower(title)), ...
                'BackgroundColor',[.18 .18 .18],'FontColor',[.9 .9 .9], ...
                'SelectionChangedFcn',@(src,~) obj.runCallback(@() obj.onTreeChanged(src,title,false)), ...
                'CheckedNodesChangedFcn',@(src,~) obj.runCallback(@() obj.onTreeChanged(src,title,true)));
            tree.Tooltip = 'Highlight to activate; check boxes for batch operations.';
            tree.ContextMenu = obj.navigationMenu(title,"");
        end

        function buildSummary(obj)
        %BUILDSUMMARY Keep domain selection independent of navigation and views.

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem("Summary").Pane;
            set(pane,'ColumnWidth',{'1x'},'RowHeight',{'fit',320}, ...
                'Padding',5,'RowSpacing',5);

            obj.SummaryDomain = uidropdown(pane, ...
                'Items',{'Project','Image','Group','Object'},'Value','Project', ...
                'ValueChangedFcn',@(~,~) obj.runCallback(@() obj.refreshSummary()));
            obj.SummaryDomain.Layout.Row = 1;
            obj.SummaryTable = uitable(pane,'ColumnName',{},'ColumnEditable',false);
            obj.SummaryTable.Layout.Row = 2;
        end

        function refreshSummary(obj)
        %REFRESHSUMMARY Resolve the active domain and assign only changed table data.
        % This path deliberately does not refresh viewers or navigation controls.

            if obj.Closing || isempty(obj.SummaryTable)
                return;
            end

            switch string(obj.SummaryDomain.Value)
                case "Project"

                    % Project or active group/image/object chosen by the summary-domain dropdown.
                    member = obj.Project;
                case "Group"
                    member = obj.Project.ActiveGroup;
                case "Image"
                    member = obj.Project.ActiveImage;
                case "Object"
                    member = obj.Project.ActiveObject;
            end

            % Summary table for that member, empty when no member is active.
            data = [];

            if ~isempty(member)
                data = member.SummaryTable;
            end

            if ~isequaln(obj.SummaryTable.Data,data)
                obj.SummaryTable.Data = data;
            end

        end

        function addSetting(obj,title,label,domain,name,choices)
        %ADDSETTING Register a typed setting control with a shared edit callback.
        % UserData is the binding; setters and model events remain the source of truth.

            if nargin < 6
                choices = [];
            end

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem(title).Pane;

            if ~isfield(obj.SettingsUI,domain)
                obj.SettingsUI.(domain) = struct();
            end

            if isempty(pane.Children)
                set(pane,'ColumnWidth',{'fit','1x'},'RowHeight',{},'Padding',[5 5 5 5], ...
                    'ColumnSpacing',5,'RowSpacing',5);
            end

            % Next grid row allocated for this control or label.
            row = numel(pane.RowHeight)+1;
            pane.RowHeight{row} = 'fit';

            % Label displaying the setting's user-facing name.
            text = uilabel(pane,'Text',label,'FontColor',[.85 .85 .85]);
            text.Layout.Row = row;
            text.Layout.Column = 1;

            % Current setting value used to select and initialize the control type.
            value = obj.Settings.(domain).(name);

            % Shared edit callback that resolves the control's stored binding.
            callback = @(src,~) obj.runCallback(@() obj.onSettingEdited(src));

            if ~isempty(choices)

                if isnumeric(choices)

                    % Readable dropdown labels for the supplied choices.
                    items = cellstr(string(choices));

                    % Dropdown item data preserving the choices' numeric/text value types.
                    values = choices;
                else
                    items = cellstr(string(choices));
                    values = cellstr(string(choices));
                end

                % Bound UI component being constructed or synchronized.
                control = uidropdown(pane,'Items',items,'ItemsData',values,'Value',value, ...
                    'ValueChangedFcn',callback);
            elseif islogical(value)
                control = uicheckbox(pane,'Text','','Value',value,'ValueChangedFcn',callback);
            elseif isnumeric(value)
                control = uieditfield(pane,'numeric','Value',value,'ValueChangedFcn',callback);
            else
                control = uieditfield(pane,'text','Value',char(value),'ValueChangedFcn',callback);
            end

            control.Layout.Row = row;
            control.Layout.Column = 2;

            if isprop(control,'BackgroundColor')
                control.BackgroundColor = [.3 .3 .3];
            end

            if isprop(control,'FontColor')
                control.FontColor = [.9 .9 .9];
            end

            control.UserData = struct('Domain',domain,'Name',name);
            obj.SettingsUI.(domain).(name) = control;
        end

        function addSectionLabel(obj,title,label)
        %ADDSECTIONLABEL Separate chronological stages without another nested panel.

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem(title).Pane;

            % Next grid row allocated for this control or label.
            row = numel(pane.RowHeight)+1;
            pane.RowHeight{row} = 'fit';

            % Bound UI component being constructed or synchronized.
            control = uilabel(pane,'Text',label,'FontWeight','bold','FontColor',[.85 .85 .85]);
            control.Layout.Row = row;
            control.Layout.Column = [1 2];
        end

        function buildSegmentationAdjustments(obj,definitions)
        %BUILDSEGMENTATIONADJUSTMENTS Build scalar controls from algorithm metadata.

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem("Mask").Pane;

            % Read each algorithm's control definitions.
            for definitionIndex = 1:numel(definitions)

                definition = definitions(definitionIndex);

                % Valid structure field used only to retain this algorithm's controls.
                algorithmField = matlab.lang.makeValidName(definition.ID);

                % Create a scalar slider for each adjustable algorithm parameter.
                parameters = definition.ParameterDefinitions;

                for k = 1:numel(parameters)
                    parameter = parameters(k);

                    if ~parameter.Adjustable
                        continue;
                    end

                    % Next grid row allocated for this control or label.
                    row = numel(pane.RowHeight)+1;
                    pane.RowHeight{row} = 'fit';

                    % Bound UI component being constructed or synchronized.
                    control = matlabx.ui.control.Slider(pane,'Title',char(parameter.Label), ...
                        'ValueMode','scalar','Limits',parameter.Limits, ...
                        'Value',mean(parameter.Limits),'ValueDisplayFormat','%.2f', ...
                        'FontColor',[.9 .9 .9],'BackgroundColor',[.18 .18 .18], ...
                        'ValueChangingFcn',@(src,~) obj.runCallback(@() obj.onSegmentationAdjustment(src,false)), ...
                        'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onSegmentationAdjustment(src,true)));
                    control.Layout.Row = row;
                    control.Layout.Column = [1 2];
                    control.UserData = struct('Algorithm',definition.ID,'Name',parameter.Name);
                    obj.SegmentationUI.(algorithmField).(parameter.Name) = control;
                end

            end

            row = numel(pane.RowHeight)+1;
            pane.RowHeight{row} = 'fit';

            % Label reporting the committed recipe and retained-object counts.
            status = uilabel(pane,'Text','Run segmentation to adjust parameters.', ...
                'FontColor',[.85 .85 .85]); status.Layout.Row = row; status.Layout.Column = [1 2];
            obj.SegmentationUI.Status = status;
            row = row+1;
            pane.RowHeight{row} = 'fit';

            % Button restoring the algorithm-selected segmentation parameters.
            reset = uibutton(pane,'Text','Reset to automatic', ...
                'ButtonPushedFcn',@(~,~) obj.runCallback(@() obj.resetSegmentationAdjustment()));
            reset.Layout.Row = row;
            reset.Layout.Column = [1 2];
            obj.SegmentationUI.Reset = reset;
        end

        function refreshSegmentationControls(obj)
        %REFRESHSEGMENTATIONCONTROLS Show parameters for the selected algorithm.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Project algorithm currently selected for new segmentation runs.
            algorithm = obj.Settings.Segmentation.Algorithm;

            % Whether the active image has a committed recipe matching that algorithm.
            ready = ~isempty(image) && ~isempty(image.SegmentationParameters) && ...
                image.SegmentationParameters.Algorithm == algorithm;

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem("Mask").Pane;

            % Whether the selected algorithm exposes any adjustable parameters.
            adjustable = false;

            % Synchronize parameter controls for every algorithm in the catalog.
            definitions = oops.analysis.segment.algorithms();

            for definitionIndex = 1:numel(definitions)

                definition = definitions(definitionIndex);

                % Valid structure field containing this algorithm's controls.
                algorithmField = matlab.lang.makeValidName(definition.ID);

                % Show and populate only the selected algorithm's adjustable controls.
                parameters = definition.ParameterDefinitions;

                for k = 1:numel(parameters)
                    parameter = parameters(k);

                    if ~parameter.Adjustable
                        continue;
                    end

                    % Bound UI component being constructed or synchronized.
                    control = obj.SegmentationUI.(algorithmField).(parameter.Name);

                    % Whether this parameter control belongs to the selected algorithm.
                    visible = definition.ID == algorithm;
                    control.Visible = matlab.lang.OnOffSwitchState(visible);

                    if visible
                        pane.RowHeight{control.Layout.Row} = 'fit';
                        adjustable = true;
                    else
                        pane.RowHeight{control.Layout.Row} = 0;
                    end

                    if isprop(control,'Enable')
                        control.Enable = matlab.lang.OnOffSwitchState(ready && visible);
                    end

                    if ready && visible
                        control.Value = image.SegmentationParameters.Values.(parameter.Name);
                        control.Title = char(parameter.Label+" ("+lower(image.SegmentationParameters.Mode)+")");
                    else
                        control.Value = mean(parameter.Limits);
                        control.Title = char(parameter.Label);
                    end

                end

            end

            % Recipe/status label below the adjustment controls.
            status = obj.SegmentationUI.Status;

            % Automatic-parameter reset button paired with the status label.
            reset = obj.SegmentationUI.Reset;

            % Status label and reset button to show/hide together.
            statusControls = {status,reset};

            % Show or hide the status/reset controls together.
            for k = 1:numel(statusControls)
                control = statusControls{k};
                control.Visible = matlab.lang.OnOffSwitchState(adjustable);

                if adjustable
                    pane.RowHeight{control.Layout.Row} = 'fit';
                else
                    pane.RowHeight{control.Layout.Row} = 0;
                end

            end

            reset.Enable = matlab.lang.OnOffSwitchState(ready);

            if ready

                % Image-local segmentation snapshot used for parameter display or adjustment.
                recipe = image.SegmentationParameters;
                retained = numel(image.Objects);

                if isfield(image.MaskProvenance.Diagnostics,'CandidateCount')
                    candidates = ...
                        image.MaskProvenance.Diagnostics.CandidateCount;
                    status.Text = sprintf('%s: %d of %d objects retained', ...
                        recipe.Mode,retained,candidates);
                else
                    status.Text = sprintf('%s: %d objects retained', ...
                        recipe.Mode,retained);
                end
            else
                status.Text = 'Run segmentation to adjust parameters.';
            end

        end

        function onSegmentationAdjustment(obj,control,commit)
        %ONSEGMENTATIONADJUSTMENT Preview without replacing objects; commit on release.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Control metadata identifying the target algorithm and parameter name.
            binding = control.UserData;

            if isempty(image) || isempty(image.SegmentationParameters) || ...
                    image.SegmentationParameters.Algorithm ~= binding.Algorithm
                obj.refreshSegmentationControls();
                return;
            end

            if commit
                obj.commitSegmentationAdjustment(image,binding.Name,control.Value);
            else
                % Current puncta thresholding is cheap on the cached enhanced image.
                % Future adjustable algorithms may provide their own preview path.

                % Saved projects omit reconstructible enhancement arrays. Load the
                % source and rebuild that cache once before the first live preview.
                oops.analysis.Analyzer.ensureSegmentationCache(image);

                % Image-local segmentation snapshot used for parameter display or adjustment.
                recipe = image.SegmentationParameters.withParameter(binding.Name,control.Value);

                % Algorithm metadata defining its implementation and adjustable controls.
                definition = oops.analysis.segment.algorithms(binding.Algorithm);

                if isempty(definition.PreviewFcn)
                    return;
                end

                % Unfiltered preview foreground produced from cached enhancement.
                candidate = definition.PreviewFcn( ...
                    image.Results.Segmentation,recipe);

                % Filtered preview mask displayed without committing model membership.
                preview = oops.analysis.segment.filter(candidate,image.Results.AverageIntensity,recipe);

                % Left and right panel source names in viewer order.
                names = [obj.Settings.View.LeftSource,obj.Settings.View.RightSource];

                % Left and right ImageAxes handles in panel order.
                viewers = {obj.LeftViewer,obj.RightViewer};

                % Replace only mask-viewer data with the preview; leave model objects untouched.
                for k = find(names == "Mask")
                    viewers{k}.ImageData = matlabx.image.Image5D.fromComponents(preview,Names="Mask");
                end

            end

        end

        function resetSegmentationAdjustment(obj)
        %RESETSEGMENTATIONADJUSTMENT Restore automatic values through the headless analyzer.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            if isempty(image) || isempty(image.SegmentationParameters)
                return;
            end

            obj.commitSegmentationAdjustment(image,"Automatic",[]);
        end

        function commitSegmentationAdjustment(obj,image,name,value)
        %COMMITSEGMENTATIONADJUSTMENT Perform analysis and one focused UI reconciliation.
        % Keep the guard through activation; neither model events nor cleanup
        % should launch another refresh. Numeric intensity/FPM sources are unchanged.

            % Processing-guard state saved for restoration after this operation.
            previous = obj.Processing;
            obj.Processing = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.restoreProcessing(previous));
            oops.analysis.Analyzer.adjustSegmentation(image,name,value,obj.Settings);
            obj.reconcileActive();

            % Left and right panel source names in viewer order.
            names = [obj.Settings.View.LeftSource,obj.Settings.View.RightSource];
            obj.ViewerKeys(names == "Mask") = "";
            clear guard;

            if ~previous
                oops.Log.INFO("Refreshing segmentation display for " + image.Name + ".");
                obj.refreshNavigation();
                obj.refreshViewers(false,false);
                obj.refreshSegmentationControls();
            end

        end

        function buildDisplayLimits(obj)
        %BUILDDISPLAYLIMITS Build one-shot and navigation policies for each domain.

            % Create independent policy buttons and a manual range for each display domain.
            for domain = ["Intensity","Order"]

                % Accordion item grid that owns the controls being created or updated.
                pane = obj.SettingsAccordion.getItem("Display Limits").Pane;

                % Next grid row allocated to the manual range slider.
                row = numel(pane.RowHeight)+1;
                pane.RowHeight{row} = 'fit';

                % Range slider used to preview and store an explicit image range.
                control = matlabx.ui.control.Slider(pane,'Title',char(domain), ...
                    'ValueMode','range','Limits',[0 1],'Value',[0 1], ...
                    'ValueDisplayFormat','%.2f','FontColor',[.9 .9 .9], ...
                    'BackgroundColor',[.18 .18 .18], ...
                    'ValueChangingFcn',@(src,~) obj.runCallback(@() obj.onDisplayLimitsEdited(src,false)), ...
                    'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onDisplayLimitsEdited(src,true)));
                control.UserData = domain;
                control.Layout.Row = row;
                control.Layout.Column = [1 2];
                obj.DisplayLimitUI.(domain) = control;

                % Next grid row allocated to the four evenly spaced policy buttons.
                row = numel(pane.RowHeight)+1;
                pane.RowHeight{row} = 'fit';

                % One-row host keeping the four display-limit actions evenly spaced.
                buttonGrid = uigridlayout(pane,[1 4], ...
                    'ColumnWidth',{'1x','1x','1x','1x'}, ...
                    'RowHeight',{'fit'},'ColumnSpacing',4, ...
                    'Padding',[0 0 0 0],'BackgroundColor',[.18 .18 .18]);
                buttonGrid.Layout.Row = row;
                buttonGrid.Layout.Column = [1 2];

                % Immediate actions calculate and store one range for the active image.
                reset = uibutton(buttonGrid,'push','Text','Reset', ...
                    'ButtonPushedFcn',@(~,~) obj.runCallback( ...
                    @() obj.onDisplayLimitAction(domain,"Reset")));
                auto = uibutton(buttonGrid,'push','Text','Auto', ...
                    'ButtonPushedFcn',@(~,~) obj.runCallback( ...
                    @() obj.onDisplayLimitAction(domain,"Auto")));

                % Persistent navigation modes are exclusive and synchronized from settings.
                keepAuto = uibutton(buttonGrid,'state','Text','Keep Auto', ...
                    'ValueChangedFcn',@(src,~) obj.runCallback( ...
                    @() obj.onDisplayLimitModeChanged(domain,"KeepAuto",src.Value)));
                lock = uibutton(buttonGrid,'state','Text','Lock', ...
                    'ValueChangedFcn',@(src,~) obj.runCallback( ...
                    @() obj.onDisplayLimitModeChanged(domain,"Lock",src.Value)));

                obj.DisplayLimitUI.Controls.(domain) = struct( ...
                    'Reset',reset,'Auto',auto,'KeepAuto',keepAuto,'Lock',lock);

                if domain == "Order"
                    obj.addSetting("Display Limits","Scaling method","Display", ...
                        "OrderAutoScaleMethod",["Contrast","Zero to max","Data range"]);
                end
            end

        end

        function refreshDisplayLimits(obj)
        %REFRESHDISPLAYLIMITS Show effective limits while preserving stored manual values.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Synchronize each display-domain slider with the active image's effective limits.
            for domain = ["Intensity","Order"]

                % Bound UI component being constructed or synchronized.
                control = obj.DisplayLimitUI.(domain);

                % Buttons controlling one-shot ranges and navigation behavior.
                buttons = obj.DisplayLimitUI.Controls.(domain);

                % Whether the active image has data for the current display-limit domain.
                ready = ~isempty(image);

                if isprop(control,'Enable')
                    control.Enable = matlab.lang.OnOffSwitchState(ready);
                end

                for name = ["Reset","Auto","KeepAuto","Lock"]
                    buttons.(name).Enable = matlab.lang.OnOffSwitchState(ready);
                end

                buttons.KeepAuto.Value = obj.Settings.Display.("KeepAutoDisplay"+domain);
                buttons.Lock.Value = obj.Settings.Display.("LockDisplay"+domain);

                if ready

                    % Match edit-field formatting and committed precision to display pixels.
                    if domain == "Intensity"
                        [detectorLimits,~] = oops.analysis.detectorRange(image.Input);
                        integerDisplay = ~isempty(detectorLimits);
                    else
                        integerDisplay = false;
                    end

                    if integerDisplay
                        control.ValueDisplayFormat = '%d';
                        control.RoundValues = 'on';
                        control.RoundDigits = 0;
                    else
                        control.ValueDisplayFormat = '%.2f';
                        control.RoundValues = 'off';
                    end

                    % Effective display range and slider bounds resolved for this image/domain.
                    [value,bounds] = oops.render.displayLimits(image,domain,obj.Settings);
                    control.Limits = bounds;
                    control.Value = value;
                else
                    control.ValueDisplayFormat = '%.2f';
                    control.RoundValues = 'off';
                    control.Limits = [0 1];
                    control.Value = [0 1];
                end

            end

        end

        function onDisplayLimitsEdited(obj,control,commit)
        %ONDISPLAYLIMITSEDITED Preview both viewers; persist only when editing finishes.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            if isempty(image)
                return;
            end

            % Display/settings domain selected by the current control.
            domain = string(control.UserData);

            % Range selected by the intensity/order display-limit slider.
            value = control.Value;

            if domain == "Intensity"
                value = oops.render.normalizeIntensityDisplayRange(image,value);
            end

            if value(1) >= value(2)
                obj.refreshDisplayLimits();
                return;
            end

            if commit

                % Existing processing state restored after the atomic policy update.
                previous = obj.Processing;
                obj.Processing = true;
                guard = onCleanup(@() obj.restoreProcessing(previous));
                image.setDisplayRange(domain,value);
                obj.Settings.Display.("KeepAutoDisplay"+domain) = false;

                if obj.Settings.Display.("LockDisplay"+domain)
                    obj.Settings.Display.("LockedDisplayRange"+domain) = value;
                end

                clear guard;

                if ~previous
                    obj.refreshViewers(true);
                end
            else
                obj.applyDisplayRangeToViewers(domain,value);

            end

        end

        function onDisplayLimitAction(obj,domain,action)
        %ONDISPLAYLIMITACTION Apply a one-shot Reset or Auto range to the active image.

            % Active image receiving the newly calculated stored display range.
            image = obj.Project.ActiveImage;

            if isempty(image)
                return;
            end

            % Reset and Auto ranges calculated from the current image and domain.
            [~,~,ranges] = oops.render.displayLimits(image,domain,obj.Settings);
            value = ranges.(action);

            if domain == "Intensity"
                value = oops.render.normalizeIntensityDisplayRange(image,value);
            end

            % Existing processing state restored after the atomic policy update.
            previous = obj.Processing;
            obj.Processing = true;
            guard = onCleanup(@() obj.restoreProcessing(previous));
            image.setDisplayRange(domain,value);
            obj.Settings.Display.("KeepAutoDisplay"+domain) = false;

            if obj.Settings.Display.("LockDisplay"+domain)
                obj.Settings.Display.("LockedDisplayRange"+domain) = value;
            end

            clear guard;

            if ~previous
                obj.refreshViewers(true);
            end

        end

        function onDisplayLimitModeChanged(obj,domain,mode,value)
        %ONDISPLAYLIMITMODECHANGED Enable an exclusive navigation scaling policy.

            % Active image supplies the effective range captured when Lock is enabled.
            image = obj.Project.ActiveImage;

            if isempty(image)
                obj.refreshDisplayLimits();
                return;
            end

            % Existing processing state restored after the atomic policy update.
            previous = obj.Processing;
            obj.Processing = true;
            guard = onCleanup(@() obj.restoreProcessing(previous));

            if mode == "Lock" && value
                current = oops.render.displayLimits(image,domain,obj.Settings);
                obj.Settings.Display.("LockedDisplayRange"+domain) = current;
            end

            obj.Settings.Display.(mode+"Display"+domain) = logical(value);
            clear guard;

            if ~previous
                obj.refreshViewers(true);
            end

        end

        function buildViewers(obj)
        %BUILDVIEWERS Nest each ImageAxes in its own panel/grid; span both columns with log.

            % Panel titles for the two persistent viewer containers.
            panels = gobjects(1,2);

            % Create the left/right panel, nested grid, and persistent ImageAxes.
            for k = 1:2

                % Left/right label identifying the current viewer panel.
                side = ["Left","Right"];
                side = side(k);
                panels(k) = uipanel(obj.RightPane,'Title',char(side),'FontSize',12, ...
                    'Tag',char("oops."+lower(side)+"Panel"),'BackgroundColor',[.12 .12 .12]);
                panels(k).Layout.Row = 1;
                panels(k).Layout.Column = k;

                % Nested grid allocating the ImageAxes inside its panel.
                grid = uigridlayout(panels(k),[1 1],'Padding',0, ...
                    'RowHeight',{'1x'},'ColumnWidth',{'1x'},'BackgroundColor',[.12 .12 .12]);
                obj.ViewerGrids{k} = grid;

                % Persistent ImageAxes created for the current panel.
                viewer = matlabx.ui.axes.ImageAxes(grid,'Name',char(side+"Viewer"), ...
                    'CData',[],'Tools',{'Zoom','Mask','Boundaries','RectangleSelect','Colorbar','DisplayLimits'},'Colormap',gray(256), ...
                    'CLim',[0 1],'FontSize',12);
                viewer.Tools.RectangleSelect.TargetTypes = "Boundary";

                % One collection batches all model-object geometry while the
                % native tool owns activation, selection, and deletion gestures.
                collection = viewer.Overlays.createBoundaryCollection();
                boundaryTool = viewer.Tools.Boundaries;
                boundaryTool.BoundaryActivatedFcn = ...
                    @(~,d) obj.runCallback(@() obj.onObjectBoundaryActivated(d));
                boundaryTool.BoundarySelectionChangedFcn = ...
                    @(~,d) obj.runCallback(@() obj.onObjectBoundarySelectionChanged(d));
                boundaryTool.BoundariesDeleteRequestedFcn = ...
                    @(~,d) obj.runCallback(@() obj.onObjectBoundariesDeleteRequested(d));

                % Boundaries start hidden. Turning the collection back on asks
                % OOPS to populate the current image before it is displayed.
                viewer.disableTool("Boundaries");
                obj.ViewerListeners(end+1) = addlistener(collection,'Visible','PostSet', ...
                    @(~,~) obj.runCallback(@() ...
                    obj.onBoundaryCollectionVisibilityChanged(collection)));
                obj.ObjectBoundaryCollections{k} = collection;

                % Passive axial field uses MATLABX's application-overlay layer.
                field = oops.render.OrientationField();
                mount = viewer.mountOverlay(field);
                mount.Visible = 'off';
                tool = oops.ui.axes.tools.OrientationField(viewer,mount);
                tool.RefreshRequestedFcn = @(~,~) obj.runCallback(@() ...
                    obj.refreshOrientationFields([obj.Settings.View.LeftSource, ...
                    obj.Settings.View.RightSource]));
                viewer.installTool(tool);
                obj.OrientationFields{k} = field;
                obj.OrientationFieldTools{k} = tool;

                if k == 1
                    obj.LeftViewer = viewer;
                else
                    obj.RightViewer = viewer;
                end

                obj.ViewerListeners(end+1) = addlistener(viewer,'DisplayStateChanged', ...
                    @(src,e) obj.runCallback(@() obj.onViewerDisplayStateChanged(src,e)));

            end

            obj.ViewerPanels = panels;

            % Log panel spanning the full width beneath the two viewers.
            panel = uipanel(obj.RightPane,'Title','Log','BackgroundColor',[.12 .12 .12]);
            panel.Layout.Row = 2;
            panel.Layout.Column = [1 2];
            grid = uigridlayout(panel,[1 1],'Padding',0,'RowHeight',{'1x'},'ColumnWidth',{'1x'});
            obj.LogTextArea = uitextarea(grid,'Editable','off','Value',{''}, ...
                'BackgroundColor',[.18 .18 .18],'FontColor',[.9 .9 .9]);
            obj.Fig.SizeChangedFcn = @(~,~) obj.runCallback(@() obj.resizeViewers());
        end

        function buildObjectViewers(obj)
        %BUILDOBJECTVIEWERS Create the persistent 2-by-2 active-object display grid.

            % Alternate right-side container occupying the normal right panel's slot.
            objectGrid = uigridlayout(obj.RightPane,[2 3], ...
                'ColumnWidth',{'1x','1x',0},'RowHeight',{'1x','1x'}, ...
                'Padding',0,'ColumnSpacing',5,'RowSpacing',5, ...
                'BackgroundColor',[.12 .12 .12],'Visible','off');
            objectGrid.Layout.Row = 1;
            objectGrid.Layout.Column = 2;

            % Fixed quadrant order shared by construction and refresh logic.
            titles = ["Corrected intensity","Order","Mask","Azimuth"];
            panels = gobjects(1,4);
            viewers = cell(1,4);

            for k = 1:4

                % Row and column placing this source in reading order.
                row = ceil(k/2);
                % The four viewers occupy a compact block in the first two columns.
                % Column three is reserved for object navigation controls.
                column = mod(k-1,2)+1;

                % Titled panel and zero-padding host preserve ImageAxes chrome sizing.
                panels(k) = uipanel(objectGrid,'Title',char(titles(k)), ...
                    'FontSize',12,'BackgroundColor',[.12 .12 .12]);
                panels(k).Layout.Row = row;
                panels(k).Layout.Column = column;

                host = uigridlayout(panels(k),[1 1], ...
                    'Padding',0,'RowHeight',{'1x'},'ColumnWidth',{'1x'}, ...
                    'BackgroundColor',[.12 .12 .12]);

                % Object viewers need navigation, mask flicker, and display inspection.
                viewers{k} = matlabx.ui.axes.ImageAxes(host, ...
                    'Name',char("Object"+erase(titles(k)," ")), ...
                    'CData',[],'Tools',{'Zoom','Mask','Colorbar'}, ...
                    'Colormap',gray(256),'CLim',[0 1],'FontSize',12);

                % Passive boundary content displays only the active object's outline.
                boundary = oops.render.ObjectBoundary();
                boundaryMount = viewers{k}.mountOverlay(boundary);
                boundaryMount.Visible = 'off';
                boundaryTool = oops.ui.axes.tools.OverlayVisibility( ...
                    viewers{k},boundaryMount,"ActiveObjectBoundary", ...
                    Tooltip="Show/Hide Object Boundary", ...
                    MenuLabel="Show object boundary", ...
                    Icon=matlabx.internal.Paths.icons('ObjectsWhiteFGTransparentBG.svg'));
                boundaryTool.RefreshRequestedFcn = @(~,~) obj.runCallback(@() ...
                    obj.refreshObjectViewerOverlays());
                viewers{k}.installTool(boundaryTool);

                % Object-restricted orientation segments share the main-view renderer.
                field = oops.render.OrientationField();
                fieldMount = viewers{k}.mountOverlay(field);
                fieldMount.Visible = 'off';
                fieldTool = oops.ui.axes.tools.OrientationField(viewers{k},fieldMount);
                fieldTool.RefreshRequestedFcn = @(~,~) obj.runCallback(@() ...
                    obj.refreshObjectViewerOverlays());
                viewers{k}.installTool(fieldTool);

                % A single passive line displays the computed object midline.
                midline = oops.render.ObjectMidline();
                midlineMount = viewers{k}.mountOverlay(midline);
                midlineMount.Visible = 'off';
                midlineTool = oops.ui.axes.tools.OverlayVisibility( ...
                    viewers{k},midlineMount,"ObjectMidline", ...
                    Tooltip="Show/Hide Object Midline", ...
                    MenuLabel="Show object midline", ...
                    Icon=matlabx.internal.Paths.icons('DrawLineWhiteFGTransparentBG.svg'));
                midlineTool.RefreshRequestedFcn = @(~,~) obj.runCallback(@() ...
                    obj.refreshObjectViewerOverlays());
                viewers{k}.installTool(midlineTool);

                obj.ObjectViewerBoundaryContents{k} = boundary;
                obj.ObjectViewerBoundaryTools{k} = boundaryTool;
                obj.ObjectViewerOrientationFields{k} = field;
                obj.ObjectViewerOrientationTools{k} = fieldTool;
                obj.ObjectViewerMidlineContents{k} = midline;
                obj.ObjectViewerMidlineTools{k} = midlineTool;
            end

            % Narrow right gutter with vertically centered square navigation buttons.
            navigation = uigridlayout(objectGrid,[5 1], ...
                'ColumnWidth',{'1x'},'RowHeight',{'1x','fit','fit','1x','fit'}, ...
                'Padding',0,'RowSpacing',5, ...
                'BackgroundColor',[.12 .12 .12]);
            navigation.Layout.Row = [1 2];
            navigation.Layout.Column = 3;

            previous = uibutton(navigation,'Text','', ...
                'Icon',matlabx.internal.Paths.icons('ChevronUpWhiteFGTransparentBG.svg'), ...
                'Tooltip','Previous object', ...
                'ButtonPushedFcn',@(~,~) obj.runCallback(@() obj.stepActiveObject(-1)));
            previous.Layout.Row = 2;

            next = uibutton(navigation,'Text','', ...
                'Icon',matlabx.internal.Paths.icons('ChevronDownWhiteFGTransparentBG.svg'), ...
                'Tooltip','Next object', ...
                'ButtonPushedFcn',@(~,~) obj.runCallback(@() obj.stepActiveObject(1)));
            next.Layout.Row = 3;

            remove = uibutton(navigation,'Text','', ...
                'Icon',matlabx.internal.Paths.icons('TrashWhiteFGTransparentBG.svg'), ...
                'Tooltip','Delete active object', ...
                'ButtonPushedFcn',@(~,~) obj.runCallback(@() obj.deleteActiveObject()));
            remove.Layout.Row = 5;

            obj.ObjectViewerGrid = objectGrid;
            obj.ObjectNavigationGrid = navigation;
            obj.ObjectViewerPanels = panels;
            obj.ObjectViewers = viewers;
        end

        function buildPlots(obj)
        %BUILDPLOTS Create stable panel hosts and transferable plot renderers.

            scatterSettings = obj.Settings.ScatterPlot;
            swarmSettings = obj.Settings.SwarmPlot;

            % PlotAxes remain attached to their panels for the life of the GUI.
            obj.LeftPlotAxes = matlabx.ui.axes.PlotAxes(obj.ViewerGrids{1}, ...
                'Name',"LeftPlotAxes",'Visible','off', ...
                'BackgroundColor',scatterSettings.BackgroundColor, ...
                'ForegroundColor',scatterSettings.ForegroundColor);
            obj.LeftPlotAxes.Layout.Row = 1;
            obj.LeftPlotAxes.Layout.Column = 1;

            obj.RightPlotAxes = matlabx.ui.axes.PlotAxes(obj.ViewerGrids{2}, ...
                'Name',"RightPlotAxes",'Visible','off', ...
                'BackgroundColor',swarmSettings.BackgroundColor, ...
                'ForegroundColor',swarmSettings.ForegroundColor);
            obj.RightPlotAxes.Layout.Row = 1;
            obj.RightPlotAxes.Layout.Column = 1;

            % Renderers own primitive graphics and may transfer between hosts.
            obj.ScatterRenderer = matlabx.ui.axes.plot.ScatterRenderer();
            obj.SwarmRenderer = matlabx.ui.axes.plot.ViolinRenderer();
            obj.PolarHistogramRenderer = oops.plot.PolarHistogramRenderer();
        end

        function buildMenus(obj)
        %BUILDMENUS Build project, import, processing, and view commands.

            % File menu begins with project lifecycle commands.
            file = uimenu(obj.Fig,'Text','File');
            uimenu(file,'Text','New','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.newProject()));
            uimenu(file,'Text','Open...','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.chooseProject()));
            obj.MenuUI.Close = uimenu(file,'Text','Close','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.closeProject()));
            obj.MenuUI.Save = uimenu(file,'Text','Save...','Separator','on', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseProjectSave(false)));
            obj.MenuUI.SaveAs = uimenu(file,'Text','Save As...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseProjectSave(true)));

            obj.MenuUI.LoadImages = uimenu(file,'Text','Import polarization stacks...','Separator','on', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseFiles()));
            obj.MenuUI.Calibration = uimenu(file,'Text','Import calibration stacks...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseCalibrationFiles()));
            obj.MenuUI.AuxiliaryChannels = uimenu(file, ...
                'Text','Import auxiliary channels...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseAuxiliaryChannels()));
            obj.MenuUI.Export = uimenu(file,'Text','Export','Separator','on');
            uimenu(obj.MenuUI.Export,'Text','Summary tables (.xlsx)...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.exportSummaryTables()));

            % Edit menu manages ordered project-wide model collections.
            edit = uimenu(obj.Fig,'Text','Edit');
            obj.MenuUI.Edit = edit;
            uimenu(edit,'Text','Groups...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.manageCollection("Groups")));
            uimenu(edit,'Text','Labels...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.manageCollection("Labels")));
            uimenu(edit,'Text','Channels...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.manageCollection("Channels")));

            % Run menu exposing the complete pipeline and its individual stages.
            run = uimenu(obj.Fig,'Text','Run');
            obj.MenuUI.Run = run;
            uimenu(run,'Text','All','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.runAnalysis("All")));
            uimenu(run,'Text','Object detection','Separator','on','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.runAnalysis("ObjectDetection")));
            uimenu(run,'Text','Polarization analysis','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.runAnalysis("Polarization")));

            % View menu populated from the graphics-free preset catalog.
            view = uimenu(obj.Fig,'Text','View');
            obj.MenuUI.View = view;

            % Create one menu entry for each catalog-defined view preset.
            for preset = oops.app.viewPresets()
                % Definitions describe content; the controller owns its graphics.
                uimenu(view,'Text',char(preset.Name),'UserData',preset, ...
                    'MenuSelectedFcn',@(src,~) obj.runCallback(@() obj.applyViewPreset(src.UserData)));
            end

            % Project-wide object selection, labeling, and deletion commands.
            objects = uimenu(obj.Fig,'Text','Objects');
            obj.MenuUI.Objects = objects;
            operations = ["Select objects...","Clear object selection...", ...
                "Invert object selection...","Delete objects..."];
            actions = ["Select","Clear","Invert","Delete"];
            scopes = ["All","In current group","In current image"];
            scopeValues = ["Project","Group","Image"];

            for k = 1:numel(operations)
                parent = uimenu(objects,'Text',char(operations(k)));

                for j = 1:numel(scopes)
                    uimenu(parent,'Text',char(scopes(j)), ...
                        'UserData',struct('Action',actions(k),'Scope',scopeValues(j)), ...
                        'MenuSelectedFcn',@(src,~) obj.runCallback( ...
                            @() obj.applyObjectSelectionAction( ...
                            src.UserData.Action,src.UserData.Scope)));
                end
            end

            uimenu(objects,'Text','Select by property...','Separator','on', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.selectByProperty()));
            uimenu(objects,'Text','Label by property...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.labelByProperty()));
            uimenu(objects,'Text','Delete by property...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.deleteByProperty()));

            % Settings menu containing JSON save/load actions.
            settings = uimenu(obj.Fig,'Text','Settings');
            uimenu(settings,'Text','Save as app defaults','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.Settings.save()));
            uimenu(settings,'Text','Load app defaults','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.loadSettings()));

            % Help menu exposes runtime diagnostics without coupling them to a view.
            help = uimenu(obj.Fig,'Text','Help');
            obj.MenuUI.RuntimeStatus = uimenu(help,'Text','Runtime status...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.showRuntimeStatus()));

            obj.updateProjectUIState();
        end

        function applyViewPreset(obj,preset)
        %APPLYVIEWPRESET Set both panel choices before refreshing changed sources once.
        % Settings events still synchronize the accordion during the guarded update.

            % Settings object supplying the values for this operation.
            settings = obj.Settings.View;
            started = tic;
            oops.Log.DEBUG("Applying view preset: " + preset.Name + ...
                " [left=" + preset.Left.Source + ", right=" + preset.Right.Source + "].");

            % Processing-guard state saved for restoration after this operation.
            previous = obj.Processing;
            obj.Processing = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.restoreProcessing(previous));
            settings.LeftSource = preset.Left.Source;
            settings.RightSource = preset.Right.Source;
            clear guard;

            if ~previous
                obj.refreshViewers(false);
            end

            oops.Log.DEBUG(sprintf('Applied view preset %s in %.3f s.', ...
                preset.Name,toc(started)));

        end

        function restoreProcessing(obj,value)
        %RESTOREPROCESSING Restore a temporary event guard without another refresh.

            obj.Processing = value;
        end

        function bindEvents(obj)
        %BINDEVENTS Keep all settings and model subscriptions in the controller.

            % Subscribe once to project collection events used to reconcile navigation.
            for name = ["GroupAdded","GroupRemoved","ImagesRemoved","ObjectsChanged"]
                obj.Listeners(end+1) = addlistener(obj.Project,char(name), ...
                    @(~,~) obj.runCallback(@() obj.onCollectionChanged()));
            end

            obj.Listeners(end+1) = addlistener(obj.Project,'CalibrationChanged', ...
                @(~,e) obj.runCallback(@() obj.onCalibrationChanged(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'GroupChanged', ...
                @(~,~) obj.runCallback(@() obj.onGroupChanged()));
            obj.Listeners(end+1) = addlistener(obj.Project,'ImagesAdded', ...
                @(~,e) obj.runCallback(@() obj.onImagesAdded(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'NavigationChanged', ...
                @(~,e) obj.runCallback(@() obj.onNavigationChanged(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'DataChanged', ...
                @(~,e) obj.runCallback(@() obj.onDataChanged(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'LabelsChanged', ...
                @(~,~) obj.runCallback(@() obj.onLabelsChanged()));
            obj.Listeners(end+1) = addlistener(obj.Project,'ActiveLabelChanged', ...
                @(~,~) obj.runCallback(@() obj.syncActiveLabel()));
            obj.Listeners(end+1) = addlistener(obj.Project,'DirtyStateChanged', ...
                @(~,~) obj.runCallback(@() obj.updateProjectUIState()));
            obj.Listeners(end+1) = addlistener(obj.Settings,'Changed', ...
                @(~,e) obj.runCallback(@() obj.onSettingsChanged(e)));
        end

        function reconcileActive(obj)
        %RECONCILEACTIVE Choose a first child only when a collection currently lacks one.

            % Project whose hierarchy supplies the navigation/operation targets.
            p = obj.Project;

            if isempty(p.ActiveGroup) && ~isempty(p.Groups)
                p.setActiveGroup(p.Groups(1));
            end

            % Active/target group supplying its owned images and bookmarks.
            group = p.ActiveGroup;

            if ~isempty(group) && isempty(group.ActiveImage) && ~isempty(group.Images)
                group.setActiveImage(group.Images(1));
            end

            % Active image supplying data and object membership for this operation.
            image = p.ActiveImage;

            if ~isempty(image) && isempty(image.ActiveObject) && ~isempty(image.Objects)
                image.setActiveObject(image.Objects(1));
            end

        end

        function onCollectionChanged(obj)
        %ONCOLLECTIONCHANGED Reconcile removals/new children, then update navigation/display.

            if obj.Processing
                return;
            end

            obj.reconcileActive();
            obj.refreshMeasurementControls();
            obj.refreshNavigation();
            obj.refreshViewers(false);
        end

        function onGroupChanged(obj)
        %ONGROUPCHANGED Refresh names, swatches, summaries, and group-colored plots.

            if obj.Processing
                return;
            end

            obj.refreshNavigation();

            if any(ismember([obj.Settings.View.LeftSource, ...
                    obj.Settings.View.RightSource],["Scatterplot","Swarmplot","PolarHistogram"]))
                obj.refreshPlots();
            end
        end

        function onNavigationChanged(obj,e)
        %ONNAVIGATIONCHANGED Reflect ID state; batch changes never reset viewer state.

            if obj.Processing
                return;
            end

            started = tic;

            if nargin > 1
                oops.Log.DEBUG("Handling navigation change: domain=" + e.Domain + ...
                    ", owner=" + e.OwnerID + ", property=" + e.Name + ".");
            else
                oops.Log.DEBUG("Handling navigation refresh without event metadata.");
            end

            stage = tic;
            obj.refreshNavigation();
            oops.Log.DEBUG(sprintf('Refreshed navigation controls in %.3f s.',toc(stage)));

            % An explicit object activation or an image switch reveals the
            % remembered active object in the reused Objects tree.
            if nargin < 2 || (e.Domain == "Image" && e.Name == "ActiveObjectID")
                obj.scrollToActiveObject();
            end

            if nargin > 1 && e.Domain == "Image" && ...
                    ismember(e.Name,["SelectedObjectIDs","ActiveObjectID"])
                obj.syncOverlayState();

                if e.Name == "ActiveObjectID" && ...
                        obj.Settings.View.RightSource == "Objects"
                    stage = tic;
                    obj.refreshObjectViewers(false);
                    oops.Log.DEBUG(sprintf( ...
                        'Refreshed active-object viewers in %.3f s.',toc(stage)));
                end

                oops.Log.DEBUG(sprintf( ...
                    'Completed object navigation response in %.3f s.',toc(started)));
                return;
            end

            if nargin > 1 && startsWith(e.Name,"Selected")
                oops.Log.DEBUG(sprintf( ...
                    'Completed batch-selection navigation response in %.3f s.',toc(started)));
                return;
            end

            stage = tic;
            obj.refreshViewers(false);
            oops.Log.DEBUG(sprintf( ...
                'Refreshed viewers after navigation in %.3f s; total response %.3f s.', ...
                toc(stage),toc(started)));
        end

        function onDataChanged(obj,e)
        %ONDATACHANGED Refresh processed sources only for changes to the active image.

            if obj.Processing
                return;
            end

            % Semantic channel assignments alter the Image Display channel list
            % even when the displayed pixels and navigation hierarchy are unchanged.
            if ismember(e.Name,["PrimaryChannelID","AuxiliaryChannels"])
                obj.refreshColormapControls();
                obj.refreshMeasurementControls();
            end

            % Per-object measurement events need only the Object summary.
            % Collection/image outputs also affect project/group status counts.
            if e.ObjectID == "" || string(obj.SummaryDomain.Value) == "Object"
                obj.refreshSummary();
            end

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            if isempty(image) || image.ID ~= e.ImageID
                if any(ismember([obj.Settings.View.LeftSource, ...
                        obj.Settings.View.RightSource],["Scatterplot","Swarmplot","PolarHistogram"]))
                    obj.refreshPlots();
                end
                return;
            end

            if any(ismember([obj.Settings.View.LeftSource, ...
                    obj.Settings.View.RightSource],["Scatterplot","Swarmplot","PolarHistogram"]))
                obj.refreshPlots();
            end

            if e.Name == "Mask"
                % Only the mask source needs new image data. Other sources just
                % receive the updated alpha mask and object membership below.

                % Left and right panel source names in viewer order.
                names = [obj.Settings.View.LeftSource,obj.Settings.View.RightSource];
                obj.ViewerKeys(names == "Mask") = "";
                obj.ObjectViewerKey = "";
                obj.refreshViewers(false);
            elseif ismember(e.Name,["Results","DisplayRange"])
                obj.ObjectViewerKey = "";
                obj.refreshViewers(true);
            elseif e.Name == "ObjectLabels"
                obj.refreshOverlayAppearance();
                if obj.Settings.View.RightSource == "Objects"
                    obj.refreshObjectViewerOverlays();
                end
            elseif e.Name == "ObjectMidline" && ...
                    obj.Settings.View.RightSource == "Objects"
                obj.refreshObjectViewerOverlays();
            end

        end

        function refreshNavigation(obj)
        %REFRESHNAVIGATION Restore highlights/checks from model IDs without invoking actions.

            if obj.Refreshing || obj.Closing
                return;
            end

            obj.Refreshing = true;

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() obj.endRefresh());

            % Project whose hierarchy supplies the navigation/operation targets.
            p = obj.Project;

            obj.syncTree(obj.GroupsTree,p.Groups,p.ActiveGroupID,p.SelectedGroupIDs);

            % Active/target group supplying its owned images and bookmarks.
            group = p.ActiveGroup;

            if isempty(group)
                obj.syncTree(obj.ImagesTree,oops.model.Image.empty(0,1),"",strings(0,1));
            else
                obj.syncTree(obj.ImagesTree,group.Images,group.ActiveImageID,group.SelectedImageIDs);
            end

            % Active image supplying data and object membership for this operation.
            image = p.ActiveImage;

            objectsItem = obj.SettingsAccordion.getItem("Objects");

            if objectsItem.expanded

                if isempty(image)
                    obj.syncTree(obj.ObjectsTree,oops.model.Object.empty(0,1),"",strings(0,1));
                else
                    obj.syncTree(obj.ObjectsTree,image.Objects,image.ActiveObjectID,image.SelectedObjectIDs);
                end

                obj.ObjectsTreeDirty = false;
            else
                obj.ObjectsTreeDirty = true;
            end

            obj.refreshSummary();
        end

        function syncTree(obj,tree,children,activeID,selectedIDs)
        %SYNCTREE Reuse nodes whenever membership matches, preserving focus and scroll.

            % Desired child IDs in model collection order.
            ids = oops.model.internal.ids(children);

            % Existing tree nodes whose IDs are compared against desired membership.
            nodes = tree.Children;

            % IDs of existing nodes, in their current display order.
            oldIDs = strings(numel(nodes),1);

            % Collect existing node IDs to compare tree membership against the model.
            for k = 1:numel(nodes)
                oldIDs(k) = string(nodes(k).NodeData);
            end

            % Object nodes are reusable display slots. Their menus resolve the
            % current ID from UserData, so switching images need not recreate UI.
            reuseSlots = tree == obj.ObjectsTree;

            if reuseSlots
                retained = ismember(oldIDs,ids);

                if any(retained)
                    % Same-image deletions retain surviving handles, menus, and
                    % overlay-driven tree state even when their indices shift.
                    obj.deleteTreeNodes(nodes(~retained));
                    nodes = tree.Children;
                    oldIDs = oldIDs(retained);
                else
                    % A different image has unrelated IDs. Rebind the existing
                    % display slots and adjust only the difference in node count.
                    excess = nodes(numel(children)+1:end);
                    obj.deleteTreeNodes(excess);
                    nodes = tree.Children;
                    oldIDs = strings(0,1);
                end
            else
                removed = ~ismember(oldIDs,ids);
                obj.deleteTreeNodes(nodes(removed));
                nodes = nodes(~removed);
                oldIDs = oldIDs(~removed);

                % Collections currently append/remove children. If a future model
                % reorders them, rebuild that tree rather than displaying a wrong order.
                if ~isequal(oldIDs,ids(1:numel(oldIDs)))
                    obj.deleteTreeNodes(nodes);
                    nodes = tree.Children;
                end
            end

            % Create/relabel nodes for the current ordered child collection.
            for k = numel(nodes)+1:numel(children)

                % Tree node being created, inspected, or activated.
                node = uitreenode(tree,'Text',char(children(k).Name),'NodeData',children(k).ID);

                if tree == obj.GroupsTree
                    node.ContextMenu = obj.navigationMenu("Groups",children(k).ID);
                elseif tree == obj.ImagesTree
                    node.ContextMenu = obj.navigationMenu("Images",children(k).ID);
                elseif tree == obj.ObjectsTree
                    node.ContextMenu = obj.navigationMenu("Objects",children(k).ID);
                end

            end

            nodes = tree.Children;

            for k = 1:numel(nodes)

                if reuseSlots
                    nodes(k).NodeData = children(k).ID;
                    nodes(k).ContextMenu.UserData = children(k).ID;
                end

                % Current child label to synchronize without replacing its tree node.
                name = char(children(k).Name);

                if ~strcmp(nodes(k).Text,name)
                    nodes(k).Text = name;
                end

                if tree == obj.GroupsTree

                    % Circular swatch displaying the group's exact identifying color.
                    icon = matlabx.ui.icon.get( ...
                        Shape="circle",Color=children(k).Color,Size=16);

                    if ~isequal(string(nodes(k).Icon),icon)
                        nodes(k).Icon = char(icon);
                    end

                end

            end

            % Node matching the model's remembered active ID.
            active = nodes(ids == activeID);

            % Nodes matching the independent model-selected ID set.
            checked = nodes(ismember(ids,selectedIDs));

            if ~isequal(tree.SelectedNodes(:),active(:))

                if isempty(active)
                    tree.SelectedNodes = [];
                else
                    tree.SelectedNodes = active;
                end

            end

            if ~isequal(tree.CheckedNodes(:),checked(:))

                if isempty(checked)
                    tree.CheckedNodes = [];
                else
                    tree.CheckedNodes = checked(:)';
                end

            end

        end

        function onObjectsAccordionExpanded(obj)
        %ONOBJECTSACCORDIONEXPANDED Populate deferred object navigation on demand.

            item = obj.SettingsAccordion.getItem("Objects");

            if ~item.expanded || ~obj.ObjectsTreeDirty || isempty(obj.Project)
                return;
            end

            image = obj.Project.ActiveImage;

            if isempty(image)
                obj.syncTree(obj.ObjectsTree,oops.model.Object.empty(0,1),"",strings(0,1));
            else
                obj.syncTree(obj.ObjectsTree,image.Objects, ...
                    image.ActiveObjectID,image.SelectedObjectIDs);
            end

            obj.ObjectsTreeDirty = false;
            obj.scrollToActiveObject();
        end

        function scrollToActiveObject(obj)
        %SCROLLTOACTIVEOBJECT Bring the highlighted active-object node into view.

            % Active image supplying the ID bookmarked independently of selection.
            image = obj.Project.ActiveImage;

            if isempty(image) || image.ActiveObjectID == "" || ...
                    isempty(obj.ObjectsTree) || ~isvalid(obj.ObjectsTree)
                return;
            end

            % Reused object nodes retain their current order and scroll context.
            nodes = obj.ObjectsTree.Children;

            for k = 1:numel(nodes)

                if string(nodes(k).NodeData) == image.ActiveObjectID
                    scroll(obj.ObjectsTree,nodes(k));
                    return;
                end

            end

        end

        function deleteTreeNodes(~,nodes)
        %DELETETREENODES Dispose only removed nodes and their figure-owned menus.

            % Delete each node's context menu before removing the node itself.
            for k = 1:numel(nodes)

                if ~isempty(nodes(k).ContextMenu)
                    delete(nodes(k).ContextMenu);
                end

            end

            delete(nodes);
        end

        function onTreeChanged(obj,tree,title,checked)
        %ONTREECHANGED Route highlighting and checkbox changes to independent model setters.

            if obj.Refreshing
                return;
            end

            if checked

                % Checked or highlighted tree nodes selected by this callback mode.
                nodes = tree.CheckedNodes;
            else
                nodes = tree.SelectedNodes;
            end

            % IDs from highlighted or checked tree nodes, depending on the callback mode.
            ids = strings(numel(nodes),1);

            for k = 1:numel(nodes)
                ids(k) = string(nodes(k).NodeData);
            end

            if ~checked && numel(ids) > 1
                ids = ids(end);
            end

            switch title
                case "Groups"

                    if checked
                        obj.Project.setSelectedGroups(ids);
                    else
                        obj.Project.setActiveGroup(ids);
                    end

                case "Images"

                    % Active/target group supplying its owned images and bookmarks.
                    group = obj.Project.ActiveGroup;

                    if isempty(group)
                        return;
                    end

                    if checked
                        group.setSelectedImages(ids);
                    else
                        group.setActiveImage(ids);
                    end

                case "Objects"

                    % Active image supplying data and object membership for this operation.
                    image = obj.Project.ActiveImage;

                    if isempty(image)
                        return;
                    end

                    if checked
                        image.setSelectedObjects(ids);
                    else
                        image.setActiveObject(ids);
                    end

            end

        end

        function onSettingEdited(obj,control)
        %ONSETTINGEDITED Apply a binding through config setters, restoring UI on rejection.

            % Control metadata identifying the target algorithm and parameter name.
            binding = control.UserData;

            % Settings object supplying the values for this operation.
            settings = obj.Settings.(binding.Domain);
            try

                if binding.Domain == "View"
                    previous = obj.Processing;
                    obj.Processing = true;
                    guard = onCleanup(@() obj.restoreProcessing(previous));
                    settings.(binding.Name) = control.Value;
                    clear guard;

                    if ~previous
                        obj.refreshViewers(false);
                    end

                    return;
                end

                settings.(binding.Name) = control.Value;

                % Common filtering controls serve as both defaults for future
                % runs and immediate edits to the active segmented image.
                filtering = ["Connectivity","MinimumArea","BorderWidth","MaxObjects"];

                if binding.Domain == "Segmentation" && ...
                        ismember(binding.Name,filtering)
                    image = obj.Project.ActiveImage;

                    if ~isempty(image) && ~isempty(image.SegmentationParameters)
                        obj.commitSegmentationAdjustment( ...
                            image,binding.Name,control.Value);
                    end
                end
            catch ME
                control.Value = settings.(binding.Name);
                rethrow(ME);
            end
        end

        function onPairedColorModeEdited(obj,control)
        %ONPAIREDCOLORMODEEDITED Store a mode and update its adjacent picker.

            obj.onSettingEdited(control);
            obj.refreshPairedColorControl(control);
        end

        function refreshPairedColorControl(~,control)
        %REFRESHPAIREDCOLORCONTROL Enable a picker only for its custom mode.

            if ~isvalid(control) || ~isstruct(control.UserData) || ...
                    ~isfield(control.UserData,'ColorControl')
                return;
            end

            color = control.UserData.ColorControl;

            if isvalid(color)
                color.Enable = matlab.lang.OnOffSwitchState( ...
                    string(control.Value) == control.UserData.CustomValue);
            end
        end

        function onSettingsChanged(obj,e)
        %ONSETTINGSCHANGED Sync the bound control and execute domain-specific refresh policy.

            if isfield(obj.SettingsUI,e.Domain) && isfield(obj.SettingsUI.(e.Domain),e.Name)

                % Bound UI component being constructed or synchronized.
                control = obj.SettingsUI.(e.Domain).(e.Name);
                control.Value = e.NewValue;
                obj.refreshPairedColorControl(control);
            end

            if isempty(obj.Project)
                return;
            end

            if obj.Processing
                return;
            end

            % Choosing a future Order Auto method does not alter a manual or
            % locked display. Keep Auto applies the new method immediately.
            if e.Domain == "Display" && e.Name == "OrderAutoScaleMethod" && ...
                    ~obj.Settings.Display.KeepAutoDisplayOrder
                return;
            end

            if e.Domain == "Colormaps"
                obj.refreshColormapControls();
            end

            if e.Domain == "Segmentation"
                obj.refreshSegmentationControls();
            end

            if ismember(e.Domain,["Colormaps","Display"])
                obj.ObjectViewerKey = "";
            end

            % Segmentation edits configure the next explicit run; no hidden reruns.
            switch e.Domain
                case {"View","Colormaps","Display"}
                    obj.refreshViewers(true);
                case "AzimuthDisplay"
                    obj.refreshOrientationFields([obj.Settings.View.LeftSource, ...
                        obj.Settings.View.RightSource]);

                    if obj.Settings.View.RightSource == "Objects"
                        obj.refreshObjectViewerOverlays();
                    end
                case "ObjectSelection"
                    obj.refreshViewerRegions();

                    if obj.Settings.View.RightSource == "Objects"
                        obj.refreshObjectViewerOverlays();
                    end
                case "ObjectDisplay"
                    obj.ObjectViewerKey = "";

                    if obj.Settings.View.RightSource == "Objects"
                        obj.refreshObjectViewers(false);
                    end
                case {"ScatterPlot","SwarmPlot","PolarHistogram","Palettes"}
                    obj.refreshPlots();
            end

        end

        function refreshLabels(obj)
        %REFRESHLABELS Rebuild the small label tree and synchronize its hotkeys.

            if isempty(obj.LabelsTree) || ~isvalid(obj.LabelsTree)
                return;
            end

            checkedIDs = strings(0,1);

            if ~isempty(obj.LabelsTree.CheckedNodes)
                checkedIDs = string({obj.LabelsTree.CheckedNodes.NodeData})';
            end

            obj.deleteTreeNodes(obj.LabelsTree.Children);

            if isempty(obj.Project)
                return;
            end

            % Ordered project labels displayed with their assigned keyboard shortcuts.
            labels = obj.Project.Labels.labels();

            for k = 1:numel(labels)
                label = labels(k);
                text = label.Name;

                if label.hasHotkey()
                    text = text + "  [" + label.Hotkey + "]";
                end

                % Tree node stores the stable label ID rather than its mutable name.
                node = uitreenode(obj.LabelsTree,'Text',char(text));
                node.NodeData = label.ID;
                node.ContextMenu = obj.labelMenu(label.ID);

                % Cached transparent circle matches group nodes and overlay colors.
                icon = matlabx.ui.icon.get( ...
                    Shape="circle",Color=label.Color,Size=16);
                node.Icon = char(icon);
            end

            nodes = obj.LabelsTree.Children;
            nodeIDs = string({nodes.NodeData});
            keep = ismember(nodeIDs,checkedIDs) & nodeIDs ~= "unlabeled";

            if any(keep)
                obj.LabelsTree.CheckedNodes = nodes(keep);
            else
                obj.LabelsTree.CheckedNodes = [];
            end

            obj.refreshLabelHotkeys();
            obj.syncActiveLabel();
            obj.refreshLabelMenus();
        end

        function refreshLabelHotkeys(obj)
        %REFRESHLABELHOTKEYS Replace only shortcuts owned by the label registry.

            % Remove prior label bindings while leaving unrelated commands intact.
            for key = obj.LabelHotkeys
                obj.CommandRouter.removeHotkey(key);
            end

            labels = obj.Project.Labels.labels();
            keys = string.empty(1,0);

            for k = 1:numel(labels)

                if ~labels(k).hasHotkey()
                    continue;
                end

                key = labels(k).Hotkey;
                obj.CommandRouter.addHotkey(key, ...
                    @(~,pressed) obj.runCallback(@() obj.onLabelHotkeyPressed(pressed)));
                keys(end+1) = key; %#ok<AGROW>
            end

            obj.LabelHotkeys = keys;
        end

        function syncActiveLabel(obj)
        %SYNCACTIVELABEL Highlight the registry's active label without applying it.

            if isempty(obj.LabelsTree) || ~isvalid(obj.LabelsTree)
                return;
            end

            nodes = obj.LabelsTree.Children;
            activeID = obj.Project.Labels.ActiveLabelID;

            for k = 1:numel(nodes)

                if string(nodes(k).NodeData) == activeID
                    obj.LabelsTree.SelectedNodes = nodes(k);
                    return;
                end

            end

            obj.LabelsTree.SelectedNodes = matlab.ui.container.TreeNode.empty();
        end

        function onLabelSelected(obj)
        %ONLABELSELECTED Choose the label that subsequent hotkey actions will apply.

            node = obj.LabelsTree.SelectedNodes;

            if ~isempty(node)
                obj.Project.Labels.setActiveByID(string(node(1).NodeData));
            end
        end

        function onLabelChecksChanged(obj)
        %ONLABELCHECKSCHANGED Exclude Unlabeled and refresh merge availability.

            nodes = obj.LabelsTree.CheckedNodes;

            if ~isempty(nodes)
                ids = string({nodes.NodeData});

                if any(ids == "unlabeled")
                    obj.LabelsTree.CheckedNodes = nodes(ids ~= "unlabeled");
                    return;
                end
            end

            obj.refreshLabelMenus();
        end

        function onLabelHotkeyPressed(obj,key)
        %ONLABELHOTKEYPRESSED Label the active image's checked object set.

            label = obj.Project.Labels.getByHotkey(key);

            if isempty(label)
                return;
            end

            obj.Project.Labels.setActiveByID(label.ID);

            % Active image owns both the checked IDs and the batch label mutation.
            image = obj.Project.ActiveImage;

            if isempty(image) || isempty(image.SelectedObjectIDs)
                return;
            end

            image.setObjectLabels(image.SelectedObjectIDs,label.ID);
        end

        function onLabelsChanged(obj)
        %ONLABELSCHANGED Refresh label presentation and affected object appearance.

            obj.refreshLabels();
            obj.refreshSummary();
            obj.refreshOverlayAppearance();

            if obj.Settings.View.RightSource == "Objects"
                obj.refreshObjectViewerOverlays();
            end

            obj.refreshPlots();
        end

        function menu = labelMenu(obj,id)
        %LABELMENU Build registry actions bound to one context-clicked label ID.

            menu = uicontextmenu(obj.Fig);
            uimenu(menu,'Text','New label...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptLabel()));
            uimenu(menu,'Text','Merge selected labels...', ...
                'Tag','oops.mergeLabels','Enable','off', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.mergeSelectedLabels()));

            if id == ""
                return;
            end

            uimenu(menu,'Text','Edit...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptLabel(id)));
            uimenu(menu,'Text','Select objects with this label', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.selectObjectsWithLabel(id)));
            uimenu(menu,'Text','Apply to current object selection', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.applyLabelToSelection(id)));
            uimenu(menu,'Text','Delete objects with this label', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.deleteObjectsWithLabel(id)));

            % Unlabeled is the permanent fallback used by new and reassigned objects.
            item = uimenu(menu,'Text','Delete label', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.deleteLabel(id)));

            if id == "unlabeled"
                item.Enable = 'off';
            end
        end

        function refreshLabelMenus(obj)
        %REFRESHLABELMENUS Enable merging only for two checked user labels.

            checked = obj.LabelsTree.CheckedNodes;
            mergeEnabled = numel(checked) >= 2 && ...
                all(string({checked.NodeData}) ~= "unlabeled");
            items = findall(obj.Fig,'Type','uimenu','Tag','oops.mergeLabels');
            set(items,'Enable',matlab.lang.OnOffSwitchState(mergeEnabled));
        end

        function refreshViewers(obj,force,refreshControls)
        %REFRESHVIEWERS Change sources on the same ImageAxes; no overlapping view sets.
        % Object deletion leaves scaling unchanged, so it can skip control refreshes.

            if nargin < 3
                refreshControls = true;
            end

            if isempty(obj.LeftViewer) || obj.Closing
                return;
            end

            if isempty(obj.Project)
                return;
            end

            started = tic;
            imageName = "none";

            if ~isempty(obj.Project.ActiveImage)
                imageName = obj.Project.ActiveImage.Name;
            end

            oops.Log.DEBUG(sprintf( ...
                'Refreshing main viewers: image=%s, force=%s, controls=%s.', ...
                imageName,yesNo(force),yesNo(refreshControls)));
            refreshTrace = onCleanup(@() logDebugElapsed( ...
                "Completed main viewer refresh",started)); %#ok<NASGU>

            obj.SyncingViewerDisplay = true;
            displayGuard = onCleanup(@() obj.endViewerDisplaySync());

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Settings object supplying the values for this operation.
            settings = obj.Settings;

            % Left and right ImageAxes handles in panel order.
            viewers = {obj.LeftViewer,obj.RightViewer};

            % Left and right panel source names in viewer order.
            names = [settings.View.LeftSource,settings.View.RightSource];

            % Reparent or resize panel content only when the view definition changes.
            % Image navigation changes pixels, not the surrounding component layout.
            stage = tic;

            if ~isequal(obj.PanelContentNames,names)
                obj.syncPanelContent(names);
                obj.resizeViewers();
                oops.Log.DEBUG(sprintf( ...
                    'Synchronized changed panel content and layout in %.3f s.',toc(stage)));
            else
                oops.Log.DEBUG("Panel content unchanged; skipped layout synchronization.");
            end

            % Whether both main panels currently expose their persistent ImageAxes.
            linkViewports = obj.LeftViewer.Visible == "on" && ...
                obj.RightViewer.Visible == "on";

            % Disconnect before source replacement so a hidden viewer cannot push
            % stale viewport state into the viewer that remains on screen.
            if ~linkViewports
                obj.setLargeViewerViewportLink(false);
            end

            % Resolve and update each panel only when forced or its source key changes.
            for k = 1:2

                if ismember(names(k),["Empty","Scatterplot","Swarmplot","PolarHistogram","Objects"])
                    oops.Log.DEBUG(sprintf( ...
                        'Panel %d uses non-image source %s; skipping ImageAxes update.', ...
                        k,names(k)));
                    obj.ViewerKeys(k) = names(k);
                    continue;
                end

                % Source name plus active image ID used to detect unchanged viewer content.
                key = names(k);

                if ~isempty(image)
                    key = key + ":" + image.ID;
                end

                if ~force && obj.ViewerKeys(k) == key
                    oops.Log.DEBUG(sprintf( ...
                        'Panel %d source unchanged (%s); reusing current ImageAxes data.', ...
                        k,key));
                    continue;
                end

                % Display-ready Image5D source and its title/scaling/availability metadata.
                stage = tic;
                [data,info] = oops.render.source(image,names(k),settings);
                oops.Log.DEBUG(sprintf( ...
                    'Resolved panel %d source %s in %.3f s; available=%s.', ...
                    k,names(k),toc(stage),yesNo(info.Available)));

                % ImageAxes for the current left/right panel.
                viewer = viewers{k};

                if info.Available

                    % Clear any prior unavailability reason retained by this
                    % reused panel when an active image/source becomes available.
                    obj.ViewerPanels(k).Title = char( ...
                        oops.config.View.sourceLabels(names(k)));

                    % Whether the viewer already represents this same image/source pair.
                    sameSource = obj.ViewerKeys(k) == key;

                    % Current component/Z/T indices retained when refreshing the same source.
                    indices = [viewer.C viewer.Z viewer.T];
                    stage = tic;
                    viewer.ImageData = data;
                    oops.Log.DEBUG(sprintf( ...
                        'Assigned panel %d ImageAxes data in %.3f s.',k,toc(stage)));

                    if sameSource
                        viewer.C = min(indices(1),data.NumComponents);
                        viewer.Z = min(indices(2),data.SizeZ);
                        viewer.T = min(indices(3),data.SizeT);
                    end

                    if isempty(info.ComponentColormaps)
                        viewer.ComponentColormaps = repmat({info.Colormap},1,data.NumComponents);
                    else
                        viewer.ComponentColormaps = info.ComponentColormaps;
                    end

                    % Every source supplies complete coloring state so a viewer
                    % cannot inherit mode or colors from its previous content.
                    if ~isempty(info.ComponentColors)
                        viewer.ComponentColors = info.ComponentColors;
                    end

                    viewer.ComponentColorMode = char(info.ComponentColorMode);

                    if ~isempty(info.ComponentCLims)
                        viewer.CLimMode = 'manual';
                        viewer.ComponentCLims = info.ComponentCLims;
                    elseif ~isempty(info.CLim)
                        viewer.CLimMode = 'manual';
                        viewer.ComponentCLims = repmat({info.CLim},1,data.NumComponents);
                    elseif settings.Display.KeepAutoDisplayIntensity
                        viewer.CLimMode = 'auto';
                    else
                        viewer.CLimMode = 'manual';
                    end

                    viewer.ImageVisible = 'on';
                    viewer.AxesVisible = 'on';
                else
                    viewer.CData = [];
                    viewer.ImageVisible = 'off';
                    viewer.AxesVisible = 'off';
                    label = oops.config.View.sourceLabels(names(k));
                    obj.ViewerPanels(k).Title = char(label + " — " + info.Reason);
                end

                obj.ViewerKeys(k) = key;
            end

            % Link after both sources are ready, using the left viewer as the
            % initial viewport when a new pair becomes visible.
            if linkViewports
                obj.setLargeViewerViewportLink(true);
            end

            if any(ismember(names,["Scatterplot","Swarmplot","PolarHistogram"]))
                stage = tic;
                obj.refreshPlots();
                oops.Log.DEBUG(sprintf('Refreshed plots in %.3f s.',toc(stage)));
            end

            if names(2) == "Objects"
                stage = tic;
                obj.refreshObjectViewers(force);
                oops.Log.DEBUG(sprintf('Refreshed object viewers in %.3f s.',toc(stage)));
            end

            stage = tic;
            obj.refreshViewerRegions();
            oops.Log.DEBUG(sprintf( ...
                'Refreshed masks and object boundaries in %.3f s.',toc(stage)));

            stage = tic;
            obj.refreshOrientationFields(names);
            oops.Log.DEBUG(sprintf( ...
                'Refreshed orientation fields in %.3f s.',toc(stage)));

            if refreshControls
                stage = tic;
                obj.refreshSegmentationControls();
                obj.refreshDisplayLimits();
                oops.Log.DEBUG(sprintf( ...
                    'Refreshed viewer-related controls in %.3f s.',toc(stage)));
            end

            clear displayGuard;

        end

        function onViewerDisplayStateChanged(obj,viewer,event)
        %ONVIEWERDISPLAYSTATECHANGED Persist contrast changed with ImageAxes tools.

            if obj.SyncingViewerDisplay || isempty(obj.Project)
                return;
            end

            % Native mask visibility remains the public ImageAxes control. Load
            % the model mask only when the user reveals it.
            if event.Property == "MaskEnabled"

                if viewer.MaskEnabled
                    obj.refreshViewerRegions();
                end

                return;
            end

            if ismember(event.Property,["ComponentColorMode","ComponentColors","ComponentColormaps"])
                obj.persistViewerColoring(viewer,event);
                return;
            end

            if event.Property ~= "ComponentCLims"
                return;
            end

            source = "";

            if viewer == obj.LeftViewer
                source = obj.Settings.View.LeftSource;
            elseif viewer == obj.RightViewer
                source = obj.Settings.View.RightSource;
            end

            if ismember(source,["Input","Corrected","AverageIntensity"])
                domain = "Intensity";
            elseif source == "Order"
                domain = "Order";
            elseif source == "AuxiliaryChannels"
                obj.persistAuxiliaryDisplayRanges(viewer,event);
                return;
            else
                return;
            end

            image = obj.Project.ActiveImage;

            if isempty(image)
                return;
            end

            % ImageAxes reports the effective limits of its active component.
            % Intensity frames share one model range, so the selected range is
            % propagated to every visible source in the same display domain.
            value = viewer.CLim;

            if domain == "Intensity"
                value = oops.render.normalizeIntensityDisplayRange(image,value);
            end

            % Ignore incomplete or unsupported values before entering model setters.
            if numel(value) ~= 2 || any(~isfinite(value)) || value(1) >= value(2)
                return;
            end

            % Order is physically constrained to [0,1], whereas intensity
            % limits follow the source data and detector display convention.
            if domain == "Order" && (value(1) < 0 || value(2) > 1)
                return;
            end

            % Model/config events emitted below must not trigger a full viewer
            % refresh while the existing ImageAxes content is still valid.
            previous = obj.Processing;
            obj.Processing = true;
            processingGuard = onCleanup(@() obj.restoreProcessing(previous));

            image.setDisplayRange(domain,value);
            obj.Settings.Display.("KeepAutoDisplay"+domain) = false;

            if obj.Settings.Display.("LockDisplay"+domain)
                obj.Settings.Display.("LockedDisplayRange"+domain) = value;
            end

            obj.applyDisplayRangeToViewers(domain,value);
            obj.refreshDisplayLimits();
            clear processingGuard;
        end

        function persistViewerColoring(obj,viewer,event)
        %PERSISTVIEWERCOLORING Commit native ImageAxes appearance edits.

            source = "";
            if viewer == obj.LeftViewer
                source = obj.Settings.View.LeftSource;
            elseif viewer == obj.RightViewer
                source = obj.Settings.View.RightSource;
            end

            image = obj.Project.ActiveImage;
            if isempty(image)
                return;
            end

            if ismember(source,["Input","Corrected","AverageIntensity"])
                modeProperty = "PrimaryIntensityColorMode";
                definitions = image.PrimaryChannel;
                mapDomain = "";
            elseif source == "AuxiliaryChannels"
                modeProperty = "AuxiliaryColorMode";
                definitions = obj.Project.Channels.Channels;
                definitions = definitions([definitions.IsAuxiliary]);
                mapDomain = "";
            elseif ismember(source,["Order","Azimuth","Mask"])
                modeProperty = source + "ColorMode";
                definitions = oops.model.ChannelDefinition.empty(0,1);
                mapDomain = source;
            else
                return;
            end

            previous = obj.Processing;
            obj.Processing = true;
            guard = onCleanup(@() obj.restoreProcessing(previous));

            if event.Property == "ComponentColorMode"
                obj.Settings.Display.(modeProperty) = string(viewer.ComponentColorMode);
            elseif event.Property == "ComponentColors"
                indices = event.ComponentIdx;
                if isempty(indices), indices = 1:viewer.NumComponents; end
                colors = viewer.ComponentColors;

                if mapDomain ~= ""
                    obj.Settings.Colormaps.(mapDomain+"Color") = string(colors{indices(1)});
                else
                    for index = reshape(indices,1,[])
                        definitionIndex = min(index,numel(definitions));
                        if definitionIndex < 1, continue; end
                        [~,rgb] = matlabx.image.normalizeComponentColor(colors{index});
                        definitions(definitionIndex).setColor(rgb);
                    end
                end
            elseif event.Property == "ComponentColormaps"
                indices = event.ComponentIdx;
                if isempty(indices), indices = 1:viewer.NumComponents; end
                maps = viewer.ComponentColormaps;

                for index = reshape(indices,1,[])
                    [name,category] = oops.render.identifyColormap(maps{index});
                    if name == "", continue; end

                    if mapDomain ~= ""
                        obj.Settings.Colormaps.setMap(mapDomain,name,category);
                        break;
                    end

                    definitionIndex = min(index,numel(definitions));
                    if definitionIndex >= 1
                        definitions(definitionIndex).setColormap(name,category);
                    end
                end
            end

            obj.refreshColormapControls();
            clear guard;
            obj.refreshViewers(true);
        end

        function persistAuxiliaryDisplayRanges(obj,viewer,event)
        %PERSISTAUXILIARYDISPLAYRANGES Store per-channel auxiliary contrast.

            image = obj.Project.ActiveImage;

            if isempty(image)
                return;
            end

            definitions = obj.Project.Channels.Channels;
            definitions = definitions([definitions.IsAuxiliary]);
            indices = event.ComponentIdx;

            if isempty(indices)
                indices = 1:min(numel(definitions),viewer.NumComponents);
            end

            limits = viewer.ComponentCLims;

            for index = reshape(indices,1,[])

                if index > numel(definitions) || index > numel(limits)
                    continue;
                end

                assignment = image.getAuxiliaryChannel(definitions(index).ID);

                if ~isempty(assignment)
                    assignment.setDisplayRange(limits{index});
                end
            end
        end

        function applyDisplayRangeToViewers(obj,domain,value)
        %APPLYDISPLAYRANGETOVIEWERS Synchronize visible sources without rebuilding them.

            obj.SyncingViewerDisplay = true;
            displayGuard = onCleanup(@() obj.endViewerDisplaySync());

            % Main sources whose pixels use the shared image display domain.
            names = [obj.Settings.View.LeftSource,obj.Settings.View.RightSource];
            viewers = {obj.LeftViewer,obj.RightViewer};

            if domain == "Intensity"
                affected = ismember(names,["Input","Corrected","AverageIntensity"]);
            else
                affected = names == "Order";
            end

            for k = find(affected)
                currentViewer = viewers{k};
                currentViewer.CLimMode = 'manual';
                currentViewer.ComponentCLims = ...
                    repmat({value},1,currentViewer.NumComponents);
            end

            % RGB derived views bake both domains into their pixels, so live
            % slider previews rebuild only the visible dependent composites.
            derived = ["IntensityWeightedOrder","IntensityWeightedAzimuth", ...
                "AzimuthOrderIntensityHSV"];
            image = obj.Project.ActiveImage;

            for k = find(ismember(names,derived))
                if domain == "Order" && names(k) == "IntensityWeightedAzimuth"
                    continue;
                end

                if domain == "Intensity"
                    rgb = oops.render.derivedVisualization( ...
                        image,names(k),obj.Settings,IntensityLimits=value);
                else
                    rgb = oops.render.derivedVisualization( ...
                        image,names(k),obj.Settings,OrderLimits=value);
                end

                label = oops.config.View.sourceLabels(names(k));
                viewers{k}.ImageData = matlabx.image.Image5D.fromComponents( ...
                    rgb,Names=label,Kinds="rgb");
            end

            % Object crops share their parent image's intensity and order limits.
            if obj.Settings.View.RightSource == "Objects"

                if domain == "Intensity"
                    objectViewer = obj.ObjectViewers{1};
                else
                    objectViewer = obj.ObjectViewers{2};
                end

                if objectViewer.ImageVisible == "on"
                    objectViewer.CLimMode = 'manual';
                    objectViewer.ComponentCLims = ...
                        repmat({value},1,objectViewer.NumComponents);
                end
            end

            clear displayGuard;
        end

        function syncPanelContent(obj,names)
        %SYNCPANELCONTENT Mount each requested source in one stable panel host.

            viewers = {obj.LeftViewer,obj.RightViewer};
            plotAxes = {obj.LeftPlotAxes,obj.RightPlotAxes};

            % The object quadrant grid replaces the complete normal right panel.
            showingObjects = names(2) == "Objects";
            obj.ViewerPanels(2).Visible = matlab.lang.OnOffSwitchState(~showingObjects);
            obj.ObjectViewerGrid.Visible = matlab.lang.OnOffSwitchState(showingObjects);

            if ~showingObjects && ~isempty(obj.Project)
                obj.Project.CacheManager.releasePinnedCorrected();
            end

            for k = 1:2
                obj.ViewerPanels(k).Title = char( ...
                    oops.config.View.sourceLabels(names(k)));

                switch names(k)
                    case "Scatterplot"
                        viewers{k}.Visible = 'off';
                        plotAxes{k}.Visible = 'on';
                        plotAxes{k}.mount(obj.ScatterRenderer);

                    case "Swarmplot"
                        viewers{k}.Visible = 'off';
                        plotAxes{k}.Visible = 'on';
                        plotAxes{k}.mount(obj.SwarmRenderer);

                    case "PolarHistogram"
                        viewers{k}.Visible = 'off';
                        plotAxes{k}.Visible = 'on';
                        plotAxes{k}.mount(obj.PolarHistogramRenderer);

                    case "Empty"
                        viewers{k}.Visible = 'off';
                        plotAxes{k}.clear();
                        plotAxes{k}.Visible = 'off';

                    case "Objects"
                        viewers{k}.Visible = 'off';
                        plotAxes{k}.clear();
                        plotAxes{k}.Visible = 'off';

                    otherwise
                        plotAxes{k}.clear();
                        plotAxes{k}.Visible = 'off';
                        viewers{k}.Visible = 'on';
                end
            end

            obj.PanelContentNames = names;
        end

        function setLargeViewerViewportLink(obj,enabled)
        %SETLARGEVIEWERVIEWPORTLINK Synchronize navigation between main viewers.

            % The large viewers own no other link groups, so removing a link from
            % either participant safely disconnects the complete pair.
            if ~enabled

                if obj.LeftViewer.hasLinks
                    obj.LeftViewer.removeLinks();
                elseif obj.RightViewer.hasLinks
                    obj.RightViewer.removeLinks();
                end

                return
            end

            % An established pair already propagates viewport changes in both directions.
            if obj.LeftViewer.hasLinks && obj.RightViewer.hasLinks
                return
            end

            % Recover a partial link state before constructing the expected pair.
            if obj.LeftViewer.hasLinks
                obj.LeftViewer.removeLinks();
            elseif obj.RightViewer.hasLinks
                obj.RightViewer.removeLinks();
            end

            obj.LeftViewer.addLink(obj.RightViewer,{'Viewport'});
        end

        function refreshObjectViewers(obj,force)
        %REFRESHOBJECTVIEWERS Populate the four aligned crops for the active object.

            region = obj.Project.ActiveObject;

            if isempty(region)
                obj.Project.CacheManager.releasePinnedCorrected();
                obj.clearObjectViewers("No active object");
                obj.ObjectViewerKey = "";
                return;
            end

            % Identity key avoids rebuilding four Image5D objects for unrelated refreshes.
            key = region.Parent.ID + ":" + region.ID;

            % Object navigation repeatedly crops one parent stack. Pin exactly
            % that image while this view is active, replacing any previous pin.
            image = region.Parent;
            calibrationIDs = image.Parent.CalibrationIDs;
            cache = obj.Project.CacheManager;

            if ~cache.isCorrectedPinned(image.ID,calibrationIDs)
                cache.releasePinnedCorrected();
            end

            corrected = oops.analysis.Analyzer.correctedStack(image);
            cache.pinCorrected(image.ID,calibrationIDs,corrected);

            if ~force && obj.ObjectViewerKey == key
                return;
            end

            [sources,info,objectMask,geometry] = oops.render.objectSources( ...
                region,obj.Settings,Corrected=corrected);

            for k = 1:numel(obj.ObjectViewers)

                % Persistent ImageAxes and titled outer panel for this quadrant.
                viewer = obj.ObjectViewers{k};
                panel = obj.ObjectViewerPanels(k);

                if ~info(k).Available
                    viewer.CData = [];
                    viewer.Mask = [];
                    viewer.ImageVisible = 'off';
                    viewer.AxesVisible = 'off';
                    panel.Title = char(info(k).Title + " — " + info(k).Reason);
                    continue;
                end

                % Preserve polarization component when refreshing the same object.
                component = viewer.C;
                viewer.ImageData = sources{k};
                viewer.C = min(component,sources{k}.NumComponents);
                viewer.ShowComposite = 'off';
                viewer.ComponentColormaps = repmat( ...
                    {info(k).Colormap},1,sources{k}.NumComponents);

                if ~isempty(info(k).ComponentColors)
                    viewer.ComponentColors = info(k).ComponentColors;
                end

                viewer.ComponentColorMode = char(info(k).ComponentColorMode);

                if ~isempty(info(k).CLim)
                    viewer.CLimMode = 'manual';
                    viewer.ComponentCLims = repmat( ...
                        {info(k).CLim},1,sources{k}.NumComponents);
                end

                % Every crop receives the same active-object membership mask.
                viewer.Mask = objectMask;
                viewer.ImageVisible = 'on';
                viewer.AxesVisible = 'on';
                panel.Title = char(info(k).Title);
            end

            % Passive active-object overlays share this crop's local coordinates.
            obj.refreshObjectViewerOverlays(region,geometry,objectMask);

            obj.ObjectViewerKey = key;
        end

        function refreshObjectViewerOverlays(obj,region,geometry,objectMask)
        %REFRESHOBJECTVIEWEROVERLAYS Update passive overlays for all four crops.

            if isempty(obj.Project) || isempty(obj.ObjectViewers)
                return;
            end

            if nargin < 2
                region = obj.Project.ActiveObject;
            end

            if isempty(region)
                obj.clearObjectViewerOverlays();
                return;
            end

            % Crop geometry is cheap to reconstruct for appearance-only changes.
            if nargin < 3
                display = obj.Settings.ObjectDisplay;
                geometry = region.getCropGeometry( ...
                    Margin=display.CropMargin,Square=display.SquareCrop);
            end

            if nargin < 4
                [objectMask,geometry] = region.getMask( ...
                    Margin=obj.Settings.ObjectDisplay.CropMargin, ...
                    Square=obj.Settings.ObjectDisplay.SquareCrop);
            end

            % Convert the parent-image boundary from [x y] to local coordinates.
            boundary = region.getBoundaryVertices();

            if ~isempty(boundary)
                localRC = geometry.toLocal(boundary(:,[2 1]));
                boundary = localRC(:,[2 1]);
            end

            % Base boundary color follows either the custom setting or object label.
            selection = obj.Settings.ObjectSelection;
            boundaryColor = selection.Color;

            if selection.ColorMode == "Label" && ~isempty(region.Label)
                boundaryColor = region.Label.Color;
            end

            % Convert the stored parent-image [x y] midline into this crop.
            midline = region.Midline;
            hasMidline = ~isempty(midline) && all(isfinite(midline),'all');

            if hasMidline
                localRC = geometry.toLocal(midline(:,[2 1]));
                midline = localRC(:,[2 1]);
            else
                midline = zeros(0,2);
            end

            % Sample analytical values only at this object's local pixels.
            image = region.Parent;
            hasOrientation = ~isempty(image.Order) && ~isempty(image.Azimuth);
            renderOrientation = hasOrientation && any(cellfun( ...
                @(tool) tool.Enabled,obj.ObjectViewerOrientationTools));
            x = zeros(0,1);
            y = zeros(0,1);
            angle = zeros(0,1);
            magnitude = zeros(0,1);

            if renderOrientation
                indices = find(objectMask);
                [rows,columns] = ind2sub(size(objectMask),indices);

                % Apply the same spatial sampling interval used by main fields.
                spacing = obj.Settings.AzimuthDisplay.ScaleDownFactor;

                if spacing > 1
                    keep = mod(rows-1,spacing) == 0 & ...
                        mod(columns-1,spacing) == 0;
                    indices = indices(keep);
                    rows = rows(keep);
                    columns = columns(keep);
                end

                % Crop analytical outputs before reading local object membership.
                order = geometry.extract(image.Order,FillValue=0);
                azimuth = geometry.extract(image.Azimuth,FillValue=0);
                magnitude = order(indices);
                angle = azimuth(indices);

                % Invalid analysis pairs are rare and checked only within the object.
                finite = isfinite(angle) & isfinite(magnitude);
                x = double(columns(finite));
                y = double(rows(finite));
                angle = double(angle(finite));
                magnitude = double(magnitude(finite));
            end

            % Direction uses azimuth colors; magnitude uses the order map.
            azimuthSettings = obj.Settings.AzimuthDisplay;

            if azimuthSettings.ColorMode == "Magnitude"
                map = oops.render.colormap(obj.Settings.Colormaps,"Order");
            else
                map = oops.render.colormap(obj.Settings.Colormaps,"Azimuth");
            end

            for k = 1:numel(obj.ObjectViewers)

                % A blank source cannot host a meaningful active-object overlay.
                available = logical(obj.ObjectViewers{k}.ImageVisible);

                boundaryContent = obj.ObjectViewerBoundaryContents{k};
                boundaryContent.setStyle(boundaryColor,selection.LineWidth);
                boundaryContent.setData(boundary);
                obj.ObjectViewerBoundaryTools{k}.setAvailable(available && ~isempty(boundary));

                field = obj.ObjectViewerOrientationFields{k};
                field.setStyle( ...
                    ColorMode=azimuthSettings.ColorMode, ...
                    Colormap=map, ...
                    Color=azimuthSettings.Color, ...
                    LineWidth=azimuthSettings.LineWidth, ...
                    Alpha=azimuthSettings.LineAlpha, ...
                    Scale=azimuthSettings.LineScale);
                field.setData(x,y,angle,magnitude);
                obj.ObjectViewerOrientationTools{k}.setAvailable( ...
                    available && hasOrientation);

                % Black remains visible over the binary mask; white suits other images.
                midlineColor = [1 1 1];

                if k == 3
                    midlineColor = [0 0 0];
                end

                midlineContent = obj.ObjectViewerMidlineContents{k};
                midlineContent.setStyle(midlineColor,1);
                midlineContent.setData(midline);
                obj.ObjectViewerMidlineTools{k}.setAvailable( ...
                    available && hasMidline);
            end
        end

        function clearObjectViewerOverlays(obj)
        %CLEAROBJECTVIEWEROVERLAYS Clear and disable every passive object overlay.

            for k = 1:numel(obj.ObjectViewers)
                obj.ObjectViewerBoundaryContents{k}.clear();
                obj.ObjectViewerBoundaryTools{k}.setAvailable(false);
                obj.ObjectViewerOrientationFields{k}.clear();
                obj.ObjectViewerOrientationTools{k}.setAvailable(false);
                obj.ObjectViewerMidlineContents{k}.clear();
                obj.ObjectViewerMidlineTools{k}.setAvailable(false);
            end
        end

        function clearObjectViewers(obj,reason)
        %CLEAROBJECTVIEWERS Empty all quadrants while retaining the stable layout.

            titles = ["Corrected intensity","Order","Mask","Azimuth"];

            for k = 1:numel(obj.ObjectViewers)
                viewer = obj.ObjectViewers{k};
                viewer.CData = [];
                viewer.Mask = [];
                viewer.ImageVisible = 'off';
                viewer.AxesVisible = 'off';
                obj.ObjectViewerPanels(k).Title = char(titles(k)+" — "+reason);
            end

            obj.clearObjectViewerOverlays();
        end

        function stepActiveObject(obj,direction)
        %STEPACTIVEOBJECT Move to the adjacent object, wrapping at either end.

            image = obj.Project.ActiveImage;

            if isempty(image) || isempty(image.Objects)
                return;
            end

            % Current member position, falling back to the first object if unset.
            ids = oops.model.internal.ids(image.Objects);
            index = find(ids == image.ActiveObjectID,1);

            if isempty(index)
                index = 1;
            else
                index = mod(index-1+direction,numel(ids))+1;
            end

            image.setActiveObject(ids(index));
        end

        function deleteActiveObject(obj)
        %DELETEACTIVEOBJECT Remove the active image's currently displayed object.

            image = obj.Project.ActiveImage;

            if isempty(image) || isempty(image.ActiveObject)
                return;
            end

            obj.deleteObjects(image.ActiveObjectID);
        end

        function refreshPlots(obj)
        %REFRESHPLOTS Rebuild visible plot data from stored object measurements.

            names = [obj.Settings.View.LeftSource, ...
                obj.Settings.View.RightSource];

            if any(names == "Scatterplot")
                obj.refreshScatterPlot();
            end

            if any(names == "Swarmplot")
                obj.refreshSwarmPlot();
            end

            if any(names == "PolarHistogram")
                obj.refreshPolarHistogram();
            end
        end

        function refreshPolarHistogram(obj)
        %REFRESHPOLARHISTOGRAM Build one image- or group-scoped axial histogram.

            settings = obj.Settings.PolarHistogram;
            members = oops.model.Object.empty(0,1);

            if settings.DataSource == "Group"
                group = obj.Project.ActiveGroup;

                if ~isempty(group)
                    members = obj.groupObjects(group);
                end
            else
                image = obj.Project.ActiveImage;

                if ~isempty(image)
                    members = image.Objects;
                end
            end

            % Model angles are stored in degrees; the renderer consumes axial radians.
            angles = deg2rad(obj.objectValues(members,settings.Variable));
            data = oops.plot.PolarHistogramData(Angles=angles);

            % Use the unshifted circular azimuth map, matching orientation-line colors.
            map = oops.render.colormap(obj.Settings.Colormaps,"Azimuth");
            variableLabel = oops.model.ObjectMeasurements.label( ...
                settings.Variable,obj.Project);
            style = oops.plot.PolarHistogramStyle( ...
                Title=settings.DataSource + " - Object " + variableLabel, ...
                BinCount=settings.BinCount, ...
                Colormap=map, ...
                WedgeFaceAlpha=settings.WedgeFaceAlpha, ...
                WedgeFaceColorMode=settings.WedgeFaceColorMode, ...
                WedgeFaceColor=settings.WedgeFaceColor, ...
                WedgeEdgeColorMode=settings.WedgeEdgeColorMode, ...
                WedgeEdgeColor=settings.WedgeEdgeColor, ...
                WedgeLineWidth=settings.WedgeLineWidth, ...
                GridlinesColor=settings.GridlinesColor, ...
                LabelsColor=settings.LabelsColor, ...
                GridlinesLineWidth=settings.GridlinesLineWidth, ...
                CircleBackgroundColor=settings.CircleBackgroundColor, ...
                CircleColor=settings.CircleColor, ...
                BackgroundColor=settings.BackgroundColor);

            obj.PolarHistogramRenderer.update(data,style);
        end

        function refreshScatterPlot(obj)
        %REFRESHSCATTERPLOT Normalize model scalars for the scatter renderer.

            settings = obj.Settings.ScatterPlot;
            [members,groupNames] = obj.plotPartitions(settings.GroupingType);

            if isempty(members)
                members = {oops.model.Object.empty(0,1)};
                groupNames = "No data";
            end

            % Series names enter tick labels and legends that use the TeX interpreter.
            displayGroupNames = oops.render.escapeTeX(groupNames);

            xData = cell(size(members));
            yData = cell(size(members));
            plottedMembers = cell(size(members));

            % Remove incomplete pairs while retaining object alignment for color data.
            for k = 1:numel(members)
                x = obj.objectValues(members{k},settings.XVariable);
                y = obj.objectValues(members{k},settings.YVariable);
                keep = isfinite(x) & isfinite(y);
                xData{k} = x(keep);
                yData{k} = y(keep);
                plottedMembers{k} = members{k}(keep);

                if isempty(xData{k})
                    xData{k} = NaN;
                    yData{k} = NaN;
                end
            end

            [colorData,colormap,limits] = obj.plotColors( ...
                plottedMembers,settings.ColorMode,settings.YVariable);

            % Resolve internal property names into text intended for display.
            xLabel = oops.model.ObjectMeasurements.label(settings.XVariable,obj.Project);
            yLabel = oops.model.ObjectMeasurements.label(settings.YVariable,obj.Project);

            % Describe each plotted point using its model identity and measurements.
            dataTipCells = cell(size(plottedMembers));

            for k = 1:numel(plottedMembers)
                dataTipCells{k} = obj.objectDataTipCell( ...
                    plottedMembers{k},settings.DataTipDetail, ...
                    [xLabel,yLabel],{xData{k},yData{k}});
            end

            % Translate application settings into the renderer-facing value.
            style = matlabx.ui.axes.plot.ScatterStyle( ...
                XLabel=xLabel, ...
                YLabel=yLabel, ...
                BackgroundColor=settings.BackgroundColor, ...
                ForegroundColor=settings.ForegroundColor, ...
                Colormap=colormap, ...
                CLim=limits, ...
                LegendVisible=settings.LegendVisible, ...
                MarkerSize=settings.MarkerSize, ...
                MarkerLineWidth=settings.MarkerLineWidth, ...
                MarkerMode=settings.MarkerMode, ...
                MarkerFaceAlpha=settings.MarkerFaceAlpha, ...
                MarkerFaceColorMode=obj.plotMarkerColorMode( ...
                    settings.MarkerFaceColorMode), ...
                MarkerFaceColor=settings.MarkerFaceColor, ...
                MarkerEdgeAlpha=settings.MarkerEdgeAlpha, ...
                MarkerEdgeColorMode=obj.plotMarkerColorMode( ...
                    settings.MarkerEdgeColorMode), ...
                MarkerEdgeColor=settings.MarkerEdgeColor, ...
                HullVisible=settings.HullVisible, ...
                HullType=settings.HullType, ...
                HullLineWidth=settings.HullLineWidth, ...
                HullFaceAlpha=settings.HullFaceAlpha, ...
                HullEdgeAlpha=settings.HullEdgeAlpha, ...
                HullFaceColorMode=settings.HullFaceColorMode, ...
                HullFaceColor=settings.HullFaceColor, ...
                HullEdgeColorMode=settings.HullEdgeColorMode, ...
                HullEdgeColor=settings.HullEdgeColor);

            data = matlabx.ui.axes.plot.ScatterData( ...
                XData=xData, ...
                YData=yData, ...
                SeriesNames=displayGroupNames, ...
                CData=colorData, ...
                DataTipCells=dataTipCells);

            obj.ScatterRenderer.update(data,style);
        end

        function refreshSwarmPlot(obj)
        %REFRESHSWARMPLOT Normalize model scalars for the violin renderer.

            settings = obj.Settings.SwarmPlot;
            [members,groupNames] = obj.plotPartitions(settings.GroupingType);

            if isempty(members)
                members = {oops.model.Object.empty(0,1)};
                groupNames = "No data";
            end

            % Series names enter tick labels that use the TeX interpreter.
            displayGroupNames = oops.render.escapeTeX(groupNames);

            data = cell(size(members));
            plottedMembers = cell(size(members));

            % Remove missing measurements before density and summary calculations.
            for k = 1:numel(members)
                values = obj.objectValues(members{k},settings.YVariable);
                keep = isfinite(values);
                data{k} = values(keep);
                plottedMembers{k} = members{k}(keep);

                if isempty(data{k})
                    data{k} = NaN;
                end
            end

            [colorData,colormap,limits] = obj.plotColors( ...
                plottedMembers,settings.ColorMode,settings.YVariable);

            % Resolve the internal property name into text intended for display.
            yLabel = oops.model.ObjectMeasurements.label(settings.YVariable,obj.Project);

            % Describe each swarm point while leaving violin summary tips at defaults.
            dataTipCells = cell(size(plottedMembers));

            for k = 1:numel(plottedMembers)
                dataTipCells{k} = obj.objectDataTipCell( ...
                    plottedMembers{k},settings.DataTipDetail,yLabel,{data{k}});
            end

            % Resolve OOPS configuration into an application-independent style.
            style = matlabx.ui.axes.plot.ViolinStyle( ...
                XLabel="Group", ...
                YLabel=yLabel, ...
                BackgroundColor=settings.BackgroundColor, ...
                ForegroundColor=settings.ForegroundColor, ...
                Colormap=colormap, ...
                CLim=limits, ...
                MarkerSize=settings.MarkerSize, ...
                MarkerLineWidth=settings.MarkerLineWidth, ...
                MarkerFaceAlpha=settings.MarkerFaceAlpha, ...
                MarkerFaceColorMode=obj.plotMarkerColorMode( ...
                    settings.MarkerFaceColorMode), ...
                MarkerFaceColor=settings.MarkerFaceColor, ...
                MarkerEdgeAlpha=settings.MarkerEdgeAlpha, ...
                MarkerEdgeColorMode=obj.plotMarkerColorMode( ...
                    settings.MarkerEdgeColorMode), ...
                MarkerEdgeColor=settings.MarkerEdgeColor, ...
                XJitterWidth=settings.XJitterWidth, ...
                PointsVisible=settings.PointsVisible, ...
                ViolinOutlinesVisible=settings.ViolinOutlinesVisible, ...
                ViolinLineWidth=settings.ViolinLineWidth, ...
                ViolinFaceColorMode=settings.ViolinFaceColorMode, ...
                ViolinFaceColor=settings.ViolinFaceColor, ...
                ViolinEdgeColorMode=settings.ViolinEdgeColorMode, ...
                ViolinEdgeColor=settings.ViolinEdgeColor, ...
                ViolinEdgeAlpha=settings.ViolinEdgeAlpha, ...
                ErrorBarsVisible=settings.ErrorBarsVisible, ...
                CentralStatistic=settings.CentralStatistic, ...
                ErrorStatistic=settings.ErrorStatistic, ...
                ErrorBarsColorMode=settings.ErrorBarsColorMode, ...
                ErrorBarsColor=settings.ErrorBarsColor, ...
                ErrorBarsLineWidth=settings.ErrorBarsLineWidth, ...
                CentralStatLineWidth=settings.CentralStatLineWidth);

            plotData = matlabx.ui.axes.plot.ViolinData( ...
                Values=data, ...
                SeriesNames=displayGroupNames, ...
                CData=colorData, ...
                DataTipCells=dataTipCells);

            % MATLABX resolves automatic violin and summary colors from the host
            % axes color order. Supply colors for the partitioning variable here,
            % independently of the CData palette used to color individual points.
            host = obj.SwarmRenderer.Host;

            if ~isempty(host) && isvalid(host)
                host.Axes.ColorOrder = obj.swarmGroupingColors( ...
                    settings.GroupingType,numel(members));
            end

            obj.SwarmRenderer.update(plotData,style);
        end

        function colors = swarmGroupingColors(obj,grouping,count)
        %SWARMGROUPINGCOLORS Return one automatic color per violin partition.

            if grouping == "Group"
                colors = reshape([obj.Project.Groups.Color],3,[])';
            else
                labels = obj.Project.Labels.labels();
                labelColors = reshape([labels.Color],3,[])';

                if grouping == "Both"
                    % Partitions are ordered by group, then label. Repeat the
                    % label palette within every group so adjacent label
                    % distributions retain their semantic label colors.
                    colors = repmat(labelColors,numel(obj.Project.Groups),1);
                else
                    colors = labelColors;
                end
            end

            % Empty projects and placeholder data still require a valid color
            % order. Repeat or truncate defensively to match rendered partitions.
            if isempty(colors)
                colors = get(groot,'defaultAxesColorOrder');
            end

            indices = mod(0:max(1,count)-1,size(colors,1))+1;
            colors = colors(indices,:);
        end

        function [members,names] = plotPartitions(obj,grouping)
        %PLOTPARTITIONS Group project objects by group, label, or both.

            members = cell(0,1);
            names = strings(0,1);
            labels = obj.Project.Labels.labels();

            if grouping == "Group"

                for group = obj.Project.Groups'
                    members{end+1,1} = obj.groupObjects(group); %#ok<AGROW>
                    names(end+1,1) = group.Name; %#ok<AGROW>
                end

                return;
            end

            if grouping == "Label"

                for label = labels
                    members{end+1,1} = obj.objectsWithLabel(obj.projectObjects(),label.ID); %#ok<AGROW>
                    names(end+1,1) = label.Name; %#ok<AGROW>
                end

                return;
            end

            % "Both" creates one violin for every group/label combination.
            for group = obj.Project.Groups'
                groupMembers = obj.groupObjects(group);

                for label = labels
                    members{end+1,1} = obj.objectsWithLabel(groupMembers,label.ID); %#ok<AGROW>
                    names(end+1,1) = group.Name+" — "+label.Name; %#ok<AGROW>
                end

            end
        end

        function members = projectObjects(obj)
        %PROJECTOBJECTS Collect all current objects in project hierarchy order.

            members = oops.model.Object.empty(0,1);

            for group = obj.Project.Groups'
                members = [members;obj.groupObjects(group)]; %#ok<AGROW>
            end
        end

        function members = groupObjects(~,group)
        %GROUPOBJECTS Collect all objects owned by one group in image order.

            members = oops.model.Object.empty(0,1);

            for image = group.Images'
                members = [members;image.Objects]; %#ok<AGROW>
            end
        end

        function members = objectsWithLabel(~,members,labelID)
        %OBJECTSWITHLABEL Filter an object array by its stable label ID.

            if isempty(members)
                return;
            end

            members = members([members.LabelID] == labelID);
        end

        function values = objectValues(~,members,property)
        %OBJECTVALUES Read one stored scalar property from an object array.

            [auxiliary,channelID] = oops.model.ObjectMeasurements.isAuxiliary(property);

            if isempty(members)
                values = zeros(0,1);
            elseif auxiliary
                values = arrayfun(@(member) ...
                    member.auxiliarySignalMean(channelID),members(:));
            else
                values = arrayfun(@(member) member.(property),members(:));
            end
        end

        function template = objectDataTipCell(~,members,detail,measurementLabels,measurementValues)
        %OBJECTDATATIPCELL Build one point-aligned model metadata template.

            if isempty(members)
                template = [];
                return;
            end

            % Allocate identity values in the same order as the plotted objects.
            count = numel(members);
            groupIndices = zeros(count,1);
            imageIndices = zeros(count,1);
            objectIndices = zeros(count,1);
            groupNames = strings(count,1);
            imageNames = strings(count,1);
            objectNames = strings(count,1);
            labelNames = strings(count,1);

            for k = 1:count
                member = members(k);
                groupIndices(k) = member.GroupIdx;
                imageIndices(k) = find( ...
                    member.Parent.Parent.Images == member.Parent,1);
                objectIndices(k) = member.SelfIdx;
                groupNames(k) = member.GroupName;
                imageNames(k) = member.ImageName;
                objectNames(k) = member.Name;

                % Prefer the current registry name but retain the stable ID if unresolved.
                label = member.Label;

                if isempty(label)
                    labelNames(k) = member.LabelID;
                else
                    labelNames(k) = label.Name;
                end
            end

            % Identity rows switch between full model names and compact indices.
            labels = ["Group","Image","Object","Label",string(measurementLabels(:).')];

            if detail == "Verbose"
                values = { ...
                    categorical(oops.render.escapeTeX(groupNames)), ...
                    categorical(oops.render.escapeTeX(imageNames)), ...
                    categorical(oops.render.escapeTeX(objectNames)), ...
                    categorical(oops.render.escapeTeX(labelNames))};
                formats = repmat({""},1,4);
            else
                values = { ...
                    groupIndices, ...
                    imageIndices, ...
                    objectIndices, ...
                    categorical(oops.render.escapeTeX(labelNames))};
                formats = {"%d","%d","%d",""};
            end

            values = [values,measurementValues(:).'];

            % Measurement rows use one internal fixed-point convention.
            formats = [formats,repmat({"%.2f"},1,numel(measurementValues))];
            template = {cellstr(labels),values,formats};
        end

        function mode = plotMarkerColorMode(~,setting)
        %PLOTMARKERCOLORMODE Translate a user-facing marker mode for MATLABX.

            if setting == "Auto"
                mode = "CData";
            else
                mode = "Custom";
            end
        end

        function [data,colormap,limits] = plotColors(obj,members,mode,magnitudeProperty)
        %PLOTCOLORS Build aligned scalar color data and its lookup map.

            data = cell(size(members));

            switch mode
                case "Group"
                    count = max(1,numel(obj.Project.Groups));
                    colormap = reshape([obj.Project.Groups.Color],3,[])';

                    if isempty(colormap)
                        colormap = get(groot,'defaultAxesColorOrder');
                        colormap = colormap(1,:);
                    end

                    limits = [0.5,count+0.5];

                    for k = 1:numel(members)
                        data{k} = arrayfun(@(member) member.GroupIdx,members{k}(:));
                    end

                case "Label"
                    labels = obj.Project.Labels.labels();
                    count = max(1,numel(labels));
                    colormap = reshape([labels.Color],3,[])';

                    if isempty(colormap)
                        colormap = [0.7 0.7 0.7];
                    end

                    limits = [0.5,count+0.5];
                    ids = obj.Project.Labels.ids();

                    for k = 1:numel(members)
                        data{k} = arrayfun(@(member) find(ids == member.LabelID,1),members{k}(:));
                    end

                otherwise
                    colormap = parula(256);
                    allValues = zeros(0,1);

                    for k = 1:numel(members)
                        data{k} = obj.objectValues(members{k},magnitudeProperty);
                        allValues = [allValues;data{k}(:)]; %#ok<AGROW>
                    end

                    allValues = allValues(isfinite(allValues));

                    if isempty(allValues)
                        limits = [0 1];
                    else
                        limits = [min(allValues),max(allValues)];

                        if limits(1) == limits(2)
                            limits = limits + [-0.5 0.5];
                        end
                    end
            end

            % Filler NaNs keep empty partitions aligned with their placeholder data.
            for k = 1:numel(data)

                if isempty(data{k})
                    data{k} = NaN;
                end

            end
        end

        function refreshOrientationFields(obj,names)
        %REFRESHORIENTATIONFIELDS Draw sampled axial segments over compatible image sources.

            % Active image supplying order, azimuth, and optional object membership.
            image = obj.Project.ActiveImage;

            % Project-wide appearance and sampling preferences for this overlay.
            settings = obj.Settings.AzimuthDisplay;
            viewers = {obj.LeftViewer,obj.RightViewer};

            for k = 1:2

                % Application-owned content and its visibility tool for this panel.
                field = obj.OrientationFields{k};
                tool = obj.OrientationFieldTools{k};

                % Any active-image view with matching XY geometry can host the
                % field. Normalized calibration data describe the group response,
                % rather than the active image, and are deliberately excluded.
                viewer = viewers{k};
                available = names(k) ~= "Calibration" && ...
                    ~isempty(image) && ~isempty(image.Order) && ~isempty(image.Azimuth) && ...
                    viewer.Visible == "on" && viewer.ImageVisible == "on" && ...
                    viewer.ImageData.SizeY == image.Input.SizeY && ...
                    viewer.ImageData.SizeX == image.Input.SizeX;

                if ~available
                    field.clear();
                    tool.setAvailable(false);
                    continue;
                end

                % Preserve availability while deferring pixel traversal and
                % graphics updates until this optional overlay is enabled.
                tool.setAvailable(true);

                if ~tool.Enabled
                    continue;
                end

                % Candidate linear indices are restricted before finite checks so
                % object-only fields never scan the complete result images.
                spacing = settings.ScaleDownFactor;

                if settings.ObjectMask

                    if isempty(image.Mask)
                        indices = zeros(0,1);
                    else
                        indices = find(image.Mask);
                    end

                    if spacing > 1 && ~isempty(indices)
                        [rows,columns] = ind2sub(size(image.Mask),indices);
                        keep = mod(rows-1,spacing) == 0 & ...
                            mod(columns-1,spacing) == 0;
                        indices = indices(keep);
                    end
                else
                    rows = (1:spacing:size(image.Order,1))';
                    columns = 1:spacing:size(image.Order,2);
                    indices = reshape(rows + (columns-1)*size(image.Order,1),[],1);
                end

                % Read each candidate result once, then discard the rare invalid pair.
                angle = image.Azimuth(indices);
                magnitude = image.Order(indices);
                finite = isfinite(angle) & isfinite(magnitude);
                indices = indices(finite);
                angle = angle(finite);
                magnitude = magnitude(finite);

                % Convert only retained candidates to parent-image coordinates.
                [y,x] = ind2sub(size(image.Order),indices);

                % Direction uses the cyclic azimuth map; magnitude uses order.
                if settings.ColorMode == "Magnitude"
                    map = oops.render.colormap(obj.Settings.Colormaps,"Order");
                else
                    map = oops.render.colormap(obj.Settings.Colormaps,"Azimuth");
                end

                field.setStyle( ...
                    ColorMode=settings.ColorMode, ...
                    Colormap=map, ...
                    Color=settings.Color, ...
                    LineWidth=settings.LineWidth, ...
                    Alpha=settings.LineAlpha, ...
                    Scale=settings.LineScale);
                field.setData(x,y,angle,magnitude);
            end

        end

        function refreshViewerRegions(obj)
        %REFRESHVIEWERREGIONS Reconcile masks and batched object boundaries.
        %
        % Mask and object coordinates belong to the active input image. They
        % apply to all four frames, but not to unavailable sources or a
        % calibration stack with different spatial dimensions.

            if obj.SyncingOverlays || obj.Closing || isempty(obj.Project) || ...
                    isempty(obj.LeftViewer) || isempty(obj.RightViewer)
                return;
            end

            % Registry changes can emit activation/selection events. Suppress
            % those callbacks until both viewers reflect the model's membership.
            obj.SyncingOverlays = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.endOverlaySync());

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Left and right ImageAxes handles in panel order.
            viewers = {obj.LeftViewer,obj.RightViewer};

            % Boundary data are derived at most once and shared by both viewers.
            payload = [];

            % Reconcile the active image's mask and object boundaries in each viewer.
            for k = 1:2

                % ImageAxes for the current left/right panel.
                viewer = viewers{k};

                if viewer.Visible == "off"
                    continue;
                end

                % Whether this viewer displays an available, spatially compatible image.
                ready = obj.PanelContentNames(k) ~= "Calibration" && ...
                    ~isempty(image) && viewer.ImageVisible == "on";

                if ready
                    ready = viewer.ImageData.SizeY == image.Input.SizeY && ...
                        viewer.ImageData.SizeX == image.Input.SizeX;
                end

                % Committed parent-image mask supplied to the viewer's mask tool.
                mask = [];

                if ready
                    if ~isempty(image.Mask)
                        mask = image.Mask;
                    end

                end

                % ImageData replacement clears the mask. Restore it only when
                % visible; the native Mask tool requests it when later enabled.
                if viewer.MaskEnabled && ~isequal(viewer.Mask,mask)
                    viewer.Mask = mask;
                end

                % Keep the mask current independently, but defer boundary
                % extraction and hit-map construction while boundaries are hidden.
                if ~viewer.Tools.Boundaries.Enabled
                    continue;
                end

                collection = obj.ObjectBoundaryCollections{k};
                obj.configureBoundaryCollection(collection);

                if ~ready
                    collection.setData(strings(1,0),{}, ...
                        HitMap=[],Colors=zeros(0,3),Labels=strings(1,0));
                    continue;
                end

                if isempty(payload)
                    payload = obj.objectBoundaryPayload(image);
                end

                collection.setData(payload.IDs,payload.Vertices, ...
                    HitMap=payload.HitMap,Colors=payload.Colors, ...
                    Labels=payload.Labels);

            end

            % With membership synchronized, apply the independent model-owned
            % active/selected IDs. That method has its own callback guard.
            clear guard;
            obj.syncOverlayState();
        end

        function refreshOverlayAppearance(obj)
        %REFRESHOVERLAYAPPEARANCE Reconcile shared and per-object boundary styles.

            obj.refreshViewerRegions();
        end

        function configureBoundaryCollection(obj,collection)
        %CONFIGUREBOUNDARYCOLLECTION Apply shared geometry and state appearance.

            settings = obj.Settings.ObjectSelection;
            if settings.BoxType == "Box"
                collection.DisplayGeometry = "boundingbox";
            else
                collection.DisplayGeometry = "boundary";
            end
            collection.UsePerBoundaryColors = settings.ColorMode == "Label";
            collection.EdgeColor = settings.Color;
            collection.LineWidth = settings.LineWidth;
            collection.SelectionLineWidth = settings.SelectedLineWidth;
            collection.ActiveLineWidth = settings.ActiveLineWidth;
            collection.HoverLineWidth = settings.HoverLineWidth;
            collection.ShowActiveEdgeWhenSelected = ...
                settings.ShowActiveWhenSelected;

            collection.SelectionEdgeColor = [];
            if settings.SelectedColorMode == "Custom"
                collection.SelectionEdgeColor = settings.SelectedColor;
            end

            collection.ActiveEdgeColor = [];
            if settings.ActiveColorMode == "Custom"
                collection.ActiveEdgeColor = settings.ActiveColor;
            end

            collection.HoverEdgeColor = [];
            if settings.HoverColorMode == "Custom"
                collection.HoverEdgeColor = settings.HoverColor;
            end
        end

        function payload = objectBoundaryPayload(obj,image)
        %OBJECTBOUNDARYPAYLOAD Build one collection update from model objects.

            regions = image.Objects;
            count = numel(regions);
            payload.IDs = reshape(oops.model.internal.ids(regions),1,[]);
            payload.Vertices = cell(1,count);
            payload.Colors = repmat(obj.Settings.ObjectSelection.Color,count,1);
            payload.Labels = strings(1,count);
            payload.HitMap = zeros(image.Input.SizeY,image.Input.SizeX,'uint32');

            for index = 1:count
                region = regions(index);
                payload.Vertices{index} = region.getBoundaryVertices();
                payload.Labels(index) = region.Name;
                payload.HitMap(region.PixelIdxList) = uint32(index);

                if obj.Settings.ObjectSelection.ColorMode == "Label"
                    label = region.Label;
                    if ~isempty(label)
                        payload.Colors(index,:) = label.Color;
                    end
                end
            end
        end

        function onBoundaryCollectionVisibilityChanged(obj,collection)
        %ONBOUNDARYCOLLECTIONVISIBILITYCHANGED Populate a newly shown collection.

            if collection.Visible == "on" && ~obj.SyncingOverlays && ~obj.Closing
                obj.refreshViewerRegions();
            end
        end

        function syncOverlayState(obj)
        %SYNCOVERLAYSTATE Apply model bookmarks and checks to both viewer registries.

            if obj.SyncingOverlays || obj.Closing
                return;
            end

            obj.SyncingOverlays = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.endOverlaySync());

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Copy model active/selected IDs into each viewer's boundary set.
            for viewer = {obj.LeftViewer,obj.RightViewer}

                % Left and right viewer handles whose overlay navigation is synchronized.
                axes = viewer{1};

                if ~axes.Tools.Boundaries.Enabled
                    continue;
                end

                % Selected model IDs restricted to boundaries available in this viewer.
                ids = strings(0,1);

                % Model active-object ID restricted to overlays available in this viewer.
                active = "";

                if ~isempty(image)

                    % Model object IDs currently represented in this viewer.
                    available = axes.Overlays.ids(Type="Boundary");
                    ids = image.SelectedObjectIDs(ismember(image.SelectedObjectIDs,available));

                    if ismember(image.ActiveObjectID,available)
                        active = image.ActiveObjectID;
                    end

                end

                % Model active-object ID, cleared when this viewer has no matching boundary.
                current = axes.Overlays.getSelectedIDs(Type="Boundary");
                % The manager's selection setter repaints even unchanged sets.
                if ~isequal(current(:),ids(:))
                    axes.Overlays.setSelected(ids,Type="Boundary");
                end

                currentActive = axes.Overlays.getActiveID(Type="Boundary");
                if currentActive ~= active
                    if strlength(active) > 0
                        axes.Overlays.setActive(active);
                    elseif strlength(currentActive) > 0
                        axes.Overlays.clearActive();
                    end
                end
            end

        end

        function endOverlaySync(obj)
        %ENDOVERLAYSYNC Release callback suppression after programmatic overlay updates.

            obj.SyncingOverlays = false;
        end

        function onObjectBoundaryActivated(obj,data)
        %ONOBJECTBOUNDARYACTIVATED Store activation independently of batch selection.

            if obj.SyncingOverlays || obj.Processing || obj.Closing
                return;
            end

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            if isempty(image)
                return;
            end

            image.setActiveObject(data.ID);
        end

        function onObjectBoundarySelectionChanged(obj,data)
        %ONOBJECTBOUNDARYSELECTIONCHANGED Store selection and update tree checks.

            if obj.SyncingOverlays || obj.Processing || obj.Closing
                return;
            end

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            if isempty(image)
                return;
            end

            image.setSelectedObjects(data.IDs);
        end

        function onObjectBoundariesDeleteRequested(obj,data)
        %ONOBJECTBOUNDARIESDELETEREQUESTED Commit one batch before changing overlays.

            if obj.SyncingOverlays || obj.Processing || obj.Closing
                return;
            end

            obj.deleteObjects(data.IDs);
        end

        function deleteObjects(obj,ids)
        %DELETEOBJECTS Remove one batch and reconcile UI once without rescaling images.
        % The tool leaves its overlays and navigation intact until this completes.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            if isempty(image) || isempty(ids)
                return;
            end

            % Processing-guard state saved for restoration after this operation.
            previous = obj.Processing;
            obj.Processing = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.restoreProcessing(previous));
            image.removeObjects(ids);
            % Suppress navigation events while choosing a surviving active object.
            obj.reconcileActive();

            % Left and right panel source names in viewer order.
            names = [obj.Settings.View.LeftSource,obj.Settings.View.RightSource];
            obj.ViewerKeys(names == "Mask") = "";
            clear guard;

            if ~previous
                obj.refreshNavigation();
                obj.refreshViewers(false,false);
            end

        end

        function resizeViewers(obj)
        %RESIZEVIEWERS Keep both panel interiors square plus the ImageAxes title chrome.
        % Outer-panel chrome is accounted for separately from ImageAxes chrome.

            if obj.Resizing || obj.Closing || isempty(obj.ViewerPanels)
                return;
            end

            obj.Resizing = true;

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() obj.endResize());
            % Web UI child positions can lag behind the figure size or come
            % from different layout passes. Derive the two equal allocations
            % from the current figure and the fixed settings-column contract.

            % Horizontal space remaining after the fixed settings column and outer padding.
            available = obj.Fig.InnerPosition(3)-sum(obj.Grid.Padding([1 3]))- ...
                obj.Grid.ColumnWidth{1}-obj.Grid.ColumnSpacing;

            % Equal width available to each viewer panel after right-pane spacing.
            panelWidth = (available-sum(obj.RightPane.Padding([1 3]))- ...
                obj.RightPane.ColumnSpacing)/2;

            % First viewer panel used to measure shared panel-title chrome.
            panel = obj.ViewerPanels(1);

            % ImageAxes title-bar height determined by the UI calibration helper.
            viewerChrome = obj.UICal.uipanelTopChromeHeightPx(12);

            % Outer panel title-bar height for its current font settings.
            panelChrome = obj.UICal.uipanelTopChromeHeightPx(panel.FontSize,FontUnits=panel.FontUnits);
            % Panel borders reduce width and height equally; their contributions
            % cancel when converting the desired inner aspect to an outer height.

            % Keep the main row sized for the large left viewer in every view.
            % Enlarging it for the object grid would make the left slot taller
            % than wide and cause ImageAxes to letterbox the displayed image.
            desiredOuterHeight = panelWidth+viewerChrome+panelChrome;

            if obj.Settings.View.RightSource == "Objects"

                % Standard spacing is retained between all four object panels.
                % Extra horizontal width becomes a control gutter after the
                % compact quadrant block instead of an oversized column gap.
                gap = obj.RightPane.ColumnSpacing;
                chrome = viewerChrome+panelChrome;
                quadrantWidth = max(1,(desiredOuterHeight-2*chrome-gap)/2);
                quadrantHeight = quadrantWidth+chrome;
                gutterWidth = max(0,panelWidth-2*quadrantWidth-2*gap);

                obj.ObjectViewerGrid.ColumnWidth = {quadrantWidth,quadrantWidth,gutterWidth};
                obj.ObjectViewerGrid.RowHeight = {quadrantHeight,quadrantHeight};
                obj.ObjectViewerGrid.ColumnSpacing = gap;
                obj.ObjectViewerGrid.RowSpacing = gap;

                % Numeric center rows make both buttons square at the current gutter width.
                obj.ObjectNavigationGrid.RowHeight = { ...
                    '1x',gutterWidth,gutterWidth,'1x',gutterWidth};
                obj.ObjectNavigationGrid.RowSpacing = gap;
            end

            obj.RightPane.RowHeight = {desiredOuterHeight,'1x'};
            drawnow;
        end

        function appendLog(obj,lines)
        %APPENDLOG Keep the latest UI lines; the logger/file retains the full session.

            if obj.Closing || isempty(obj.LogTextArea) || ~isvalid(obj.LogTextArea)
                return;
            end

            % Existing textarea lines followed by the newly delivered logger lines.
            values = [string(obj.LogTextArea.Value(:));string(lines(:))];
            obj.LogTextArea.Value = cellstr(values(max(1,end-999):end));
            scroll(obj.LogTextArea,'bottom');
        end

        function buildColormapControls(obj)
        %BUILDCOLORMAPCONTROLS Use one domain selector, preview, and registry category tree.

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem("Image Display").Pane;
            set(pane,'ColumnWidth',{70,'1x'},'RowHeight',{24,24,24,24,200}, ...
                'Padding',5,'RowSpacing',5,'ColumnSpacing',5);
            obj.ColormapTypeLabel = uilabel(pane,'Text','Type','FontColor',[.85 .85 .85]);
            obj.ColormapTypeLabel.Layout.Row = 1;
            obj.ColormapTypeLabel.Layout.Column = 1;
            obj.ColormapDomain = uidropdown(pane, ...
                'Items',{'Primary intensity','Auxiliary channels','Order','Azimuth','Mask'}, ...
                'ItemsData',{'PrimaryIntensity','Auxiliary','Order','Azimuth','Mask'}, ...
                'Value','PrimaryIntensity','BackgroundColor',[.3 .3 .3],'FontColor',[.9 .9 .9], ...
                'ValueChangedFcn',@(~,~) obj.runCallback(@() obj.refreshColormapControls()));
            obj.ColormapDomain.Layout.Row = 1;
            obj.ColormapDomain.Layout.Column = 2;
            obj.ColormapChannelLabel = uilabel(pane,'Text','Channel','FontColor',[.85 .85 .85]);
            obj.ColormapChannelLabel.Layout.Row = 2;
            obj.ColormapChannelLabel.Layout.Column = 1;
            obj.ColormapChannel = uidropdown(pane,'Items',{'All primary channels'}, ...
                'ItemsData',{'__all__'},'BackgroundColor',[.3 .3 .3], ...
                'FontColor',[.9 .9 .9], ...
                'ValueChangedFcn',@(~,~) obj.runCallback(@() obj.refreshColormapControls()));
            obj.ColormapChannel.Layout.Row = 2;
            obj.ColormapChannel.Layout.Column = 2;
            obj.ColormapModeLabel = uilabel(pane,'Text','Mode','FontColor',[.85 .85 .85]);
            obj.ColormapModeLabel.Layout.Row = 3;
            obj.ColormapModeLabel.Layout.Column = 1;
            obj.ColormapMode = uidropdown(pane,'Items',{'Colors','LUTs'}, ...
                'ItemsData',{'colors','luts'},'BackgroundColor',[.3 .3 .3], ...
                'FontColor',[.9 .9 .9], ...
                'ValueChangedFcn',@(~,~) obj.runCallback(@() obj.onColorModeChosen()));
            obj.ColormapMode.Layout.Row = 3;
            obj.ColormapMode.Layout.Column = 2;
            obj.ColormapAppearanceLabel = uilabel(pane,'Text','Color','FontColor',[.85 .85 .85]);
            obj.ColormapAppearanceLabel.Layout.Row = 4;
            obj.ColormapAppearanceLabel.Layout.Column = 1;
            obj.ColormapColor = uidropdown(pane, ...
                'Items',matlabx.ui.axes.ImageAxes.getColorNames(), ...
                'BackgroundColor',[.3 .3 .3],'FontColor',[.9 .9 .9], ...
                'ValueChangedFcn',@(~,~) obj.runCallback(@() obj.onDisplayColorChosen()));
            obj.ColormapColor.Layout.Row = 4;
            obj.ColormapColor.Layout.Column = 2;
            obj.ColormapPreview = uiimage(pane,'ScaleMethod','stretch');
            obj.ColormapPreview.Layout.Row = 4;
            obj.ColormapPreview.Layout.Column = 2;
            obj.ColormapTree = uitree(pane,'BackgroundColor',[.18 .18 .18],'FontColor',[.9 .9 .9], ...
                'SelectionChangedFcn',@(src,~) obj.runCallback(@() obj.onColormapChosen(src)));
            obj.ColormapTree.Layout.Row = 5;
            obj.ColormapTree.Layout.Column = [1 2];

            % Registered colormap categories to create as tree branches.
            categories = matlabx.colors.maps.Registry.categories();

            % Create a tree branch for each registered map category.
            for k = 1:numel(categories)

                % Category represented by the current parent tree node.
                category = categories(k);

                % Tree node being created, inspected, or activated.
                node = uitreenode(obj.ColormapTree,'Text',char(category));

                % Registered map names within the current category.
                names = matlabx.colors.maps.Registry.names(category);

                % Create a selectable leaf for each map within that category.
                for j = 1:numel(names)
                    uitreenode(node,'Text',char(names(j)), ...
                        'NodeData',struct('Category',category,'Name',names(j)));
                end

            end

            obj.refreshColormapControls();
        end

        function refreshColormapControls(obj)
        %REFRESHCOLORMAPCONTROLS Restore the chosen domain's map and rendered preview.

            if isempty(obj.ColormapTree)
                return;
            end

            % Internal settings key for the selected user-facing display domain.
            domain = string(obj.ColormapDomain.Value);

            channelDomain = ismember(domain,["PrimaryIntensity","Auxiliary"]);
            obj.ColormapChannel.Visible = matlab.lang.OnOffSwitchState(channelDomain);
            obj.ColormapChannelLabel.Visible = matlab.lang.OnOffSwitchState(channelDomain);
            definitions = obj.displayChannels(domain);

            if channelDomain
                previousChannel = string(obj.ColormapChannel.Value);
                prefix = "All "+lower(strrep(domain,"PrimaryIntensity","primary"))+" channels";
                obj.ColormapChannel.Items = cellstr([prefix string({definitions.Name})]);
                obj.ColormapChannel.ItemsData = cellstr(["__all__" string({definitions.ID})]);
                if ismember(previousChannel,string(obj.ColormapChannel.ItemsData))
                    obj.ColormapChannel.Value = char(previousChannel);
                else
                    obj.ColormapChannel.Value = '__all__';
                end
            end

            modeProperty = domain + "ColorMode";
            obj.ColormapMode.Value = char(obj.Settings.Display.(modeProperty));

            % Project-wide map/category assignments for all display domains.
            maps = obj.Settings.Colormaps;
            [mapName,mapCategory,colorName] = obj.displayAppearance(domain,definitions);
            obj.ColormapColor.Value = char(colorName);
            colorsMode = string(obj.ColormapMode.Value) == "colors";
            if colorsMode
                obj.ColormapAppearanceLabel.Text = 'Color';
            else
                obj.ColormapAppearanceLabel.Text = 'LUT';
            end
            obj.ColormapColor.Visible = matlab.lang.OnOffSwitchState(colorsMode);
            obj.ColormapTree.Visible = matlab.lang.OnOffSwitchState(~colorsMode);
            obj.ColormapPreview.Visible = matlab.lang.OnOffSwitchState(~colorsMode);
            pane = obj.SettingsAccordion.getItem("Image Display").Pane;
            pane.RowHeight = {24,24*double(channelDomain),24,24,200*double(~colorsMode)};

            % All category/map nodes inspected to restore the assigned map highlight.
            nodes = findall(obj.ColormapTree,'Type','uitreenode');
            obj.ColormapTree.SelectedNodes = [];

            % Find the map leaf corresponding to the selected display domain's assignment.
            for k = 1:numel(nodes)

                % Node/source metadata read for the current UI update.
                data = nodes(k).NodeData;

                if isstruct(data) && data.Name == mapName && data.Category == mapCategory
                    obj.ColormapTree.SelectedNodes = nodes(k);
                    expand(nodes(k).Parent);
                    break;
                end

            end

            % Selected lookup table rendered as the preview image.
            map = matlabx.colors.maps.Registry.map(mapName,mapCategory);
            if domain == "Azimuth"
                map = oops.render.colormap(maps,"Azimuth");
            end
            obj.ColormapPreview.ImageSource = permute(repmat(map,1,1,16),[3 1 2]);
        end

        function onColormapChosen(obj,tree)
        %ONCOLORMAPCHOSEN Apply a leaf to the selected domain, independently of other maps.

            % Tree node being created, inspected, or activated.
            node = tree.SelectedNodes;

            if isempty(node) || ~isstruct(node(1).NodeData)
                return;
            end

            % Chosen leaf's registry category and map name.
            data = node(1).NodeData;

            % Display/settings domain selected by the current control.
            domain = string(obj.ColormapDomain.Value);

            % Project colormap settings receiving the selected domain's assignment.
            maps = obj.Settings.Colormaps;
            % Temporarily suspend view updates between category/name changes so
            % a name never resolves against the wrong category during a switch.
            obj.Processing = true;

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() obj.endProcessing());
            definitions = obj.displayChannels(domain);
            if ismember(domain,["PrimaryIntensity","Auxiliary"])
                definitions = obj.selectedDisplayChannels(definitions);
                for definition = reshape(definitions,1,[])
                    definition.setColormap(data.Name,data.Category);
                end
            else
                maps.setMap(domain,data.Name,data.Category);
            end
            obj.Processing = false;
            obj.refreshColormapControls();
            obj.refreshViewers(true);
        end

        function onColorModeChosen(obj)
        %ONCOLORMODECHOSEN Store the selected viewer/domain coloring policy.

            domain = string(obj.ColormapDomain.Value);
            obj.Settings.Display.(domain+"ColorMode") = string(obj.ColormapMode.Value);
            obj.refreshColormapControls();
            obj.refreshViewers(true);
        end

        function onDisplayColorChosen(obj)
        %ONDISPLAYCOLORCHOSEN Apply a canonical color to a domain or channels.

            domain = string(obj.ColormapDomain.Value);
            color = string(obj.ColormapColor.Value);
            if ismember(domain,["PrimaryIntensity","Auxiliary"])
                definitions = obj.selectedDisplayChannels(obj.displayChannels(domain));
                [~,rgb] = matlabx.image.normalizeComponentColor(color);
                for definition = reshape(definitions,1,[])
                    definition.setColor(rgb);
                end
            else
                obj.Settings.Colormaps.(domain+"Color") = color;
            end
            obj.refreshViewers(true);
        end

        function definitions = displayChannels(obj,domain)
        %DISPLAYCHANNELS Return definitions participating in one channel domain.

            definitions = oops.model.ChannelDefinition.empty(0,1);
            if isempty(obj.Project), return; end
            definitions = obj.Project.Channels.Channels;
            if domain == "PrimaryIntensity"
                definitions = definitions([definitions.IsPrimary]);
            elseif domain == "Auxiliary"
                definitions = definitions([definitions.IsAuxiliary]);
            else
                definitions = oops.model.ChannelDefinition.empty(0,1);
            end
        end

        function definitions = selectedDisplayChannels(obj,definitions)
        %SELECTEDDISPLAYCHANNELS Resolve the current channel or the All target.

            id = string(obj.ColormapChannel.Value);
            if id ~= "__all__"
                definitions = definitions(string({definitions.ID}) == id);
            end
        end

        function [name,category,color] = displayAppearance(obj,domain,definitions)
        %DISPLAYAPPEARANCE Resolve the selected channel/domain appearance.

            if ismember(domain,["PrimaryIntensity","Auxiliary"])
                selected = obj.selectedDisplayChannels(definitions);
                if isempty(selected), selected = definitions; end
                if isempty(selected)
                    name = "gray"; category = "MATLAB"; color = "gray";
                    return;
                end
                name = selected(1).Colormap;
                category = selected(1).ColormapCategory;
                color = oops.render.canonicalComponentColor(selected(1).Color);
            else
                name = obj.Settings.Colormaps.(domain);
                category = obj.Settings.Colormaps.(domain+"Category");
                color = obj.Settings.Colormaps.(domain+"Color");
            end
        end

        function menu = navigationMenu(obj,title,id)
        %NAVIGATIONMENU Bind node-specific actions to IDs, never the current highlight.

            % Context menu bound to this tree/node identity.
            menu = uicontextmenu(obj.Fig);
            menu.UserData = id;

            if title == "Groups"
                uimenu(menu,'Text','New group...','MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptGroup()));

                if id ~= ""
                    uimenu(menu,'Text','Edit group...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptGroup(string(menu.UserData))));

                    % Occasional calibration actions grouped away from routine navigation.
                    calibration = uimenu(menu,'Text','Calibration');
                    uimenu(calibration,'Text','View assignment...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.showCalibrationAssignment(string(menu.UserData))));
                    uimenu(calibration,'Text','Assign imported calibrations...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseRegisteredCalibrations(string(menu.UserData))));
                    uimenu(calibration,'Text','Import and assign...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseCalibrationFiles(string(menu.UserData))));
                    uimenu(calibration,'Text','Clear assignment','Separator','on', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.applyCalibrationAssignment(string(menu.UserData),strings(0,1))));
                end

                % Domain label used for node-specific and batch deletion actions.
                singular = "group";
            elseif title == "Images"
                singular = "image";

                if id ~= ""
                    uimenu(menu,'Text','Info...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.showImageInfo(string(menu.UserData))));
                end
            else
                singular = "object";
            end

            % Batch-selection commands operate on the collection represented by this tree.
            uimenu(menu,'Text','Select all','Separator','on', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.changeTreeSelection(title,"All")));
            uimenu(menu,'Text','Clear selection', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.changeTreeSelection(title,"Clear")));
            uimenu(menu,'Text','Invert selection', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.changeTreeSelection(title,"Invert")));

            if id ~= ""
                uimenu(menu,'Text',char("Delete "+singular),'MenuSelectedFcn', ...
                    @(~,~) obj.runCallback(@() obj.deleteNavigation(title,string(menu.UserData))));
            end

            uimenu(menu,'Text',char("Delete selected "+lower(title)),'MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.deleteNavigation(title,"")));
        end

        function showImageInfo(obj,id)
        %SHOWIMAGEINFO Display compact model metadata for one context-clicked image.

            group = obj.Project.ActiveGroup;

            if isempty(group)
                error('oops:app:UnknownImage','No active group contains this image.');
            end

            image = oops.model.internal.resolve(group.Images,id);

            if isempty(image)
                error('oops:app:UnknownImage','The selected image no longer exists.');
            end

            if ~isempty(obj.ImageInfoWindow) && isvalid(obj.ImageInfoWindow)
                delete(obj.ImageInfoWindow);
            end

            lines = cellstr(matlabx.struct.prettyPrint( ...
                image.infoStruct(),StringArrayStyle="lines"));
            obj.ImageInfoWindow = matlabx.app.TextWindow( ...
                'Title',char(image.Name + " Info"), ...
                'Text',lines, ...
                'WordWrap','off', ...
                'Position',[0 0 700 700], ...
                'ClosedFcn',@(~,~) obj.clearImageInfoWindow());
        end

        function clearImageInfoWindow(obj)
        %CLEARIMAGEINFOWINDOW Release the controller reference after manual closure.

            obj.ImageInfoWindow = [];
        end

        function showRuntimeStatus(obj)
        %SHOWRUNTIMESTATUS Display disposable caches and resident analysis arrays.

            if isempty(obj.Project)
                return;
            end

            if ~isempty(obj.RuntimeStatusWindow) && isvalid(obj.RuntimeStatusWindow)
                delete(obj.RuntimeStatusWindow);
            end

            % The headless report remains programmatically accessible; this
            % controller only converts its tables into stable plain text.
            status = oops.runtime.cacheStatus(obj.Project);
            lines = runtimeStatusLines(status);

            obj.RuntimeStatusWindow = matlabx.app.TextWindow( ...
                'Title','OOPS Runtime Status', ...
                'Text',cellstr(lines), ...
                'WordWrap','off', ...
                'Position',[0 0 1100 700], ...
                'ClosedFcn',@(~,~) obj.clearRuntimeStatusWindow());
        end

        function clearRuntimeStatusWindow(obj)
        %CLEARRUNTIMESTATUSWINDOW Release the closed diagnostic window handle.

            obj.RuntimeStatusWindow = [];
        end

        function changeTreeSelection(obj,title,operation)
        %CHANGETREESELECTION Apply a bulk checkbox operation to one navigation domain.

            switch title
                case "Groups"
                    children = obj.Project.Groups;
                    selected = obj.Project.SelectedGroupIDs;
                    setter = @(ids) obj.Project.setSelectedGroups(ids);
                case "Images"
                    group = obj.Project.ActiveGroup;

                    if isempty(group)
                        return;
                    end

                    children = group.Images;
                    selected = group.SelectedImageIDs;
                    setter = @(ids) group.setSelectedImages(ids);
                otherwise
                    image = obj.Project.ActiveImage;

                    if isempty(image)
                        return;
                    end

                    children = image.Objects;
                    selected = image.SelectedObjectIDs;
                    setter = @(ids) image.setSelectedObjects(ids);
            end

            % Complete collection of IDs represented by the chosen tree.
            ids = oops.model.internal.ids(children);

            switch operation
                case "All"
                    next = ids;
                case "Clear"
                    next = strings(0,1);
                case "Invert"
                    next = ids(~ismember(ids,selected));
            end

            setter(next);
        end

        function deleteNavigation(obj,title,id)
        %DELETENAVIGATION Delete checked IDs or the context-clicked group, image, or object.

            % Project whose hierarchy supplies the navigation/operation targets.
            p = obj.Project;

            if title == "Objects"

                % Active image supplying data and object membership for this operation.
                image = p.ActiveImage;

                if isempty(image)
                    return;
                end

                % Model IDs represented by the current operation or navigation control.
                ids = id;

                if id == ""
                    ids = image.SelectedObjectIDs;
                end

                obj.deleteObjects(ids);
                return;
            end

            obj.Processing = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.endProcessing());

            if title == "Groups"
                ids = id;

                if id == ""
                    ids = p.SelectedGroupIDs;
                end

                % Remove each target group and its explicitly owned image models.
                for k = 1:numel(ids)

                    % Active/target group supplying its owned images and bookmarks.
                    group = oops.model.internal.resolve(p.Groups,ids(k));

                    if isempty(group)
                        continue;
                    end

                    % Images owned by the group being removed, retained for explicit destruction.
                    images = group.Images;
                    p.removeGroup(group);
                    delete(images);
                    delete(group);
                end

            else
                group = p.ActiveGroup;

                if isempty(group)
                    return;
                end

                ids = id;

                if id == ""
                    ids = group.SelectedImageIDs;
                end

                images = oops.model.Image.empty(0,1);

                for k = 1:numel(ids)
                    image = oops.model.internal.resolve(group.Images,ids(k));
                    if isempty(image)
                        continue;
                    end

                    images(end+1,1) = image; %#ok<AGROW>
                end

                if ~isempty(images)
                    group.removeImages(images);
                    delete(images);
                end

            end

            obj.reconcileActive();
        end

        function chooseAuxiliaryChannels(obj)
        %CHOOSEAUXILIARYCHANNELS Stage batch file pairing and semantic mappings.

            group = obj.Project.ActiveGroup;

            if isempty(group)
                uialert(obj.Fig,'Select a group containing target images first.', ...
                    'Import auxiliary channels','Icon','info');
                return;
            end

            % Checked images are batch targets; the active image is the fallback.
            ids = group.SelectedImageIDs;

            if isempty(ids) && ~isempty(group.ActiveImage)
                ids = group.ActiveImage.ID;
            end

            images = oops.model.Image.empty(0,1);

            for id = reshape(ids,1,[])
                image = oops.model.internal.resolve(group.Images,id);

                if ~isempty(image)
                    images(end+1,1) = image; %#ok<AGROW>
                end
            end

            if isempty(images)
                uialert(obj.Fig,'Check one or more images, or activate one image.', ...
                    'Import auxiliary channels','Icon','info');
                return;
            end

            [files,folder] = matlabx.image.io.uigetimagefile([], ...
                sprintf('Select %d auxiliary image file(s)',numel(images)), ...
                char(obj.Settings.IO.DefaultFolder),MultiSelect='on');
            obj.focusWindow();
            cleanupFocus = onCleanup(@() obj.focusWindow()); %#ok<NASGU>

            if isequal(files,0)
                return;
            end

            files = fullfile(string(folder),string(files));
            files = files(:);

            if numel(files) ~= numel(images)
                uialert(obj.Fig, ...
                    sprintf('Select exactly %d file(s), one for each target image.',numel(images)), ...
                    'File count mismatch','Icon','warning');
                return;
            end

            obj.Settings.IO.DefaultFolder = string(folder);
            plan = oops.app.auxiliaryChannelImportDialog( ...
                obj.Fig,images,files,obj.Project.Channels);

            if isempty(plan)
                return;
            end

            obj.commitAuxiliaryChannelImport(plan);
        end

        function commitAuxiliaryChannelImport(obj,plan)
        %COMMITAUXILIARYCHANNELIMPORT Apply a validated dialog plan to the model.

            previous = obj.Processing;
            obj.Processing = true;
            guard = onCleanup(@() obj.restoreProcessing(previous));
            importedImageIDs = strings(numel(plan),1);

            for k = 1:numel(plan)
                definition = obj.Project.Channels.findOrAdd( ...
                    plan(k).ChannelName,plan(k).ChannelColor);
                plan(k).Image.addAuxiliaryChannel( ...
                    definition.ID,plan(k).Input,plan(k).ComponentIndex);
                importedImageIDs(k) = plan(k).Image.ID;
            end

            for imageID = reshape(unique(importedImageIDs,'stable'),1,[])
                index = find(importedImageIDs == imageID,1);
                oops.analysis.Analyzer.measureAuxiliaryObjects(plan(index).Image);
            end

            % Show the first imported image and its stable registry-ordered stack.
            obj.Project.setActiveImage(plan(1).Image);
            obj.Settings.View.LeftSource = "AverageIntensity";
            obj.Settings.View.RightSource = "AuxiliaryChannels";
            clear guard;
            obj.refreshMeasurementControls();
            obj.ViewerKeys(:) = "";
            obj.refreshViewers(true);
            oops.Log.INFO(sprintf( ...
                'Imported %d auxiliary channel assignment(s) for %d image(s).', ...
                numel(plan),numel(unique(importedImageIDs))));
        end

        function chooseCalibrationFiles(obj,groupID)
        %CHOOSECALIBRATIONFILES Register files, optionally assigning a clicked group.

            if nargin < 2
                groupID = "";
            end

            % Selected calibration filenames and directory, or zero on cancellation.
            [files,folder] = matlabx.image.io.uigetimagefile([], ...
                'Select four-angle calibration stacks',char(obj.Settings.IO.DefaultFolder),MultiSelect='on');
            % Native file dialogs can leave MATLAB behind other windows. Raise
            % this figure on return, including cancellation, and after loading.
            obj.focusWindow();

            % Cleanup guard returning focus to the visible GUI after loading completes.
            cleanupFocus = onCleanup(@() obj.focusWindow()); %#ok<NASGU>

            if isequal(files,0)
                return;
            end

            obj.Settings.IO.DefaultFolder = string(folder);

            if groupID == ""
                obj.registerCalibrations(fullfile(folder,string(files)));
            else

                % Context-clicked group remains the target regardless of active/check state.
                group = oops.model.internal.resolve(obj.Project.Groups,groupID);

                if isempty(group)
                    error('oops:app:UnknownGroup','The selected group no longer exists.');
                end

                obj.loadCalibrations(fullfile(folder,string(files)),group);
            end
        end

        function calibrations = registerCalibrationFiles(obj,files,progress)
        %REGISTERCALIBRATIONFILES Open files and add reusable project registry entries.

            % Column string array of input paths processed in file-selection order.
            files = string(files(:));

            % Registered calibration handles collected from the chosen files.
            calibrations = oops.model.Calibration.empty(0,1);

            % Open and register each source without assigning it to any group here.
            for k = 1:numel(files)

                % Filename stem used as the registered calibration's initial name.
                [~,name] = fileparts(files(k));
                oops.runtime.updateProgress(progress, ...
                    sprintf('Calibration %d/%d: %s\nOpening four-angle stack...',k,numel(files),name), ...
                    (k-1)/numel(files));

                % Lazy calibration source opened from the current file.
                input = oops.io.readInput(files(k));

                % Existing registry member reused when the same source was already opened.
                calibration = obj.Project.addCalibration(input,string(name));
                calibrations(end+1,1) = calibration; %#ok<AGROW>
            end
        end

        function warnCalibrationState(obj)
        %WARNCALIBRATIONSTATE Report incomplete group assignments and unused files.

            % Groups currently relying on raw input because no calibration is assigned.
            uncalibrated = arrayfun(@(group) isempty(group.CalibrationIDs),obj.Project.Groups);

            if any(uncalibrated)
                oops.Log.WARN(sprintf('%d group(s) have no assigned calibration files.',nnz(uncalibrated)));
            end

            % Registry IDs referenced by at least one current group assignment.
            assigned = strings(0,1);

            for group = reshape(obj.Project.Groups,1,[])
                assigned = [assigned;group.CalibrationIDs]; %#ok<AGROW>
            end

            % Registered sources that remain available but unused by every group.
            registered = oops.model.internal.ids(obj.Project.Calibrations);
            unused = registered(~ismember(registered,assigned));

            if ~isempty(unused)
                oops.Log.WARN(sprintf('%d registered calibration file(s) are not assigned to any group.',numel(unused)));
            end
        end

        function showCalibrationAssignment(obj,groupID)
        %SHOWCALIBRATIONASSIGNMENT List the registry entries assigned to one group.

            % Context-clicked group resolved independently of active tree selection.
            group = oops.model.internal.resolve(obj.Project.Groups,groupID);

            if isempty(group)
                error('oops:app:UnknownGroup','The selected group no longer exists.');
            end

            % Human-readable lines containing names, source paths, and stable IDs.
            lines = strings(0,1);

            for calibration = reshape(group.Calibrations,1,[])
                path = obj.calibrationPath(calibration);

                if path == ""
                    path = "In-memory source";
                end

                lines(end+1,1) = calibration.Name + newline + ...
                    "File: " + path + newline + "ID: " + calibration.ID; %#ok<AGROW>
            end

            if isempty(lines)
                message = "No calibration files are assigned to " + group.Name + ".";
            else
                message = strjoin(lines,sprintf('\n\n'));
            end

            uialert(obj.Fig,message,char(group.Name + " — Calibration assignment"),'Icon','info');
        end

        function chooseRegisteredCalibrations(obj,groupID)
        %CHOOSEREGISTEREDCALIBRATIONS Edit one group's assignment from the registry.

            % Context-clicked group resolved independently of active tree selection.
            group = oops.model.internal.resolve(obj.Project.Groups,groupID);

            if isempty(group)
                error('oops:app:UnknownGroup','The selected group no longer exists.');
            end

            if isempty(obj.Project.Calibrations)
                uialert(obj.Fig, ...
                    'No calibration files have been imported. Use Import and assign first.', ...
                    'Calibration assignment','Icon','info');
                return;
            end

            % Modal editor centered on the active display.
            width = 520;
            height = 420;
            dialog = uifigure('Name',char(group.Name + " — Calibration assignment"), ...
                'Position',[0 0 width height],'WindowStyle','modal','Resize','on');
            oops.app.centerDialog(dialog);

            % Simple tree-and-buttons layout leaves room for longer source paths.
            grid = uigridlayout(dialog,[2 1], ...
                'RowHeight',{'1x','fit'},'ColumnWidth',{'1x'},'Padding',10,'RowSpacing',10);
            tree = uitree(grid,'checkbox');
            tree.Layout.Row = 1;
            tree.Tooltip = 'Check every imported calibration stack to average for this group.';

            % One checkable registry node per reusable calibration input.
            nodes = matlab.ui.container.TreeNode.empty(0,1);

            for k = 1:numel(obj.Project.Calibrations)
                calibration = obj.Project.Calibrations(k);
                path = obj.calibrationPath(calibration);

                if path == ""
                    label = calibration.Name + " — in-memory";
                else
                    label = path;
                end

                nodes(k,1) = uitreenode(tree, ...
                    'Text',char(label), ...
                    'NodeData',calibration.ID); %#ok<AGROW>
            end

            % Nodes matching the group's current assignment, if any.
            checked = nodes(ismember(oops.model.internal.ids(obj.Project.Calibrations),group.CalibrationIDs));

            if isempty(checked)
                tree.CheckedNodes = [];
            else
                tree.CheckedNodes = checked(:)';
            end

            % Right-aligned confirmation controls for the modal assignment editor.
            buttons = uigridlayout(grid,[1 3], ...
                'ColumnWidth',{'1x','fit','fit'},'RowHeight',{'fit'},'Padding',0,'ColumnSpacing',8);
            buttons.Layout.Row = 2;
            cancel = uibutton(buttons,'Text','Cancel','ButtonPushedFcn',@(~,~) delete(dialog));
            cancel.Layout.Column = 2;
            assign = uibutton(buttons,'Text','Assign','ButtonPushedFcn', ...
                @(~,~) obj.runCallback(@() obj.commitRegisteredCalibrations(dialog,tree,groupID)));
            assign.Layout.Column = 3;
        end

        function commitRegisteredCalibrations(obj,dialog,tree,groupID)
        %COMMITREGISTEREDCALIBRATIONS Apply checked registry IDs from the modal editor.

            % Checked calibration IDs captured before closing their owning dialog.
            nodes = tree.CheckedNodes;
            ids = strings(numel(nodes),1);

            for k = 1:numel(nodes)
                ids(k) = string(nodes(k).NodeData);
            end

            delete(dialog);
            obj.applyCalibrationAssignment(groupID,ids);
        end

        function applyCalibrationAssignment(obj,groupID,ids)
        %APPLYCALIBRATIONASSIGNMENT Assign registry entries to one context-clicked group.

            % Context-clicked group resolved independently of active tree selection.
            group = oops.model.internal.resolve(obj.Project.Groups,groupID);

            if isempty(group)
                error('oops:app:UnknownGroup','The selected group no longer exists.');
            end

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog("Applying calibration assignment..."); %#ok<ASGLU>
            obj.Processing = true;

            % Cleanup guard restores UI state if validation or correction fails.
            cleaner = onCleanup(@() obj.endProcessing());
            oops.analysis.Analyzer.assignCalibrations(obj.Project,group,ids,Progress=progress);
            oops.runtime.updateProgress(progress,"Updating viewers...",[]);
            obj.Processing = false;
            obj.refreshNavigation();
            obj.refreshSummary();
            obj.refreshViewers(true);
            obj.warnCalibrationState();
        end

        function path = calibrationPath(~,calibration)
        %CALIBRATIONPATH Return a registered source path when one exists.

            path = "";
            source = calibration.Input.Source;

            if calibration.Input.IsFileBacked && isprop(source,'FilePath')
                path = string(source.FilePath);
            end
        end

        function onCalibrationChanged(obj,e)
        %ONCALIBRATIONCHANGED Automatically correct images for externally edited assignments.

            if obj.Processing
                return;
            end

            % Active/target group supplying its owned images and bookmarks.
            group = oops.model.internal.resolve(obj.Project.Groups,e.GroupID);

            if isempty(group)
                return;
            end

            obj.Processing = true;

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() obj.endProcessing());

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog("Performing flat-field correction..."); %#ok<ASGLU>
            oops.analysis.Analyzer.correctGroup(group,Progress=progress);
            oops.runtime.updateProgress(progress,"Updating viewers...",[]);
            obj.Processing = false;
            obj.refreshNavigation();
            obj.refreshViewers(true);
        end

        function onImagesAdded(obj,e)
        %ONIMAGESADDED Initialize a newly attached batch and refresh once.

            if obj.Processing
                return;
            end

            % Active/target group supplying its owned images and bookmarks.
            group = oops.model.internal.resolve(obj.Project.Groups,e.GroupID);

            if isempty(group)
                return;
            end

            images = oops.model.Image.empty(0,1);

            for imageID = reshape(e.ImageIDs,1,[])
                image = oops.model.internal.resolve(group.Images,imageID);

                if ~isempty(image)
                    images(end+1,1) = image; %#ok<AGROW>
                end
            end

            if isempty(images)
                return;
            end

            obj.Processing = true;
            cleaner = onCleanup(@() obj.endProcessing());
            obj.reconcileActive();
            [progress,cleanupProgress] = obj.createProgressDialog( ...
                "Initializing added images..."); %#ok<ASGLU>
            oops.analysis.Analyzer.correctImages(images,Progress=progress);
        end

        function images = analysisTargets(obj)
        %ANALYSISTARGETS Prefer checked images, then all images of checked groups, then active.

            % Images accumulated from checked images/groups, falling back to the active image.
            images = oops.model.Image.empty(0,1);

            % Project whose hierarchy supplies the navigation/operation targets.
            p = obj.Project;

            % Collect checked images across every project group.
            for k = 1:numel(p.Groups)

                % Active/target group supplying its owned images and bookmarks.
                group = p.Groups(k);

                % Model IDs represented by the current operation or navigation control.
                ids = group.SelectedImageIDs;
                images = [images;group.Images(ismember(oops.model.internal.ids(group.Images),ids))]; %#ok<AGROW>
            end

            if isempty(images)

                % Use images from checked groups when no images were checked individually.
                for k = 1:numel(p.Groups)
                    group = p.Groups(k);

                    if ismember(group.ID,p.SelectedGroupIDs)
                        images = [images;group.Images]; %#ok<AGROW>
                    end

                end

            end

            if isempty(images)
                images = p.ActiveImage;
            end

        end

        function runAnalysis(obj,stage)
        %RUNANALYSIS Run selected processing stages for the current model targets.

            % Resolved image targets for the requested batch pipeline stage.
            images = obj.analysisTargets();

            if isempty(images)
                oops.Log.WARN("No images available for analysis.");
                return;
            end

            switch stage
                case "All"
                    message = "Running all processing steps...";
                    stages = ["Polarization","ObjectDetection"];
                    skipCurrentPolarization = true;
                case "ObjectDetection"
                    message = "Detecting objects...";
                    stages = "ObjectDetection";
                    skipCurrentPolarization = false;
                case "Polarization"
                    message = "Calculating polarization results...";
                    stages = "Polarization";
                    skipCurrentPolarization = false;
                otherwise
                    error('oops:app:UnknownProcessingStage', ...
                        'Unknown processing command: %s',stage);
            end

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog(message); %#ok<ASGLU>

            obj.Processing = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.endProcessing());

            oops.analysis.Analyzer.processImages( ...
                images,obj.Settings,stages,Progress=progress, ...
                SkipCurrentPolarization=skipCurrentPolarization);

            oops.runtime.updateProgress(progress,"Updating viewers...",[]);
            obj.Processing = false;
            obj.reconcileActive();
            obj.refreshNavigation();
            obj.refreshViewers(true);
        end

        function [progress,cleanupProgress] = createProgressDialog(obj,message)
        %CREATEPROGRESSDIALOG Own one operation's dialog with exception-safe cleanup.
        % Hidden GUIs keep programmatic/test operations free of modal dialogs.

            % Optional dialog handle, left empty for hidden/programmatic GUI operations.
            progress = [];

            if ~isempty(obj.Fig) && isvalid(obj.Fig) && strcmp(obj.Fig.Visible,'on')
                progress = uiprogressdlg(obj.Fig, ...
                    'Title','OOPS','Message',message,'Indeterminate','on');
            end

            % The caller retains this guard until analysis and display updates
            % finish. A closed/deleted dialog is harmless during cleanup.

            % Cleanup guard that closes the dialog when the operation scope ends.
            cleanupProgress = onCleanup(@() closeProgressDialog(progress));
        end

        function focusWindow(obj)
        %FOCUSWINDOW Return focus after a native dialog without showing hidden GUIs.

            if ~obj.Closing && ~isempty(obj.Fig) && isvalid(obj.Fig) && strcmp(obj.Fig.Visible,'on')
                figure(obj.Fig);
                drawnow;
            end

        end

        function endProcessing(obj)
        %ENDPROCESSING Release the processing guard even when an operation throws.

            obj.Processing = false;
            try
                obj.refreshNavigation();
                obj.refreshColormapControls();
                obj.refreshViewers(false);
            catch ME
                oops.Log.EXCEPTION(ME); % cleanup must preserve the original exception
            end
        end

        function manageCollection(obj,kind)
        %MANAGECOLLECTION Open a shared flat-tree editor for model registries.

            actions = struct();

            switch kind
                case "Groups"
                    itemsFcn = @() obj.collectionItems("Groups");
                    actions.New = @(~,~) obj.promptGroup();
                    actions.Edit = @(id,~) obj.promptGroup(id);
                    actions.Delete = @(id,parent) obj.deleteManagedGroup(id,parent);
                    actions.Move = @(id,offset,~) obj.Project.moveGroup(id,offset);
                    hint = "Checked groups are reserved for future batch actions.";

                case "Labels"
                    itemsFcn = @() obj.collectionItems("Labels");
                    actions.New = @(~,~) obj.promptLabel();
                    actions.Edit = @(id,~) obj.promptLabel(id);
                    actions.Delete = @(id,parent) obj.deleteLabel(id,parent);
                    actions.Move = @(id,offset,~) obj.Project.Labels.move(id,offset);
                    hint = "Checked labels are reserved for future merge and batch actions.";

                case "Channels"
                    itemsFcn = @() obj.collectionItems("Channels");
                    actions.New = @(~,~) obj.promptChannel();
                    actions.Edit = @(id,~) obj.promptChannel(id);
                    actions.Delete = @(id,parent) obj.deleteChannel(id,parent);
                    actions.Move = @(id,offset,~) obj.moveChannel(id,offset);
                    hint = "Checked channels are reserved for future batch actions.";
            end

            oops.app.collectionManagerDialog( ...
                obj.Fig,"Edit "+lower(kind),itemsFcn,actions,Hint=hint);
            obj.focusWindow();
        end

        function items = collectionItems(obj,kind)
        %COLLECTIONITEMS Describe ordered manager nodes without exposing handles.

            items = repmat(struct('ID',"",'Name',"",'Color',[1 1 1], ...
                'Protected',false),0,1);

            switch kind
                case "Groups"
                    values = obj.Project.Groups;
                case "Labels"
                    values = obj.Project.Labels.labels();
                case "Channels"
                    values = obj.Project.Channels.Channels;
            end

            for k = 1:numel(values)
                name = values(k).Name;

                if kind == "Labels" && values(k).Hotkey ~= ""
                    name = name + "  [" + values(k).Hotkey + "]";
                end

                items(k,1) = struct( ...
                    'ID',values(k).ID,'Name',name,'Color',values(k).Color, ...
                    'Protected',kind == "Labels" && values(k).ID == "unlabeled"); %#ok<AGROW>
            end
        end

        function deleteManagedGroup(obj,id,parent)
        %DELETEMANAGEDGROUP Confirm the complete hierarchy removed with a group.

            if nargin < 3
                parent = obj.Fig;
            end

            group = oops.model.internal.resolve(obj.Project.Groups,id);

            if isempty(group)
                return;
            end

            objectCount = sum(arrayfun(@(image) numel(image.Objects),group.Images));
            message = sprintf('Delete "%s" with %d images and %d objects?', ...
                group.Name,numel(group.Images),objectCount);
            answer = uiconfirm(parent,message,'Delete group?', ...
                'Options',{'Delete','Cancel'},'DefaultOption','Cancel', ...
                'CancelOption','Cancel','Icon','warning');

            if strcmp(answer,'Delete')
                obj.deleteNavigation("Groups",id);
            end
        end

        function promptChannel(obj,channelID)
        %PROMPTCHANNEL Create or edit a semantic channel definition.

            if nargin < 2
                channelID = "";
            end

            if channelID == ""
                title = "New channel";
                channel = oops.model.ChannelDefinition.empty(0,1);
                number = numel(obj.Project.Channels.Channels)+1;
                name = "Channel "+number;
                colors = get(groot,'defaultAxesColorOrder');
                color = colors(mod(number-1,size(colors,1))+1,:);
            else
                title = "Edit channel";
                channel = obj.Project.Channels.findByID(channelID);

                if isempty(channel)
                    error('oops:app:UnknownChannel', ...
                        'The selected channel no longer exists.');
                end

                name = channel.Name;
                color = channel.Color;
            end

            params = matlabx.app.ParamsDialog.prompt(title, ...
                {'Name','Name','string',name, ...
                    @(value) obj.channelNameAvailable(value,channelID), ...
                    'Name must be nonempty and unique.'}, ...
                {'Color','Color','color',color});

            if isempty(params)
                return;
            end

            if isempty(channel)
                obj.Project.Channels.add(strtrim(string(params.Name)),params.Color);
            else
                obj.Project.Channels.edit(channelID, ...
                    strtrim(string(params.Name)),params.Color);
            end

            obj.refreshChannelsAfterEdit();
        end

        function available = channelNameAvailable(obj,name,ownerID)
        %CHANNELNAMEAVAILABLE Validate a trimmed channel name for parameter dialogs.

            name = strtrim(string(name));
            channels = obj.Project.Channels.Channels;
            ids = string({channels.ID});
            names = string({channels.Name});
            available = name ~= "" && ...
                ~any(strcmpi(name,names(ids ~= string(ownerID))));
        end

        function deleteChannel(obj,id,parent)
        %DELETECHANNEL Remove an unused semantic channel definition.

            if nargin < 3
                parent = obj.Fig;
            end

            channel = obj.Project.Channels.findByID(id);

            if isempty(channel)
                return;
            end

            [primaryReferences,auxiliaryReferences] = obj.channelReferenceCounts(id);

            if primaryReferences > 0
                uialert(parent,sprintf( ...
                    'This channel is the primary channel for %d images and cannot be deleted.', ...
                    primaryReferences), ...
                    'Channel is in use','Icon','warning');
                return;
            end

            message = "Delete channel """+channel.Name+"""?";

            if auxiliaryReferences > 0
                message = message+newline+sprintf( ...
                    'Its assignments will be removed from %d images.',auxiliaryReferences);
            end

            answer = uiconfirm(parent,message, ...
                'Delete channel?','Options',{'Delete','Cancel'}, ...
                'DefaultOption','Cancel','CancelOption','Cancel','Icon','warning');

            if strcmp(answer,'Delete')
                previous = obj.Processing;
                obj.Processing = true;
                guard = onCleanup(@() obj.restoreProcessing(previous));

                for group = reshape(obj.Project.Groups,1,[])
                    for image = reshape(group.Images,1,[])
                        image.removeAuxiliaryChannel(id);
                    end
                end

                obj.Project.Channels.remove(id);
                clear guard;
                obj.refreshChannelsAfterEdit();
            end
        end

        function [primary,auxiliary] = channelReferenceCounts(obj,id)
        %CHANNELREFERENCECOUNTS Count primary and auxiliary image assignments.

            primary = 0;
            auxiliary = 0;

            for group = reshape(obj.Project.Groups,1,[])
                for image = reshape(group.Images,1,[])
                    primary = primary+double(image.PrimaryChannelID == id);
                    auxiliary = auxiliary+double( ...
                        any(string({image.AuxiliaryChannels.ChannelID}) == id));
                end
            end
        end

        function moveChannel(obj,id,offset)
        %MOVECHANNEL Reorder channels and refresh channel-dependent displays.

            obj.Project.Channels.move(id,offset);
            obj.refreshChannelsAfterEdit();
        end

        function refreshChannelsAfterEdit(obj)
        %REFRESHCHANNELSAFTEREDIT Reconcile controls and visible channel sources.

            obj.refreshColormapControls();
            obj.refreshMeasurementControls();
            obj.ViewerKeys(:) = "";
            obj.refreshViewers(true);
        end

        function refreshMeasurementControls(obj)
        %REFRESHMEASUREMENTCONTROLS Rebuild plot variables from channel identities.

            if isempty(obj.Project) || ~isfield(obj.SettingsUI,'ScatterPlot') || ...
                    ~isfield(obj.SettingsUI,'SwarmPlot')
                return;
            end

            names = oops.model.ObjectMeasurements.plottableNames(obj.Project);
            labels = oops.model.ObjectMeasurements.labels(names,obj.Project);
            bindings = {obj.SettingsUI.ScatterPlot.XVariable,'ScatterPlot','XVariable'; ...
                obj.SettingsUI.ScatterPlot.YVariable,'ScatterPlot','YVariable'; ...
                obj.SettingsUI.SwarmPlot.YVariable,'SwarmPlot','YVariable'};

            for k = 1:size(bindings,1)
                control = bindings{k,1};
                domain = bindings{k,2};
                property = bindings{k,3};
                value = obj.Settings.(domain).(property);

                if ~ismember(value,names)
                    value = names(1);
                    obj.Settings.(domain).(property) = value;
                end

                set(control,'Items',cellstr(labels), ...
                    'ItemsData',cellstr(names),'Value',char(value));
            end
        end

        function promptGroup(obj,groupID)
        %PROMPTGROUP Create or edit a group's name and identifying color.

            if nargin < 2
                groupID = "";
            end

            if groupID == ""
                title = "New group";
                name = "Group " + (numel(obj.Project.Groups)+1);
                color = obj.Project.NextGroupColor;
                group = oops.model.Group.empty(0,1);
            else
                group = oops.model.internal.resolve(obj.Project.Groups,groupID);

                if isempty(group)
                    error('oops:app:UnknownGroup','The selected group no longer exists.');
                end

                title = "Edit group";
                name = group.Name;
                color = group.Color;
            end

            % Shared MATLABX form used for both creation and later editing.
            params = matlabx.app.ParamsDialog.prompt(title, ...
                {'Name','Name','string',name, ...
                    @(value) strlength(strtrim(value)) > 0,'Group name cannot be empty.'}, ...
                {'Color','Color','color',color});
            obj.focusWindow();

            if isempty(params)
                return;
            end

            if isempty(group)
                obj.addGroup(strtrim(string(params.Name)),params.Color);
            else
                group.setProperties(strtrim(string(params.Name)),params.Color);
            end

        end

        function promptLabel(obj,labelID)
        %PROMPTLABEL Create or edit label identity, shortcut, and display color.

            if nargin < 2
                labelID = "";
            end

            if labelID == ""
                title = "New label";
                label = oops.model.ObjectLabel.empty(0,1);

                % Numbered defaults remain readable while uniqueness checks handle gaps.
                number = max(1,numel(obj.Project.Labels.labels()));
                name = "Label " + number;
                id = "label-" + number;

                while ~obj.labelIDAvailable(id,"") || ~obj.labelNameAvailable(name,"")
                    number = number+1;
                    name = "Label " + number;
                    id = "label-" + number;
                end

                hotkey = obj.nextLabelHotkey();

                % MATLAB's axes color order provides simple, predictable defaults.
                colors = get(groot,'defaultAxesColorOrder');
                userLabelCount = max(0,numel(obj.Project.Labels.labels())-1);
                colorIndex = mod(userLabelCount,size(colors,1))+1;
                color = colors(colorIndex,:);
            else
                title = "Edit label";
                label = obj.Project.Labels.getByID(labelID);

                if isempty(label)
                    error('oops:app:UnknownLabel','The selected label no longer exists.');
                end

                name = label.Name;
                id = label.ID;
                hotkey = label.Hotkey;
                color = label.Color;
            end

            % The registry repeats these checks so programmatic calls remain safe.
            params = matlabx.app.ParamsDialog.prompt(title, ...
                {'Name','Name','string',name, ...
                    @(value) obj.labelNameAvailable(value,labelID), ...
                    'Name must be nonempty and unique.'}, ...
                {'ID','ID','string',id, ...
                    @(value) obj.labelIDAvailable(value,labelID), ...
                    'ID must be nonempty and unique.'}, ...
                {'Hotkey','Hotkey','string',hotkey, ...
                    @(value) obj.labelHotkeyAvailable(value,labelID), ...
                    'Hotkey must be one unique alphanumeric character.'}, ...
                {'Color','Color','color',color});
            obj.focusWindow();

            if isempty(params)
                return;
            end

            if isempty(label)
                obj.Project.addLabel(strtrim(string(params.Name)), ...
                    ID=strtrim(string(params.ID)), ...
                    Hotkey=lower(strtrim(string(params.Hotkey))), ...
                    Color=params.Color);
            else
                obj.Project.editLabel(labelID, ...
                    Name=strtrim(string(params.Name)), ...
                    ID=strtrim(string(params.ID)), ...
                    Hotkey=lower(strtrim(string(params.Hotkey))), ...
                    Color=params.Color);
            end
        end

        function deleteLabel(obj,labelID,parent)
        %DELETELABEL Confirm removal and return affected objects to Unlabeled.

            if nargin < 3
                parent = obj.Fig;
            end

            label = obj.Project.Labels.getByID(labelID);

            if isempty(label)
                error('oops:app:UnknownLabel','The selected label no longer exists.');
            end

            answer = uiconfirm(parent, ...
                "Objects using this label will be reassigned to Unlabeled.", ...
                "Delete " + label.Name + "?", ...
                'Options',{'Delete','Cancel'},'DefaultOption','Cancel', ...
                'CancelOption','Cancel','Icon','warning');

            if strcmp(answer,'Delete')
                obj.Project.removeLabel(labelID);
            end
        end

        function mergeSelectedLabels(obj)
        %MERGESELECTEDLABELS Replace checked user labels with one new label.

            nodes = obj.LabelsTree.CheckedNodes;
            ids = string({nodes.NodeData});
            ids(ids == "unlabeled") = [];

            if numel(ids) < 2
                return;
            end

            number = numel(obj.Project.Labels.labels());
            name = "Merged label " + number;
            id = "merged-label-" + number;

            while ~obj.labelIDAvailable(id,"") || ~obj.labelNameAvailable(name,"")
                number = number+1;
                name = "Merged label " + number;
                id = "merged-label-" + number;
            end

            colors = zeros(numel(ids),3);

            for k = 1:numel(ids)
                colors(k,:) = obj.Project.Labels.getByID(ids(k)).Color;
            end

            params = matlabx.app.ParamsDialog.prompt('Merge selected labels', ...
                {'Name','Name','string',name, ...
                    @(value) obj.labelNameAvailable(value,""), ...
                    'Name must be nonempty and unique.'}, ...
                {'ID','ID','string',id, ...
                    @(value) obj.labelIDAvailable(value,""), ...
                    'ID must be nonempty and unique.'}, ...
                {'Hotkey','Hotkey','string',obj.nextLabelHotkey(), ...
                    @(value) obj.labelHotkeyAvailable(value,""), ...
                    'Hotkey must be one unique alphanumeric character.'}, ...
                {'Color','Color','color',mean(colors,1)});
            obj.focusWindow();

            if isempty(params)
                return;
            end

            obj.Project.mergeLabels(ids,strtrim(string(params.Name)), ...
                ID=strtrim(string(params.ID)), ...
                Hotkey=lower(strtrim(string(params.Hotkey))), ...
                Color=params.Color);
        end

        function selectObjectsWithLabel(obj,labelID)
        %SELECTOBJECTSWITHLABEL Add every matching object to its image selection.

            images = obj.projectImages();
            selections = cell(numel(images),1);

            for k = 1:numel(images)
                image = images(k);
                matches = image.Objects([image.Objects.LabelID] == labelID);
                selections{k} = unique([image.SelectedObjectIDs; ...
                    oops.model.internal.ids(matches)],'stable');
            end

            obj.runObjectBatch( ...
                @() obj.setObjectSelectionsByImage(images,selections),"Selection");
        end

        function applyLabelToSelection(obj,labelID)
        %APPLYLABELTOSELECTION Apply one label across all remembered selections.

            images = obj.projectImages();
            ids = arrayfun(@(image) image.SelectedObjectIDs,images, ...
                'UniformOutput',false);
            obj.runObjectBatch( ...
                @() obj.setObjectLabelsByImage(images,ids,labelID),"Labels");
        end

        function deleteObjectsWithLabel(obj,labelID)
        %DELETEOBJECTSWITHLABEL Delete every project object using one label.

            images = obj.projectImages();
            ids = cell(numel(images),1);

            for k = 1:numel(images)
                matches = images(k).Objects([images(k).Objects.LabelID] == labelID);
                ids{k} = oops.model.internal.ids(matches);
            end

            obj.runObjectBatch( ...
                @() obj.removeObjectsByImage(images,ids),"Objects");
        end

        function applyObjectSelectionAction(obj,action,scope)
        %APPLYOBJECTSELECTIONACTION Mutate selections within one model scope.

            images = obj.objectScopeImages(scope);
            ids = cell(numel(images),1);

            for k = 1:numel(images)
                image = images(k);
                allIDs = oops.model.internal.ids(image.Objects);

                switch action
                    case "Select"
                        ids{k} = allIDs;
                    case "Clear"
                        ids{k} = strings(0,1);
                    case "Invert"
                        ids{k} = allIDs( ...
                            ~ismember(allIDs,image.SelectedObjectIDs));
                    case "Delete"
                        ids{k} = image.SelectedObjectIDs;
                end
            end

            if action == "Delete"
                obj.runObjectBatch( ...
                    @() obj.removeObjectsByImage(images,ids),"Objects");
            else
                obj.runObjectBatch( ...
                    @() obj.setObjectSelectionsByImage(images,ids),"Selection");
            end
        end

        function selectByProperty(obj)
        %SELECTBYPROPERTY Add objects matching an AND filter set to selection.

            filters = oops.app.objectFilterDialog(obj.Fig,obj.Project);
            obj.focusWindow();

            if isempty(filters)
                return;
            end

            [images,ids,count] = obj.objectsMatchingFilters(filters);
            added = 0;
            selections = cell(numel(images),1);

            for k = 1:numel(images)
                old = images(k).SelectedObjectIDs;
                selections{k} = unique([old;ids{k}],'stable');
                added = added + numel(selections{k})-numel(old);
            end

            obj.runObjectBatch( ...
                @() obj.setObjectSelectionsByImage(images,selections),"Selection");

            uialert(obj.Fig,sprintf('%d objects were added to the selection.',added), ...
                'Object selection','Icon','info');
            oops.Log.INFO(sprintf('Property filters matched %d objects; %d were newly selected.', ...
                count,added));
        end

        function labelByProperty(obj)
        %LABELBYPROPERTY Apply an existing or new label to filtered objects.

            filters = oops.app.objectFilterDialog(obj.Fig,obj.Project);
            obj.focusWindow();

            if isempty(filters)
                return;
            end

            [images,ids,count] = obj.objectsMatchingFilters(filters);

            if count == 0
                uialert(obj.Fig,'No objects matched the specified filters.', ...
                    'Label by property','Icon','info');
                return;
            end

            choice = uiconfirm(obj.Fig,'Choose how to supply the target label.', ...
                'Label matching objects','Options',{'Existing label','New label','Cancel'}, ...
                'DefaultOption','Existing label','CancelOption','Cancel');

            if strcmp(choice,'Cancel')
                return;
            elseif strcmp(choice,'New label')
                before = obj.Project.Labels.ids();
                obj.promptLabel();
                created = setdiff(obj.Project.Labels.ids(),before,'stable');

                if isempty(created)
                    return;
                end

                labelID = created(1);
            else
                labels = obj.Project.Labels.labels();
                names = [labels.Name];
                params = matlabx.app.ParamsDialog.prompt('Choose object label', ...
                    {'Label','Label','choice',names(1),cellstr(names)});
                obj.focusWindow();

                if isempty(params)
                    return;
                end

                labelID = labels(names == string(params.Label)).ID;
            end

            obj.runObjectBatch( ...
                @() obj.setObjectLabelsByImage(images,ids,labelID),"Labels");

            uialert(obj.Fig,sprintf('%d objects were labeled.',count), ...
                'Label by property','Icon','info');
        end

        function deleteByProperty(obj)
        %DELETEBYPROPERTY Confirm and delete every object matching filters.

            filters = oops.app.objectFilterDialog(obj.Fig,obj.Project);
            obj.focusWindow();

            if isempty(filters)
                return;
            end

            [images,ids,count] = obj.objectsMatchingFilters(filters);

            if count == 0
                uialert(obj.Fig,'No objects matched the specified filters.', ...
                    'Delete by property','Icon','info');
                return;
            end

            answer = uiconfirm(obj.Fig,sprintf('Delete %d matching objects?',count), ...
                'Delete by property','Options',{'Delete','Cancel'}, ...
                'DefaultOption','Cancel','CancelOption','Cancel','Icon','warning');

            if strcmp(answer,'Delete')
                obj.runObjectBatch( ...
                    @() obj.removeObjectsByImage(images,ids),"Objects");
            end
        end

        function runObjectBatch(obj,operation,kind)
        %RUNOBJECTBATCH Suppress per-image responses and refresh once by mutation kind.

            arguments
                obj
                operation (1,1) function_handle
                kind (1,1) string {mustBeMember(kind,["Selection","Labels","Objects"])}
            end

            previous = obj.Processing;
            obj.Processing = true;
            guard = onCleanup(@() obj.finishObjectBatch(previous,kind));
            operation();
        end

        function finishObjectBatch(obj,previous,kind)
        %FINISHOBJECTBATCH Restore callbacks and apply the deferred UI response.

            if kind == "Objects"
                try
                    obj.reconcileActive();
                    names = [obj.Settings.View.LeftSource,obj.Settings.View.RightSource];
                    obj.ViewerKeys(names == "Mask") = "";
                    obj.ObjectViewerKey = "";
                catch ME
                    oops.Log.EXCEPTION(ME);
                end
            end

            obj.Processing = previous;

            if previous
                return;
            end

            try
                switch kind
                    case "Selection"
                        obj.refreshNavigation();
                        obj.syncOverlayState();
                    case "Labels"
                        obj.refreshSummary();

                        if any(ismember([obj.Settings.View.LeftSource, ...
                                obj.Settings.View.RightSource], ...
                                ["Scatterplot","Swarmplot","PolarHistogram"]))
                            obj.refreshPlots();
                        end

                        obj.refreshOverlayAppearance();

                        if obj.Settings.View.RightSource == "Objects"
                            obj.refreshObjectViewerOverlays();
                        end
                    case "Objects"
                        obj.refreshSummary();
                        obj.refreshNavigation();

                        if any(ismember([obj.Settings.View.LeftSource, ...
                                obj.Settings.View.RightSource], ...
                                ["Scatterplot","Swarmplot","PolarHistogram"]))
                            obj.refreshPlots();
                        end

                        obj.refreshViewers(false,false);
                end
            catch ME
                oops.Log.EXCEPTION(ME);
            end
        end

        function setObjectSelectionsByImage(~,images,ids)
        %SETOBJECTSELECTIONSBYIMAGE Apply one prepared selection per image.

            for k = 1:numel(images)
                images(k).setSelectedObjects(ids{k});
            end
        end

        function setObjectLabelsByImage(~,images,ids,labelID)
        %SETOBJECTLABELSBYIMAGE Apply one label to prepared memberships by image.

            for k = 1:numel(images)
                images(k).setObjectLabels(ids{k},labelID);
            end
        end

        function removeObjectsByImage(~,images,ids)
        %REMOVEOBJECTSBYIMAGE Remove prepared object memberships from each image.

            for k = 1:numel(images)
                images(k).removeObjects(ids{k});
            end
        end

        function [images,ids,count] = objectsMatchingFilters(obj,filters)
        %OBJECTSMATCHINGFILTERS Group matching object IDs by parent image.

            images = obj.projectImages();
            ids = cell(numel(images),1);
            count = 0;

            for k = 1:numel(images)
                objects = images(k).Objects;
                keep = true(numel(objects),1);

                for j = 1:numel(filters)
                    values = obj.objectValues(objects,filters(j).Property);

                    switch filters(j).Operator
                        case ">",  match = values > filters(j).Value;
                        case ">=", match = values >= filters(j).Value;
                        case "==", match = values == filters(j).Value;
                        case "~=", match = values ~= filters(j).Value;
                        case "<=", match = values <= filters(j).Value;
                        case "<",  match = values < filters(j).Value;
                    end

                    keep = keep & match;
                end

                ids{k} = oops.model.internal.ids(objects(keep));
                count = count + numel(ids{k});
            end
        end

        function images = objectScopeImages(obj,scope)
        %OBJECTSCOPEIMAGES Resolve project, group, or image command scope.

            switch scope
                case "Project"
                    images = obj.projectImages();
                case "Group"
                    group = obj.Project.ActiveGroup;
                    if isempty(group), images = oops.model.Image.empty(0,1); else, images = group.Images; end
                case "Image"
                    images = obj.Project.ActiveImage;
            end
        end

        function images = projectImages(obj)
        %PROJECTIMAGES Flatten project images without changing hierarchy order.

            images = oops.model.Image.empty(0,1);

            for group = reshape(obj.Project.Groups,1,[])
                images = [images;group.Images(:)]; %#ok<AGROW>
            end
        end

        function tf = labelNameAvailable(obj,value,ownerID)
        %LABELNAMEAVAILABLE Validate a visible name against every other label.

            value = lower(strtrim(string(value)));
            labels = obj.Project.Labels.labels();
            tf = strlength(value) > 0;

            for k = 1:numel(labels)

                if lower(labels(k).ID) ~= lower(ownerID) && ...
                        lower(strtrim(labels(k).Name)) == value
                    tf = false;
                    return;
                end

            end
        end

        function tf = labelIDAvailable(obj,value,ownerID)
        %LABELIDAVAILABLE Validate a stable ID, preserving the fallback identity.

            value = lower(strtrim(string(value)));
            ownerID = lower(string(ownerID));
            ids = lower(obj.Project.Labels.ids());
            tf = strlength(value) > 0 && ~any(ids(ids ~= ownerID) == value);

            if ownerID == "unlabeled"
                tf = tf && value == "unlabeled";
            end
        end

        function tf = labelHotkeyAvailable(obj,value,ownerID)
        %LABELHOTKEYAVAILABLE Require one unused alphanumeric shortcut.

            value = lower(strtrim(string(value)));
            labels = obj.Project.Labels.labels();
            tf = strlength(value) == 1 && isstrprop(char(value),'alphanum');

            for k = 1:numel(labels)

                if lower(labels(k).ID) ~= lower(ownerID) && labels(k).Hotkey == value
                    tf = false;
                    return;
                end

            end
        end

        function key = nextLabelHotkey(obj)
        %NEXTLABELHOTKEY Choose the first unused digit or letter for a new label.

            candidates = [string(1:9),string(char('a':'z')')'];
            used = lower(obj.Project.Labels.hotkeys());
            available = candidates(~ismember(candidates,used));

            if isempty(available)
                key = "";
            else
                key = available(1);
            end
        end

        function chooseFiles(obj)
        %CHOOSEFILES Delegate image reading to the programmatic import entry point.

            % Selected input filenames and directory, or zero filenames on cancellation.
            [files,folder] = matlabx.image.io.uigetimagefile([], ...
                'Select four-angle inputs',char(obj.Settings.IO.DefaultFolder),MultiSelect='on');
            % Native file dialogs can leave MATLAB behind other windows. Raise
            % this figure on return, including cancellation, and after loading.
            obj.focusWindow();

            % Cleanup guard returning focus to the visible GUI after loading completes.
            cleanupFocus = onCleanup(@() obj.focusWindow()); %#ok<NASGU>

            if isequal(files,0)
                return;
            end

            obj.Settings.IO.DefaultFolder = string(folder);
            obj.addFiles(fullfile(folder,string(files)));
        end

        function loadSettings(obj)
        %LOADSETTINGS Apply saved defaults to the existing root, retaining subscriptions.

            % Settings tree loaded temporarily before copying values into the existing root.
            loaded = oops.config.Settings.load();

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() delete(loaded));
            obj.Settings.fromStruct(loaded.toStruct());
        end

        function runCallback(obj,callback)
        %RUNCALLBACK Catch UI-boundary errors and forward their exception to the facade.

            if obj.Closing
                return;
            end

            try
                callback();
            catch ME
                oops.Log.EXCEPTION(ME);

                if ~isempty(obj.Fig) && isvalid(obj.Fig) && strcmp(obj.Fig.Visible,'on')
                    uialert(obj.Fig,ME.message,'OOPS');
                end

            end
        end

        function endRefresh(obj)
        %ENDREFRESH Release the navigation guard even after a callback fails.

            obj.Refreshing = false;
        end

        function endResize(obj)
        %ENDRESIZE Release the resize guard even after a layout error.

            obj.Resizing = false;
        end

        function endViewerDisplaySync(obj)
        %ENDVIEWERDISPLAYSYNC Re-enable persistence after programmatic viewer updates.

            obj.SyncingViewerDisplay = false;
        end

    end
end

function lines = runtimeStatusLines(status)
%RUNTIMESTATUSLINES Format cache diagnostics without rich table markup.

cache = status.Cache;
lines = [ ...
    "CACHE BUDGETS AND OCCUPANCY"
    cacheLine("Raw input",cache.RawInputMiB,cache.RawInputLimitMiB)
    cacheLine("Corrected stacks",cache.CorrectedStackMiB,cache.CorrectedStackLimitMiB)
    sprintf('Pinned object-view corrected stack: %.3f MiB', ...
        cache.PinnedCorrectedStackMiB)
    cacheLine("Normalized calibrations",cache.CalibrationMiB,cache.CalibrationLimitMiB)
    cacheLine("Auxiliary sources",0,cache.AuxiliaryLimitMiB)
    ""
    "IMAGE RESIDENCY"];

images = status.Images;

if isempty(images)
    lines(end+1,1) = "No images.";
else

    for k = 1:height(images)
        lines(end+1,1) = ""; %#ok<AGROW>
        lines(end+1,1) = "[" + images.Group(k) + "] " + images.Image(k); %#ok<AGROW>
        lines(end+1,1) = sprintf( ...
            '  Disposable: raw loaded=%s (%.3f MiB); corrected cached=%s (%.3f MiB)', ...
            yesNo(images.RawLoaded(k)),images.RawMiB(k), ...
            yesNo(images.CorrectedCached(k)),images.CorrectedMiB(k)); %#ok<AGROW>
        lines(end+1,1) = sprintf( ...
            ['  Model outputs: average=%.3f; enhanced=%.3f; mask=%.3f; ' ...
            'order=%.3f; azimuth=%.3f MiB'], ...
            images.AverageMiB(k),images.EnhancedMiB(k),images.MaskMiB(k), ...
            images.OrderMiB(k),images.AzimuthMiB(k)); %#ok<AGROW>
        lines(end+1,1) = sprintf( ...
            '  Auxiliary: %d loaded source(s), %.3f MiB; total resident=%.3f MiB', ...
            images.AuxiliarySourcesLoaded(k),images.AuxiliaryMiB(k), ...
            images.TotalMiB(k)); %#ok<AGROW>
    end
end

lines(end+1:end+2,1) = ["";"NORMALIZED CALIBRATIONS"];
calibrations = status.Calibrations;

if isempty(calibrations)
    lines(end+1,1) = "No normalized calibration responses are cached.";
else

    for k = 1:height(calibrations)
        lines(end+1,1) = sprintf('  %.3f MiB  %s', ...
            calibrations.MiB(k),calibrations.Key(k)); %#ok<AGROW>
    end
end
end

function line = cacheLine(name,used,limit)
%CACHELINE Format one current-occupancy and configured-limit pair.

if isinf(limit)
    limitText = "unlimited";
else
    limitText = sprintf('%.3f MiB',limit);
end

line = sprintf('  %-24s %9.3f MiB / %s',name,used,limitText);
end

function value = yesNo(tf)
%YESNO Format one scalar logical for compact diagnostic text.

if tf
    value = 'yes';
else
    value = 'no';
end
end

function logDebugElapsed(operation,started)
%LOGDEBUGELAPSED Report completion time from an exception-safe cleanup.

oops.Log.DEBUG(sprintf('%s in %.3f s.',operation,toc(started)));
end

function plan = defaultPrimaryChannelPlan(inputs,imageNames,registry)
%DEFAULTPRIMARYCHANNELPLAN Map hidden/programmatic imports without UI prompts.

plan = repmat(struct( ...
    'Input',matlabx.image.Image5D.empty(0,1), ...
    'ImageName',"",'ChannelName',"",'ChannelColor',[0 0 0]), ...
    numel(inputs),1);

for k = 1:numel(inputs)
    locations = oops.io.fourAngleLocations(inputs(k));
    component = inputs(k).getComponent(locations(1,1));
    name = strtrim(string(component.Name));

    if name == ""
        name = "Primary channel";
    end

    definition = registry.findByName(name);

    if isempty(definition)
        colorName = oops.render.canonicalComponentColor(component.Color);

        if colorName == ""
            colorName = "gray";
        end

        [~,color] = matlabx.image.normalizeComponentColor(colorName);
    else
        name = definition.Name;
        color = definition.Color;
    end

    plan(k) = struct( ...
        'Input',inputs(k), ...
        'ImageName',imageNames(k), ...
        'ChannelName',name, ...
        'ChannelColor',color);
end
end

function closeProgressDialog(progress)
%CLOSEPROGRESSDIALOG Release a dialog without masking an operation's exception.

    if ~isempty(progress) && isvalid(progress)
        close(progress);
    end

end
