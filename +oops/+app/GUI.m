% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef GUI < handle
%GUI First OOPS controller: navigation, settings, two viewers, and session logging.
% The model owns ID state; this controller interprets it and owns all graphics.

    properties (SetAccess=private)
        Project (:,1) oops.model.Project = oops.model.Project.empty(0,1)
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
        OrientationFields cell = {}
        OrientationFieldTools cell = {}
        ScatterRenderer matlabx.ui.axes.plot.ScatterRenderer
        SwarmRenderer matlabx.ui.axes.plot.ViolinRenderer
        ViewerPanels
        LogTextArea
        ColormapTree
        ColormapDomain
        ColormapPreview
        SettingsUI struct = struct()
        SegmentationUI struct = struct()
        DisplayLimitUI struct = struct()
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
        ObjectViewerKey (1,1) string = ""
        LabelHotkeys (1,:) string = string.empty(1,0)
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
                    obj.Project = oops.model.Project("Untitled",oops.config.Settings.load());
                    obj.OwnsProject = true;
                else
                    validateattributes(opts.Project,{'oops.model.Project'},{'scalar'});
                    obj.Project = opts.Project;
                end

                if opts.WriteLogFile
                    obj.Logger = oops.Log.startSession();
                    obj.OwnsLogger = true;
                else
                    obj.Logger = oops.Log.get();
                end

                obj.UICal = matlabx.UICal.get();
                obj.buildWindow();
                obj.CommandRouter = matlabx.ui.interaction.CommandRouter('Parent',obj.Fig);
                obj.buildAccordion();
                obj.buildViewers();
                obj.buildObjectViewers();
                obj.buildPlots();
                obj.buildMenus();
                obj.bindEvents();
                obj.reconcileActive();
                obj.refreshNavigation();
                obj.refreshViewers(true);
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

            % Open each chosen input independently so a bad file does not stop later imports.
            for k = 1:numel(files)

                % Filename stem used as the imported image's initial name.
                [~,name] = fileparts(files(k));
                oops.analysis.updateProgress(progress, ...
                    sprintf('Image %d/%d: %s\nLoading four-angle input...',k,numel(files),name), ...
                    (k-1)/numel(files));
                try

                    % Lazy four-angle input opened from the current path.
                    input = oops.io.readInput(files(k));

                    % New image model attached to the destination group.
                    image = group.addImage(input,string(name));
                    images(end+1,1) = image; %#ok<AGROW>
                catch ME
                    oops.Log.EXCEPTION(ME);
                    % One invalid file must not prevent importing later valid files.
                end
            end

            if ~isempty(images)
                obj.Project.setActiveImage(images(1));
            end

        end

        function calibrations = registerCalibrations(obj,files)
        %REGISTERCALIBRATIONS Add reusable files without assigning any group.

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog("Registering calibration stacks..."); %#ok<ASGLU>
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
            oops.analysis.updateProgress(progress,"Updating viewers...",[]);
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

                % Application tools unregister their toolbar/menu contributions
                % while the ImageAxes graphics hierarchy is still alive.
                for tool = obj(k).OrientationFieldTools
                    if ~isempty(tool{1}) && isvalid(tool{1})
                        delete(tool{1});
                    end
                end

                % Application-owned content removes its passive mount next.
                for field = obj(k).OrientationFields
                    if ~isempty(field{1}) && isvalid(field{1})
                        delete(field{1});
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
                    delete(obj(k).Project);
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

        function buildWindow(obj)
        %BUILDWINDOW Use a fixed settings column and a non-scrolling viewer/log grid.

            obj.Fig = uifigure('Name','OOPS','Tag',oops.Info.MainFigureTag, ...
                'Visible','off','AutoResizeChildren','off','Position',[80 80 1400 850],'Color',[.12 .12 .12], ...
                'CloseRequestFcn',@(~,~) delete(obj));
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

            % Ordered item titles for navigation, summaries, and settings sections.
            titles = ["Groups","Images","Objects","Labels","Summary", ...
                "Object Selection","View","Mask","Scatterplot","Swarmplot", ...
                "Colormap","Display Limits"];

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
            obj.buildLabels();
            obj.buildSummary();

            % Object overlay geometry and appearance settings.
            obj.addSetting("Object Selection","Shape","ObjectSelection", ...
                "BoxType",["Boundary","Box"]);
            obj.addSetting("Object Selection","Color by","ObjectSelection", ...
                "ColorMode",["Custom","Label"]);
            obj.buildObjectSelectionColor();
            obj.addSetting("Object Selection","Line width","ObjectSelection","LineWidth");
            obj.addSetting("Object Selection","Selected width", ...
                "ObjectSelection","SelectedLineWidth");

            % Image source choices supported by both viewer dropdowns.
            sources = oops.config.View.sources();
            obj.addSetting("View","Left","View","LeftSource",sources(sources ~= "Objects"));
            obj.addSetting("View","Right","View","RightSource",sources);

            % Segmentation catalog used to populate the strategy selector and controls.
            definitions = oops.analysis.segment.strategies();
            obj.addSetting("Mask","Strategy","Segmentation","Strategy",[definitions.Name]);
            obj.SettingsUI.Segmentation.Strategy.Items = cellstr([definitions.Label]);
            obj.addSetting("Mask","Connectivity","Segmentation","Connectivity",[4 8]);
            obj.buildSegmentationAdjustments(definitions);
            obj.addSectionLabel("Mask","Object filtering");
            obj.addSetting("Mask","Minimum area","Segmentation","MinimumArea");
            obj.addSetting("Mask","Maximum objects","Segmentation","MaxObjects");
            obj.SettingsUI.Segmentation.MaxObjects.Tooltip = 'Keep the brightest objects by mean input intensity; 0 means unlimited.';
            obj.addSetting("Mask","Border width","Segmentation","BorderWidth");
            obj.buildScatterPlotControls();
            obj.buildSwarmPlotControls();
            obj.buildColormapControls();
            obj.buildDisplayLimits();

            % Expand the three navigation sections for initial use.
            for title = ["Groups","Images","Objects","Labels"]
                obj.SettingsAccordion.getItem(title).expand();
            end

        end

        function buildScatterPlotControls(obj)
        %BUILDSCATTERPLOTCONTROLS Bind scatter variables and appearance settings.

            variables = oops.model.Object.measurementNames();
            obj.addSetting("Scatterplot","X variable","ScatterPlot","XVariable",variables);
            obj.addSetting("Scatterplot","Y variable","ScatterPlot","YVariable",variables);
            obj.addSetting("Scatterplot","Group by","ScatterPlot","GroupingType",["Group","Label"]);
            obj.addSetting("Scatterplot","Color by","ScatterPlot","ColorMode",["Group","Label","Magnitude"]);
            obj.addSetting("Scatterplot","Marker size","ScatterPlot","MarkerSize");
            obj.addSetting("Scatterplot","Marker face alpha","ScatterPlot","MarkerFaceAlpha");
            obj.addSetting("Scatterplot","Marker edge alpha","ScatterPlot","MarkerEdgeAlpha");
            obj.addSetting("Scatterplot","Marker mode","ScatterPlot","MarkerMode",["single","multi","auto"]);
            obj.addSetting("Scatterplot","Marker edge color","ScatterPlot", ...
                "MarkerEdgeColorMode",["Custom","auto"]);
            obj.addSetting("Scatterplot","Show hulls","ScatterPlot","HullVisible");
            obj.addSetting("Scatterplot","Hull type","ScatterPlot","HullType",["concave","convex"]);
            obj.addSetting("Scatterplot","Hull line width","ScatterPlot","HullLineWidth");
            obj.addSetting("Scatterplot","Hull face alpha","ScatterPlot","HullFaceAlpha");
            obj.addSetting("Scatterplot","Hull edge alpha","ScatterPlot","HullEdgeAlpha");
            obj.addSetting("Scatterplot","Hull face color","ScatterPlot", ...
                "HullFaceColorMode",["Custom","auto"]);
            obj.addSetting("Scatterplot","Hull edge color","ScatterPlot", ...
                "HullEdgeColorMode",["Custom","auto"]);
            obj.addSetting("Scatterplot","Show legend","ScatterPlot","LegendVisible");
            obj.addColorSetting("Scatterplot","Background","ScatterPlot","BackgroundColor");
            obj.addColorSetting("Scatterplot","Foreground","ScatterPlot","ForegroundColor");
            obj.addColorSetting("Scatterplot","Marker edge","ScatterPlot","MarkerEdgeColor");
            obj.addColorSetting("Scatterplot","Hull face","ScatterPlot","HullFaceColor");
            obj.addColorSetting("Scatterplot","Hull edge","ScatterPlot","HullEdgeColor");
        end

        function buildSwarmPlotControls(obj)
        %BUILDSWARMPLOTCONTROLS Bind violin grouping, variable, and appearance settings.

            variables = oops.model.Object.measurementNames();
            obj.addSetting("Swarmplot","Y variable","SwarmPlot","YVariable",variables);
            obj.addSetting("Swarmplot","Group by","SwarmPlot","GroupingType",["Group","Label","Both"]);
            obj.addSetting("Swarmplot","Color by","SwarmPlot","ColorMode",["Group","Label","Magnitude"]);
            obj.addSetting("Swarmplot","Marker size","SwarmPlot","MarkerSize");
            obj.addSetting("Swarmplot","Marker face alpha","SwarmPlot","MarkerFaceAlpha");
            obj.addSetting("Swarmplot","Jitter width","SwarmPlot","XJitterWidth");
            obj.addSetting("Swarmplot","Show points","SwarmPlot","PointsVisible");
            obj.addSetting("Swarmplot","Show violins","SwarmPlot","ViolinOutlinesVisible");
            obj.addSetting("Swarmplot","Show error bars","SwarmPlot","ErrorBarsVisible");
            obj.addSetting("Swarmplot","Marker edge color","SwarmPlot", ...
                "MarkerEdgeColorMode",["Custom","auto"]);
            obj.addSetting("Swarmplot","Violin face color","SwarmPlot", ...
                "ViolinFaceColorMode",["Custom","auto"]);
            obj.addSetting("Swarmplot","Violin edge color","SwarmPlot", ...
                "ViolinEdgeColorMode",["Custom","auto"]);
            obj.addSetting("Swarmplot","Error-bar color","SwarmPlot", ...
                "ErrorBarsColorMode",["Custom","auto"]);
            obj.addColorSetting("Swarmplot","Background","SwarmPlot","BackgroundColor");
            obj.addColorSetting("Swarmplot","Foreground","SwarmPlot","ForegroundColor");
            obj.addColorSetting("Swarmplot","Marker edge","SwarmPlot","MarkerEdgeColor");
            obj.addColorSetting("Swarmplot","Violin face","SwarmPlot","ViolinFaceColor");
            obj.addColorSetting("Swarmplot","Violin edge","SwarmPlot","ViolinEdgeColor");
            obj.addColorSetting("Swarmplot","Error bars","SwarmPlot","ErrorBarsColor");
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
                'Value',obj.Project.Settings.(domain).(name), ...
                'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onSettingEdited(src)));
            control.Layout.Row = row;
            control.Layout.Column = 2;
            control.UserData = struct('Domain',domain,'Name',name);
            obj.SettingsUI.(domain).(name) = control;
        end

        function buildLabels(obj)
        %BUILDLABELS Display the project label registry and its active shortcut target.

            % Accordion item grid containing the project label list.
            pane = obj.SettingsAccordion.getItem("Labels").Pane;
            set(pane,'RowHeight',{140},'ColumnWidth',{'1x'},'Padding',0);

            % Plain tree selection chooses the active label; object checks remain separate.
            obj.LabelsTree = uitree(pane,'Tag','oops.labels', ...
                'BackgroundColor',[.18 .18 .18],'FontColor',[.9 .9 .9], ...
                'SelectionChangedFcn',@(~,~) obj.runCallback(@() obj.onLabelSelected()));
            obj.LabelsTree.Tooltip = 'Select a label, or press its hotkey, to label checked objects.';
            obj.LabelsTree.ContextMenu = obj.labelMenu("");
            obj.refreshLabels();
        end

        function buildObjectSelectionColor(obj)
        %BUILDOBJECTSELECTIONCOLOR Add the RGB picker omitted by generic scalar settings.

            % Accordion grid receiving the custom color row.
            pane = obj.SettingsAccordion.getItem("Object Selection").Pane;

            % Next grid row allocated for the label and color picker.
            row = numel(pane.RowHeight)+1;
            pane.RowHeight{row} = 'fit';

            text = uilabel(pane,'Text','Custom color','FontColor',[.85 .85 .85]);
            text.Layout.Row = row;
            text.Layout.Column = 1;

            % Native color picker bound to the project-wide custom overlay color.
            control = uicolorpicker(pane, ...
                'Value',obj.Project.Settings.ObjectSelection.Color, ...
                'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onSettingEdited(src)));
            control.Layout.Row = row;
            control.Layout.Column = 2;
            control.UserData = struct('Domain','ObjectSelection','Name','Color');
            obj.SettingsUI.ObjectSelection.Color = control;
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
            value = obj.Project.Settings.(domain).(name);

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
        %BUILDSEGMENTATIONADJUSTMENTS Build scalar controls from strategy metadata.
        % Names/ranges live in the catalog; callback bindings carry no strategy switch.

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem("Mask").Pane;

            % Read each strategy's control definitions.
            for definition = definitions

                % Create a scalar slider for each adjustable strategy parameter.
                for parameter = definition.Parameters

                    if ~parameter.Adjustable
                        continue;
                    end

                    % Next grid row allocated for this control or label.
                    row = numel(pane.RowHeight)+1;
                    pane.RowHeight{row} = 'fit';

                    % Bound UI component being constructed or synchronized.
                    control = matlabx.ui.control.Slider(pane,'Title',char(parameter.Label), ...
                        'ValueMode','scalar','Limits',parameter.Limits, ...
                        'Value',mean(parameter.Limits),'ValueDisplayFormat','%.4g', ...
                        'FontColor',[.9 .9 .9],'BackgroundColor',[.18 .18 .18], ...
                        'ValueChangingFcn',@(src,~) obj.runCallback(@() obj.onSegmentationAdjustment(src,false)), ...
                        'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onSegmentationAdjustment(src,true)));
                    control.Layout.Row = row;
                    control.Layout.Column = [1 2];
                    control.UserData = struct('Strategy',definition.Name,'Name',parameter.Name);
                    obj.SegmentationUI.(definition.Name).(parameter.Name) = control;
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
        %REFRESHSEGMENTATIONCONTROLS Show only parameters for the selected strategy.
        % A project strategy change does not relabel or alter an existing mask recipe.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Project strategy currently selected for new segmentation runs.
            strategy = obj.Project.Settings.Segmentation.Strategy;

            % Whether the active image has a committed recipe matching that strategy.
            ready = ~isempty(image) && ~isempty(image.SegmentationParameters) && ...
                image.SegmentationParameters.Strategy == strategy;

            % Accordion item grid that owns the controls being created or updated.
            pane = obj.SettingsAccordion.getItem("Mask").Pane;

            % Whether the selected strategy exposes any adjustable parameters.
            adjustable = false;

            % Synchronize parameter controls for every strategy in the catalog.
            for definition = oops.analysis.segment.strategies()

                % Show and populate only the selected strategy's adjustable controls.
                for parameter = definition.Parameters

                    if ~parameter.Adjustable
                        continue;
                    end

                    % Bound UI component being constructed or synchronized.
                    control = obj.SegmentationUI.(definition.Name).(parameter.Name);

                    % Whether this parameter control belongs to the selected strategy.
                    visible = definition.Name == strategy;
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
                status.Text = sprintf('%s: %d of %d objects retained',recipe.Mode,recipe.RetainedCount,recipe.CandidateCount);
            else
                status.Text = 'Run segmentation to adjust parameters.';
            end

        end

        function onSegmentationAdjustment(obj,control,commit)
        %ONSEGMENTATIONADJUSTMENT Preview without replacing objects; commit on release.

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Control metadata identifying the target domain/strategy and setting name.
            binding = control.UserData;

            if isempty(image) || isempty(image.SegmentationParameters) || ...
                    image.SegmentationParameters.Strategy ~= binding.Strategy
                obj.refreshSegmentationControls();
                return;
            end

            if commit
                obj.commitSegmentationAdjustment(image,binding.Name,control.Value);
            else
                % Current puncta thresholding is cheap on the cached enhanced image.
                % Future adjustable algorithms may provide their own preview path.

                % Image-local segmentation snapshot used for parameter display or adjustment.
                recipe = image.SegmentationParameters.withParameter(binding.Name,control.Value);

                % Strategy metadata defining its algorithm and adjustable controls.
                definition = oops.analysis.segment.strategies(binding.Strategy);

                if isempty(definition.Preview)
                    return;
                end

                % Unfiltered preview foreground produced from cached enhancement.
                candidate = definition.Preview(image.Results.Segmentation,recipe);

                % Filtered preview mask displayed without committing model membership.
                preview = oops.analysis.segment.filter(candidate,image.Results.AverageIntensity,recipe);

                % Left and right panel source names in viewer order.
                names = [obj.Project.Settings.View.LeftSource,obj.Project.Settings.View.RightSource];

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
            oops.analysis.Analyzer.adjustSegmentation(image,name,value,obj.Project.Settings);
            obj.reconcileActive();

            % Left and right panel source names in viewer order.
            names = [obj.Project.Settings.View.LeftSource,obj.Project.Settings.View.RightSource];
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
        %BUILDDISPLAYLIMITS Give each domain its own project policy and image-local range.

            % Create independent auto-scale and manual-range controls for each display domain.
            for domain = ["Intensity","Order"]
                obj.addSetting("Display Limits","Auto "+lower(domain),"Display","AutoScaleDisplay"+domain);

                % Accordion item grid that owns the controls being created or updated.
                pane = obj.SettingsAccordion.getItem("Display Limits").Pane;

                % Next grid row allocated for this control or label.
                row = numel(pane.RowHeight)+1;
                pane.RowHeight{row} = 'fit';

                % Bound UI component being constructed or synchronized.
                control = matlabx.ui.control.Slider(pane,'Title',char(domain), ...
                    'ValueMode','range','Limits',[0 1],'Value',[0 1], ...
                    'ValueDisplayFormat','%.4g','FontColor',[.9 .9 .9], ...
                    'BackgroundColor',[.18 .18 .18], ...
                    'ValueChangingFcn',@(src,~) obj.runCallback(@() obj.onDisplayLimitsEdited(src,false)), ...
                    'ValueChangedFcn',@(src,~) obj.runCallback(@() obj.onDisplayLimitsEdited(src,true)));
                control.UserData = domain;
                control.Layout.Row = row;
                control.Layout.Column = [1 2];
                obj.DisplayLimitUI.(domain) = control;
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

                % Whether the active image has data for the current display-limit domain.
                ready = ~isempty(image);

                if isprop(control,'Enable')
                    control.Enable = matlab.lang.OnOffSwitchState(ready);
                end

                if ready

                    % Effective display range and slider bounds resolved for this image/domain.
                    [value,bounds] = oops.render.displayLimits(image,domain,obj.Project.Settings);
                    control.Limits = bounds;
                    control.Value = value;
                else
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

            if value(1) >= value(2)
                obj.refreshDisplayLimits();
                return;
            end

            if commit
                obj.Processing = true;

                % Cleanup guard restoring the temporary callback/processing state.
                guard = onCleanup(@() obj.endProcessing());
                image.setDisplayRange(domain,value);
                obj.Project.Settings.Display.("AutoScaleDisplay"+domain) = false;
                obj.Processing = false;
                obj.refreshViewers(true);
            else

                % Left and right panel source names in viewer order.
                names = [obj.Project.Settings.View.LeftSource,obj.Project.Settings.View.RightSource];

                % Left and right ImageAxes handles in panel order.
                viewers = {obj.LeftViewer,obj.RightViewer};

                if domain == "Intensity"

                    % Panel flags identifying sources that use the edited display domain.
                    affected = ismember(names,["Input","Corrected","Average intensity"]);
                else
                    affected = names == "Order";
                end

                % Apply edited limits only to viewers currently displaying the matching domain.
                for k = find(affected)

                    % ImageAxes for the current left/right panel.
                    viewer = viewers{k};
                    viewer.CLimMode = 'manual';
                    viewer.ComponentCLims = repmat({value},1,viewer.NumComponents);
                end

                % Object crops use the same parent-image display limits.
                if obj.Project.Settings.View.RightSource == "Objects"

                    if domain == "Intensity"
                        viewer = obj.ObjectViewers{1};
                    else
                        viewer = obj.ObjectViewers{2};
                    end

                    if viewer.ImageVisible == "on"
                        viewer.CLimMode = 'manual';
                        viewer.ComponentCLims = repmat({value},1,viewer.NumComponents);
                    end

                end

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
                    'CData',[],'Tools',{'Zoom','Mask','Overlays','Polygon','RectangleSelect','Colorbar'},'Colormap',gray(256), ...
                    'CLim',[0 1],'FontSize',12);
                viewer.Tools.RectangleSelect.TargetTypes = "Polygon";
                viewer.Tools.Polygon.PolygonActivatedFcn = @(~,d) obj.runCallback(@() obj.onPolygonActivated(d));
                viewer.Tools.Polygon.PolygonSelectionChangedFcn = @(~,d) obj.runCallback(@() obj.onPolygonSelectionChanged(d));
                viewer.Tools.Polygon.PolygonsDeleteRequestedFcn = @(~,d) obj.runCallback(@() obj.onPolygonsDeleteRequested(d));

                % Passive axial field uses MATLABX's application-overlay layer.
                field = oops.render.OrientationField();
                mount = viewer.mountOverlay(field);
                tool = oops.ui.axes.tools.OrientationField(viewer,mount);
                viewer.installTool(tool);
                tool.enable();
                obj.OrientationFields{k} = field;
                obj.OrientationFieldTools{k} = tool;

                if k == 1
                    obj.LeftViewer = viewer;
                else
                    obj.RightViewer = viewer;
                end

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

            scatterSettings = obj.Project.Settings.ScatterPlot;
            swarmSettings = obj.Project.Settings.SwarmPlot;

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
        end

        function buildMenus(obj)
        %BUILDMENUS Build import, processing, and content presets with thin callbacks.

            % File menu containing image/calibration import actions.
            file = uimenu(obj.Fig,'Text','File');
            uimenu(file,'Text','Load images...','MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseFiles()));
            obj.MenuUI.Calibration = uimenu(file,'Text','Register calibration stacks...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseCalibrationFiles()));

            % Analysis menu containing explicit segmentation and FPM actions.
            analysis = uimenu(obj.Fig,'Text','Analysis');
            uimenu(analysis,'Text','Segment selected / active images','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.runAnalysis("Segment")));
            uimenu(analysis,'Text','Order/orientation for selected / active images','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.runAnalysis("FPM")));

            % View menu populated from the graphics-free preset catalog.
            view = uimenu(obj.Fig,'Text','View');

            % Create one menu entry for each catalog-defined view preset.
            for preset = oops.app.viewPresets()
                % Definitions describe content; the controller owns its graphics.
                uimenu(view,'Text',char(preset.Name),'UserData',preset, ...
                    'MenuSelectedFcn',@(src,~) obj.runCallback(@() obj.applyViewPreset(src.UserData)));
            end

            % Settings menu containing JSON save/load actions.
            settings = uimenu(obj.Fig,'Text','Settings');
            uimenu(settings,'Text','Save as app defaults','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.Project.Settings.save()));
            uimenu(settings,'Text','Load app defaults','MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.loadSettings()));
        end

        function applyViewPreset(obj,preset)
        %APPLYVIEWPRESET Set both panel choices before refreshing changed sources once.
        % Settings events still synchronize the accordion during the guarded update.

            % Settings object supplying the values for this operation.
            settings = obj.Project.Settings.View;

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

        end

        function restoreProcessing(obj,value)
        %RESTOREPROCESSING Restore a temporary event guard without another refresh.

            obj.Processing = value;
        end

        function bindEvents(obj)
        %BINDEVENTS Keep all settings and model subscriptions in the controller.

            % Subscribe once to project collection events used to reconcile navigation.
            for name = ["GroupAdded","GroupRemoved","ImageAdded","ImageRemoved","ObjectsChanged"]
                obj.Listeners(end+1) = addlistener(obj.Project,char(name), ...
                    @(~,~) obj.runCallback(@() obj.onCollectionChanged()));
            end

            obj.Listeners(end+1) = addlistener(obj.Project,'CalibrationChanged', ...
                @(~,e) obj.runCallback(@() obj.onCalibrationChanged(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'GroupChanged', ...
                @(~,~) obj.runCallback(@() obj.onGroupChanged()));
            obj.Listeners(end+1) = addlistener(obj.Project,'ImageAdded', ...
                @(~,e) obj.runCallback(@() obj.onImageAdded(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'ActiveImageChanged', ...
                @(~,~) obj.runCallback(@() obj.onNavigationChanged()));
            obj.Listeners(end+1) = addlistener(obj.Project,'NavigationChanged', ...
                @(~,e) obj.runCallback(@() obj.onNavigationChanged(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'DataChanged', ...
                @(~,e) obj.runCallback(@() obj.onDataChanged(e)));
            obj.Listeners(end+1) = addlistener(obj.Project,'LabelsChanged', ...
                @(~,~) obj.runCallback(@() obj.onLabelsChanged()));
            obj.Listeners(end+1) = addlistener(obj.Project,'ActiveLabelChanged', ...
                @(~,~) obj.runCallback(@() obj.syncActiveLabel()));
            obj.Listeners(end+1) = addlistener(obj.Project.Settings,'Changed', ...
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
            obj.refreshNavigation();
            obj.refreshViewers(false);
        end

        function onGroupChanged(obj)
        %ONGROUPCHANGED Refresh names, swatches, summaries, and group-colored plots.

            if obj.Processing
                return;
            end

            obj.refreshNavigation();

            if any(ismember([obj.Project.Settings.View.LeftSource, ...
                    obj.Project.Settings.View.RightSource],["Scatterplot","Swarmplot"]))
                obj.refreshPlots();
            end
        end

        function onNavigationChanged(obj,e)
        %ONNAVIGATIONCHANGED Reflect ID state; batch changes never reset viewer state.

            if obj.Processing
                return;
            end

            obj.refreshNavigation();

            if nargin > 1 && e.Domain == "Image" && ...
                    ismember(e.Name,["SelectedObjectIDs","ActiveObjectID"])
                obj.syncOverlayState();

                if e.Name == "ActiveObjectID" && ...
                        obj.Project.Settings.View.RightSource == "Objects"
                    obj.refreshObjectViewers(false);
                end

                return;
            end

            if nargin > 1 && startsWith(e.Name,"Selected")
                return;
            end

            obj.refreshViewers(false);
        end

        function onDataChanged(obj,e)
        %ONDATACHANGED Refresh processed sources only for changes to the active image.

            if obj.Processing
                return;
            end

            % Per-object measurement events need only the Object summary.
            % Collection/image outputs also affect project/group status counts.
            if e.ObjectID == "" || string(obj.SummaryDomain.Value) == "Object"
                obj.refreshSummary();
            end

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            if isempty(image) || image.ID ~= e.ImageID
                if any(ismember([obj.Project.Settings.View.LeftSource, ...
                        obj.Project.Settings.View.RightSource],["Scatterplot","Swarmplot"]))
                    obj.refreshPlots();
                end
                return;
            end

            if any(ismember([obj.Project.Settings.View.LeftSource, ...
                    obj.Project.Settings.View.RightSource],["Scatterplot","Swarmplot"]))
                obj.refreshPlots();
            end

            if e.Name == "Mask"
                % Only the mask source needs new image data. Other sources just
                % receive the updated alpha mask and object membership below.

                % Left and right panel source names in viewer order.
                names = [obj.Project.Settings.View.LeftSource,obj.Project.Settings.View.RightSource];
                obj.ViewerKeys(names == "Mask") = "";
                obj.ObjectViewerKey = "";
                obj.refreshViewers(false);
            elseif ismember(e.Name,["Results","DisplayRange"])
                obj.ObjectViewerKey = "";
                obj.refreshViewers(true);
            elseif e.Name == "ObjectLabels"
                obj.refreshOverlayAppearance();
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

            if isempty(image)
                obj.syncTree(obj.ObjectsTree,oops.model.Object.empty(0,1),"",strings(0,1));
            else
                obj.syncTree(obj.ObjectsTree,image.Objects,image.ActiveObjectID,image.SelectedObjectIDs);
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

            % Flags marking nodes whose model children no longer exist.
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

            % Control metadata identifying the target domain/strategy and setting name.
            binding = control.UserData;

            % Settings object supplying the values for this operation.
            settings = obj.Project.Settings.(binding.Domain);
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
            catch ME
                control.Value = settings.(binding.Name);
                rethrow(ME);
            end
        end

        function onSettingsChanged(obj,e)
        %ONSETTINGSCHANGED Sync the bound control and execute domain-specific refresh policy.

            if isfield(obj.SettingsUI,e.Domain) && isfield(obj.SettingsUI.(e.Domain),e.Name)

                % Bound UI component being constructed or synchronized.
                control = obj.SettingsUI.(e.Domain).(e.Name);
                control.Value = e.NewValue;
            end

            if obj.Processing
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
                    obj.refreshOrientationFields([obj.Project.Settings.View.LeftSource, ...
                        obj.Project.Settings.View.RightSource]);
                case "ObjectSelection"
                    obj.refreshViewerRegions();
                case "ObjectDisplay"
                    obj.ObjectViewerKey = "";

                    if obj.Project.Settings.View.RightSource == "Objects"
                        obj.refreshObjectViewers(false);
                    end
                case {"ScatterPlot","SwarmPlot","Palettes"}
                    obj.refreshPlots();
            end

        end

        function refreshLabels(obj)
        %REFRESHLABELS Rebuild the small label tree and synchronize its hotkeys.

            if isempty(obj.LabelsTree) || ~isvalid(obj.LabelsTree)
                return;
            end

            obj.deleteTreeNodes(obj.LabelsTree.Children);

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

            obj.refreshLabelHotkeys();
            obj.syncActiveLabel();
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
            obj.refreshPlots();
        end

        function menu = labelMenu(obj,id)
        %LABELMENU Build registry actions bound to one context-clicked label ID.

            menu = uicontextmenu(obj.Fig);
            uimenu(menu,'Text','New label...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptLabel()));

            if id == ""
                return;
            end

            uimenu(menu,'Text','Edit label...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptLabel(id)));

            % Unlabeled is the permanent fallback used by new and reassigned objects.
            item = uimenu(menu,'Text','Delete label...', ...
                'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.deleteLabel(id)));

            if id == "unlabeled"
                item.Enable = 'off';
            end
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

            % Active image supplying data and object membership for this operation.
            image = obj.Project.ActiveImage;

            % Settings object supplying the values for this operation.
            settings = obj.Project.Settings;

            % Left and right ImageAxes handles in panel order.
            viewers = {obj.LeftViewer,obj.RightViewer};

            % Left and right panel source names in viewer order.
            names = [settings.View.LeftSource,settings.View.RightSource];

            % Reparent the two singleton plot sources and expose one content type per panel.
            obj.syncPanelContent(names);
            obj.resizeViewers();

            % Resolve and update each panel only when forced or its source key changes.
            for k = 1:2

                if ismember(names(k),["Empty","Scatterplot","Swarmplot","Objects"])
                    obj.ViewerKeys(k) = names(k);
                    continue;
                end

                % Source name plus active image ID used to detect unchanged viewer content.
                key = names(k);

                if ~isempty(image)
                    key = key + ":" + image.ID;
                end

                if ~force && obj.ViewerKeys(k) == key
                    continue;
                end

                % Display-ready Image5D source and its title/scaling/availability metadata.
                [data,info] = oops.render.source(image,names(k),settings);

                % ImageAxes for the current left/right panel.
                viewer = viewers{k};
                obj.ViewerPanels(k).Title = char(info.Title);

                if info.Available

                    % Whether the viewer already represents this same image/source pair.
                    sameSource = obj.ViewerKeys(k) == key;

                    % Current component/Z/T indices retained when refreshing the same source.
                    indices = [viewer.C viewer.Z viewer.T];
                    viewer.ImageData = data;

                    if sameSource
                        viewer.C = min(indices(1),data.NumComponents);
                        viewer.Z = min(indices(2),data.SizeZ);
                        viewer.T = min(indices(3),data.SizeT);
                    end

                    viewer.ShowComposite = 'off';
                    viewer.ComponentColormaps = repmat({info.Colormap},1,data.NumComponents);

                    if ~isempty(info.CLim)
                        viewer.CLimMode = 'manual';
                        viewer.ComponentCLims = repmat({info.CLim},1,data.NumComponents);
                    elseif settings.Display.AutoScaleDisplayIntensity
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
                    obj.ViewerPanels(k).Title = char(info.Title + " — " + info.Reason);
                end

                obj.ViewerKeys(k) = key;
            end

            if any(ismember(names,["Scatterplot","Swarmplot"]))
                obj.refreshPlots();
            end

            if names(2) == "Objects"
                obj.refreshObjectViewers(force);
            end

            obj.refreshViewerRegions();
            obj.refreshOrientationFields(names);

            if refreshControls
                obj.refreshSegmentationControls();
                obj.refreshDisplayLimits();
            end

        end

        function syncPanelContent(obj,names)
        %SYNCPANELCONTENT Mount each requested source in one stable panel host.

            viewers = {obj.LeftViewer,obj.RightViewer};
            plotAxes = {obj.LeftPlotAxes,obj.RightPlotAxes};

            % The object quadrant grid replaces the complete normal right panel.
            showingObjects = names(2) == "Objects";
            obj.ViewerPanels(2).Visible = matlab.lang.OnOffSwitchState(~showingObjects);
            obj.ObjectViewerGrid.Visible = matlab.lang.OnOffSwitchState(showingObjects);

            for k = 1:2
                obj.ViewerPanels(k).Title = char(names(k));

                switch names(k)
                    case "Scatterplot"
                        viewers{k}.Visible = 'off';
                        plotAxes{k}.Visible = 'on';
                        plotAxes{k}.mount(obj.ScatterRenderer);

                    case "Swarmplot"
                        viewers{k}.Visible = 'off';
                        plotAxes{k}.Visible = 'on';
                        plotAxes{k}.mount(obj.SwarmRenderer);

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
        end

        function refreshObjectViewers(obj,force)
        %REFRESHOBJECTVIEWERS Populate the four aligned crops for the active object.

            region = obj.Project.ActiveObject;

            if isempty(region)
                obj.clearObjectViewers("No active object");
                obj.ObjectViewerKey = "";
                return;
            end

            % Identity key avoids rebuilding four Image5D objects for unrelated refreshes.
            key = region.Parent.ID + ":" + region.ID;

            if ~force && obj.ObjectViewerKey == key
                return;
            end

            [sources,info,objectMask] = oops.render.objectSources( ...
                region,obj.Project.Settings);

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

            obj.ObjectViewerKey = key;
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

            names = [obj.Project.Settings.View.LeftSource, ...
                obj.Project.Settings.View.RightSource];

            if any(names == "Scatterplot")
                obj.refreshScatterPlot();
            end

            if any(names == "Swarmplot")
                obj.refreshSwarmPlot();
            end
        end

        function refreshScatterPlot(obj)
        %REFRESHSCATTERPLOT Normalize model scalars for the scatter renderer.

            settings = obj.Project.Settings.ScatterPlot;
            [members,groupNames] = obj.plotPartitions(settings.GroupingType);

            if isempty(members)
                members = {oops.model.Object.empty(0,1)};
                groupNames = "No data";
            end

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

            % Translate application settings into the renderer-facing value.
            style = matlabx.ui.axes.plot.ScatterStyle( ...
                Title=settings.YVariable+" vs "+settings.XVariable, ...
                XLabel=settings.XVariable, ...
                YLabel=settings.YVariable, ...
                BackgroundColor=settings.BackgroundColor, ...
                ForegroundColor=settings.ForegroundColor, ...
                Colormap=colormap, ...
                CLim=limits, ...
                LegendVisible=settings.LegendVisible, ...
                MarkerSize=settings.MarkerSize, ...
                MarkerMode=settings.MarkerMode, ...
                MarkerFaceAlpha=settings.MarkerFaceAlpha, ...
                MarkerEdgeAlpha=settings.MarkerEdgeAlpha, ...
                MarkerEdgeColorMode=settings.MarkerEdgeColorMode, ...
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
                SeriesNames=groupNames, ...
                CData=colorData);

            obj.ScatterRenderer.update(data,style);
        end

        function refreshSwarmPlot(obj)
        %REFRESHSWARMPLOT Normalize model scalars for the violin renderer.

            settings = obj.Project.Settings.SwarmPlot;
            [members,groupNames] = obj.plotPartitions(settings.GroupingType);

            if isempty(members)
                members = {oops.model.Object.empty(0,1)};
                groupNames = "No data";
            end

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

            % Resolve OOPS configuration into an application-independent style.
            style = matlabx.ui.axes.plot.ViolinStyle( ...
                Title=settings.YVariable, ...
                XLabel="Group", ...
                YLabel=settings.YVariable, ...
                BackgroundColor=settings.BackgroundColor, ...
                ForegroundColor=settings.ForegroundColor, ...
                Colormap=colormap, ...
                CLim=limits, ...
                MarkerSize=settings.MarkerSize, ...
                MarkerFaceAlpha=settings.MarkerFaceAlpha, ...
                MarkerEdgeColorMode=settings.MarkerEdgeColorMode, ...
                MarkerEdgeColor=settings.MarkerEdgeColor, ...
                XJitterWidth=settings.XJitterWidth, ...
                PointsVisible=settings.PointsVisible, ...
                ViolinOutlinesVisible=settings.ViolinOutlinesVisible, ...
                ViolinFaceColorMode=settings.ViolinFaceColorMode, ...
                ViolinFaceColor=settings.ViolinFaceColor, ...
                ViolinEdgeColorMode=settings.ViolinEdgeColorMode, ...
                ViolinEdgeColor=settings.ViolinEdgeColor, ...
                ErrorBarsVisible=settings.ErrorBarsVisible, ...
                ErrorBarsColorMode=settings.ErrorBarsColorMode, ...
                ErrorBarsColor=settings.ErrorBarsColor);

            plotData = matlabx.ui.axes.plot.ViolinData( ...
                Values=data, ...
                SeriesNames=groupNames, ...
                CData=colorData);

            obj.SwarmRenderer.update(plotData,style);
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

            if isempty(members)
                values = zeros(0,1);
            else
                values = arrayfun(@(member) member.(property),members(:));
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
        %REFRESHORIENTATIONFIELDS Draw sampled axial segments over average intensity.

            % Active image supplying order, azimuth, and optional object membership.
            image = obj.Project.ActiveImage;

            % Project-wide appearance and sampling preferences for this overlay.
            settings = obj.Project.Settings.AzimuthDisplay;

            for k = 1:2

                % Application-owned content and its visibility tool for this panel.
                field = obj.OrientationFields{k};
                tool = obj.OrientationFieldTools{k};

                % The first implementation is intentionally limited to the
                % average-intensity source and requires completed FPM analysis.
                available = names(k) == "Average intensity" && ...
                    ~isempty(image) && ~isempty(image.Order) && ~isempty(image.Azimuth);

                if ~available
                    field.clear();
                    tool.setAvailable(false);
                    continue;
                end

                % Pixels eligible for display before applying spatial sampling.
                mask = isfinite(image.Order) & isfinite(image.Azimuth);

                if settings.ObjectMask

                    if isempty(image.Mask)
                        mask(:) = false;
                    else
                        mask = mask & image.Mask;
                    end

                end

                % Regular sampling lattice limits the number of graphics segments.
                spacing = settings.ScaleDownFactor;

                if spacing > 1
                    sampled = false(size(mask));
                    sampled(1:spacing:end,1:spacing:end) = true;
                    mask = mask & sampled;
                end

                % Parent-image pixel centers and their axial FPM results.
                [y,x] = find(mask);
                angle = image.Azimuth(mask);
                magnitude = image.Order(mask);

                % Direction uses the cyclic azimuth map; magnitude uses order.
                if settings.ColorMode == "Magnitude"
                    map = oops.render.colormap(obj.Project.Settings.Colormaps,"Order");
                else
                    map = oops.render.colormap(obj.Project.Settings.Colormaps,"Azimuth");
                end

                field.setStyle( ...
                    ColorMode=settings.ColorMode, ...
                    Colormap=map, ...
                    LineWidth=settings.LineWidth, ...
                    Alpha=settings.LineAlpha, ...
                    Scale=settings.LineScale);
                field.setData(x,y,angle,magnitude);
                tool.setAvailable(true);
            end

        end

        function refreshViewerRegions(obj)
        %REFRESHVIEWERREGIONS Reconcile polygon membership without rebuilding survivors.
        %
        % Mask and object coordinates belong to the active input image. They
        % apply to all four frames, but not to unavailable sources or a
        % calibration stack with different spatial dimensions.

            if obj.SyncingOverlays || obj.Closing
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

            % Per-refresh boundary cache shared by both viewers for each object ID.
            geometry = containers.Map('KeyType','char','ValueType','any');

            % Reconcile the active image's mask and object polygons in each viewer.
            for k = 1:2

                % ImageAxes for the current left/right panel.
                viewer = viewers{k};

                if viewer.Visible == "off"
                    continue;
                end

                % Whether this viewer displays an available, spatially compatible image.
                ready = ~isempty(image) && viewer.ImageVisible == "on";

                if ready
                    ready = viewer.ImageData.SizeY == image.Input.SizeY && ...
                        viewer.ImageData.SizeX == image.Input.SizeX;
                end

                % Object IDs to represent with one polygon each in the current viewer.
                ids = strings(0,1);

                % Committed parent-image mask supplied to the viewer's mask tool.
                mask = [];

                if ready
                    ids = oops.model.internal.ids(image.Objects);

                    if ~isempty(image.Mask)
                        mask = image.Mask;
                    end

                end

                % Assigning ImageData clears ImageAxes.Mask. Restore it even
                % when the objects have not changed during a display refresh.
                if ~isequal(viewer.Mask,mask)
                    viewer.Mask = mask;
                end

                % Remove obsolete overlays in one consistent registry update.
                % This is model reconciliation, not a user deletion request.

                % Polygon IDs already registered in this viewer.
                existing = viewer.Overlays.ids(Type="Polygon");
                viewer.Overlays.removeMany(existing(~ismember(existing,ids)));

                if ready

                    % Add or update each object polygon using geometry shared by both viewers.
                    for region = image.Objects'

                        % Current object ID used for both the geometry cache and overlay registry.
                        key = char(region.ID);

                        if ~isKey(geometry,key)
                            geometry(key) = obj.objectOverlayGeometry(region);
                        end

                        if viewer.Overlays.has(region.ID)
                            overlay = viewer.Overlays.get(region.ID);
                            overlay.Vertices = geometry(key);
                        else
                            overlay = viewer.Tools.Polygon.addPolygon( ...
                                region.ID,geometry(key),'Label',region.Name);
                        end

                        obj.applyOverlayAppearance(overlay,region);
                    end

                end

            end

            % With membership synchronized, apply the independent model-owned
            % active/selected IDs. That method has its own callback guard.
            clear guard;
            obj.syncOverlayState();
        end

        function geometry = objectOverlayGeometry(obj,region)
        %OBJECTOVERLAYGEOMETRY Resolve the configured boundary or bounding rectangle.

            if obj.Project.Settings.ObjectSelection.BoxType == "Box"
                box = region.BoundingBox;
                x = box(1);
                y = box(2);
                width = box(3);
                height = box(4);
                geometry = [x y; x+width y; x+width y+height; x y+height];
            else
                geometry = oops.geometry.objectBoundary(region);
            end
        end

        function refreshOverlayAppearance(obj)
        %REFRESHOVERLAYAPPEARANCE Restyle existing polygons without rebuilding graphics.

            image = obj.Project.ActiveImage;

            if isempty(image)
                return;
            end

            for viewer = {obj.LeftViewer,obj.RightViewer}
                axes = viewer{1};

                for region = image.Objects'

                    if axes.Overlays.has(region.ID)
                        obj.applyOverlayAppearance(axes.Overlays.get(region.ID),region);
                    end

                end

            end
        end

        function applyOverlayAppearance(obj,overlay,region)
        %APPLYOVERLAYAPPEARANCE Apply config widths and custom/label color.

            settings = obj.Project.Settings.ObjectSelection;
            color = settings.Color;

            if settings.ColorMode == "Label"
                label = region.Label;

                if ~isempty(label)
                    color = label.Color;
                end
            end

            overlay.EdgeColor = color;
            overlay.FaceColor = color;
            overlay.LineWidth = settings.LineWidth;
            overlay.SelectionLineWidth = settings.SelectedLineWidth;
            overlay.ActiveLineWidth = settings.SelectedLineWidth;
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

            % Copy model active/selected IDs into each viewer's available polygon set.
            for viewer = {obj.LeftViewer,obj.RightViewer}

                % Left and right viewer handles whose overlay navigation is synchronized.
                axes = viewer{1};

                % Selected model IDs restricted to the polygons available in this viewer.
                ids = strings(0,1);

                % Model active-object ID restricted to overlays available in this viewer.
                active = "";

                if ~isempty(image)

                    % Model object IDs currently represented by polygons in this viewer.
                    available = axes.Overlays.ids(Type="Polygon");
                    ids = image.SelectedObjectIDs(ismember(image.SelectedObjectIDs,available));

                    if ismember(image.ActiveObjectID,available)
                        active = image.ActiveObjectID;
                    end

                end

                % Model active-object ID, cleared when this viewer has no matching polygon.
                current = axes.Tools.Polygon.getSelectedPolygonIDs();
                % The manager's selection setter repaints even unchanged sets.
                if ~isequal(current(:),ids(:))
                    axes.Tools.Polygon.setSelectedPolygonIDs(ids);
                end

                axes.Tools.Polygon.setActivePolygonID(active);
            end

        end

        function endOverlaySync(obj)
        %ENDOVERLAYSYNC Release callback suppression after programmatic overlay updates.

            obj.SyncingOverlays = false;
        end

        function onPolygonActivated(obj,data)
        %ONPOLYGONACTIVATED Store viewer activation independently of batch selection.

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

        function onPolygonSelectionChanged(obj,data)
        %ONPOLYGONSELECTIONCHANGED Store viewer selection and reflect it in tree checks.

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

        function onPolygonsDeleteRequested(obj,data)
        %ONPOLYGONSDELETEREQUESTED Commit the full tool request before changing overlays.

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
            names = [obj.Project.Settings.View.LeftSource,obj.Project.Settings.View.RightSource];
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

            if obj.Project.Settings.View.RightSource == "Objects"

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
            pane = obj.SettingsAccordion.getItem("Colormap").Pane;
            set(pane,'ColumnWidth',{'1x'},'RowHeight',{24,24,200},'Padding',5,'RowSpacing',5);
            obj.ColormapDomain = uidropdown(pane,'Items',{'Intensity','Order','Azimuth'}, ...
                'Value','Intensity','BackgroundColor',[.3 .3 .3],'FontColor',[.9 .9 .9], ...
                'ValueChangedFcn',@(~,~) obj.runCallback(@() obj.refreshColormapControls()));
            obj.ColormapDomain.Layout.Row = 1;
            obj.ColormapPreview = uiimage(pane,'ScaleMethod','stretch');
            obj.ColormapPreview.Layout.Row = 2;
            obj.ColormapTree = uitree(pane,'BackgroundColor',[.18 .18 .18],'FontColor',[.9 .9 .9], ...
                'SelectionChangedFcn',@(src,~) obj.runCallback(@() obj.onColormapChosen(src)));
            obj.ColormapTree.Layout.Row = 3;

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

            % Intensity, order, or azimuth domain selected for colormap editing.
            domain = string(obj.ColormapDomain.Value);

            % Project-wide map/category assignments for all display domains.
            maps = obj.Project.Settings.Colormaps;

            % All category/map nodes inspected to restore the assigned map highlight.
            nodes = findall(obj.ColormapTree,'Type','uitreenode');
            obj.ColormapTree.SelectedNodes = [];

            % Find the map leaf corresponding to the selected display domain's assignment.
            for k = 1:numel(nodes)

                % Node/source metadata read for the current UI update.
                data = nodes(k).NodeData;

                if isstruct(data) && data.Name == maps.(domain) && data.Category == maps.(domain+"Category")
                    obj.ColormapTree.SelectedNodes = nodes(k);
                    expand(nodes(k).Parent);
                    break;
                end

            end

            % Selected lookup table rendered as the preview image.
            map = oops.render.colormap(maps,domain);
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
            maps = obj.Project.Settings.Colormaps;
            % Temporarily suspend view updates between category/name changes so
            % a name never resolves against the wrong category during a switch.
            obj.Processing = true;

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() obj.endProcessing());
            maps.setMap(domain,data.Name,data.Category);
            obj.Processing = false;
            obj.refreshColormapControls();
            obj.refreshViewers(true);
        end

        function menu = navigationMenu(obj,title,id)
        %NAVIGATIONMENU Bind node-specific actions to IDs, never the current highlight.

            % Context menu bound to this tree/node identity.
            menu = uicontextmenu(obj.Fig);

            if title == "Groups"
                uimenu(menu,'Text','New group...','MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptGroup()));

                if id ~= ""
                    uimenu(menu,'Text','Edit group...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.promptGroup(id)));

                    % Occasional calibration actions grouped away from routine navigation.
                    calibration = uimenu(menu,'Text','Calibration');
                    uimenu(calibration,'Text','View assignment...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.showCalibrationAssignment(id)));
                    uimenu(calibration,'Text','Assign registered calibrations...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseRegisteredCalibrations(id)));
                    uimenu(calibration,'Text','Import and assign...', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.chooseCalibrationFiles(id)));
                    uimenu(calibration,'Text','Clear assignment','Separator','on', ...
                        'MenuSelectedFcn',@(~,~) obj.runCallback(@() obj.applyCalibrationAssignment(id,strings(0,1))));
                end

                % Domain label used for node-specific and batch deletion actions.
                singular = "group";
            elseif title == "Images"
                singular = "image";
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
                    @(~,~) obj.runCallback(@() obj.deleteNavigation(title,id)));
            end

            uimenu(menu,'Text',char("Delete selected "+lower(title)),'MenuSelectedFcn', ...
                @(~,~) obj.runCallback(@() obj.deleteNavigation(title,"")));
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

                % Remove each target image from its parent group.
                for k = 1:numel(ids)
                    image = oops.model.internal.resolve(group.Images,ids(k));

                    if isempty(image)
                        continue;
                    end

                    group.removeImage(image);
                    delete(image);
                end

            end

            obj.Processing = false;
            obj.reconcileActive();
            obj.refreshNavigation();
            obj.refreshViewers(false);
        end

        function chooseCalibrationFiles(obj,groupID)
        %CHOOSECALIBRATIONFILES Register files, optionally assigning a clicked group.

            if nargin < 2
                groupID = "";
            end

            % Selected calibration filenames and directory, or zero on cancellation.
            [files,folder] = matlabx.image.io.uigetimagefile([], ...
                'Select four-angle calibration stacks',char(obj.Project.Settings.IO.DefaultFolder),MultiSelect='on');
            % Native file dialogs can leave MATLAB behind other windows. Raise
            % this figure on return, including cancellation, and after loading.
            obj.focusWindow();

            % Cleanup guard returning focus to the visible GUI after loading completes.
            cleanupFocus = onCleanup(@() obj.focusWindow()); %#ok<NASGU>

            if isequal(files,0)
                return;
            end

            obj.Project.Settings.IO.DefaultFolder = string(folder);

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
                oops.analysis.updateProgress(progress, ...
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
                    'No calibration files are registered. Use Import and assign first.', ...
                    'Calibration assignment','Icon','info');
                return;
            end

            % Modal editor centered approximately over the main application window.
            mainPosition = obj.Fig.Position;
            width = 520;
            height = 420;
            position = [mainPosition(1)+(mainPosition(3)-width)/2 ...
                mainPosition(2)+(mainPosition(4)-height)/2 width height];
            dialog = uifigure('Name',char(group.Name + " — Calibration assignment"), ...
                'Position',position,'WindowStyle','modal','Resize','on');

            % Simple tree-and-buttons layout leaves room for longer source paths.
            grid = uigridlayout(dialog,[2 1], ...
                'RowHeight',{'1x','fit'},'ColumnWidth',{'1x'},'Padding',10,'RowSpacing',10);
            tree = uitree(grid,'checkbox');
            tree.Layout.Row = 1;
            tree.Tooltip = 'Check every registered calibration stack to average for this group.';

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
            oops.analysis.updateProgress(progress,"Updating viewers...",[]);
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
            oops.analysis.updateProgress(progress,"Updating viewers...",[]);
            obj.Processing = false;
            obj.refreshNavigation();
            obj.refreshViewers(true);
        end

        function onImageAdded(obj,e)
        %ONIMAGEADDED Apply the parent's existing calibration to newly imported inputs.

            % Active/target group supplying its owned images and bookmarks.
            group = oops.model.internal.resolve(obj.Project.Groups,e.GroupID);

            if isempty(group) || isempty(group.CalibrationIDs)
                return;
            end

            % Active image supplying data and object membership for this operation.
            image = oops.model.internal.resolve(group.Images,e.ImageID);
            oops.analysis.Analyzer.correctImage(image);
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
        %RUNANALYSIS Run one explicit stage with optional UI progress, using model targets.

            % Resolved image targets for the requested batch pipeline stage.
            images = obj.analysisTargets();

            if isempty(images)
                oops.Log.WARN("No images available for analysis.");
                return;
            end

            if stage == "Segment"

                % Initial progress-dialog message identifying segmentation or FPM analysis.
                message = "Segmenting images and detecting objects...";
            else
                message = "Calculating order and orientation statistics...";
            end

            % Operation progress dialog and its exception-safe cleanup guard.
            [progress,cleanupProgress] = obj.createProgressDialog(message); %#ok<ASGLU>

            obj.Processing = true;

            % Cleanup guard restoring the temporary callback/processing state.
            guard = onCleanup(@() obj.endProcessing());

            if stage == "Segment"
                oops.analysis.Analyzer.segmentImages(images,obj.Project.Settings,Progress=progress);
            else
                oops.analysis.Analyzer.analyzeImages(images,obj.Project.Settings,Progress=progress);
            end

            oops.analysis.updateProgress(progress,"Updating viewers...",[]);
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
                obj.refreshViewers(false);
            catch ME
                oops.Log.EXCEPTION(ME); % cleanup must preserve the original exception
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

        function deleteLabel(obj,labelID)
        %DELETELABEL Confirm removal and return affected objects to Unlabeled.

            label = obj.Project.Labels.getByID(labelID);

            if isempty(label)
                error('oops:app:UnknownLabel','The selected label no longer exists.');
            end

            answer = uiconfirm(obj.Fig, ...
                "Objects using this label will be reassigned to Unlabeled.", ...
                "Delete " + label.Name + "?", ...
                'Options',{'Delete','Cancel'},'DefaultOption','Cancel', ...
                'CancelOption','Cancel','Icon','warning');

            if strcmp(answer,'Delete')
                obj.Project.removeLabel(labelID);
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
                'Select four-angle inputs',char(obj.Project.Settings.IO.DefaultFolder),MultiSelect='on');
            % Native file dialogs can leave MATLAB behind other windows. Raise
            % this figure on return, including cancellation, and after loading.
            obj.focusWindow();

            % Cleanup guard returning focus to the visible GUI after loading completes.
            cleanupFocus = onCleanup(@() obj.focusWindow()); %#ok<NASGU>

            if isequal(files,0)
                return;
            end

            obj.Project.Settings.IO.DefaultFolder = string(folder);
            obj.addFiles(fullfile(folder,string(files)));
        end

        function loadSettings(obj)
        %LOADSETTINGS Apply saved defaults to the existing root, retaining subscriptions.

            % Settings tree loaded temporarily before copying values into the existing root.
            loaded = oops.config.Settings.load();

            % Cleanup guard releasing the temporary refresh/processing state.
            cleaner = onCleanup(@() delete(loaded));
            obj.Project.Settings.fromStruct(loaded.toStruct());
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

    end
end

function closeProgressDialog(progress)
%CLOSEPROGRESSDIALOG Release a dialog without masking an operation's exception.

    if ~isempty(progress) && isvalid(progress)
        close(progress);
    end

end
