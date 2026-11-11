classdef PlotAxes < matlab.ui.componentcontainer.ComponentContainer
%PLOTAXES Stable axes host for transferable plot-content renderers.
%
% PlotAxes mirrors the host/content boundary and pluggable-tool conventions
% used by ImageAxes while retaining plot-specific collaborators. The host owns
% the axes, layout, presentation, toolbar, and context menu. A PlotContent
% object owns plot primitives and can move between PlotAxes hosts without
% reparenting this container.
%
% PlotAxes registers once with FigureEventHub and forwards normalized events
% to its mounted content. Keeping the axes stable gives the hub one durable
% registrant per panel, independent of the currently mounted renderer.
%
% Create a host, prepare renderer data and style, then mount the renderer:
%
%   fig = uifigure;
%   host = matlabx.ui.axes.PlotAxes(fig);
%   renderer = matlabx.ui.axes.plot.ScatterRenderer;
%   data = matlabx.ui.axes.plot.ScatterData( ...
%       XData={[1 2 3]}, YData={[2 1 4]}, SeriesNames="Samples", ...
%       CData={[0.2 0.5 0.8]});
%   renderer.update(data,matlabx.ui.axes.plot.ScatterStyle(Title="Example"));
%   host.mount(renderer);
%
% Content remains application-owned and reusable. clear detaches it without
% deleting it, and mounting the same content in another PlotAxes transfers it.
%
% See also matlabx.ui.axes.PlotContent, matlabx.ui.axes.PlotAxesTool,
% matlabx.ui.axes.PlotAxesToolManager,
% matlabx.ui.axes.PlotAxesContextMenuManager,
% matlabx.ui.axes.plot.ScatterRenderer,
% matlabx.ui.axes.plot.ViolinRenderer

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

    % Public host identity and appearance applied to the stable UIAxes.
    properties (AbortSet)
        % Identifier assigned to the underlying axes Tag.
        Name (1,1) string = ""
        % Foreground color used for rulers, labels, title, and subtitle.
        ForegroundColor (1,3) double = [0 0 0]
        % Font size applied to the underlying axes.
        FontSize (1,1) double {mustBePositive} = 12
    end

    % Configurable host UI and installed-tool state.
    properties (Dependent)
        % Installed PlotAxesTool objects; assignment replaces built-in tools.
        Tools
        % Built-in context-menu entries shown by the host.
        ContextMenuItems
        % Requested visibility of the axes toolbar.
        ToolbarVisible (1,1) matlab.lang.OnOffSwitchState
        % Visibility of the major Cartesian grid.
        GridVisible (1,1) matlab.lang.OnOffSwitchState
        % Visibility of the Cartesian axes box.
        BoxVisible (1,1) matlab.lang.OnOffSwitchState
    end

    % Read-only access to the mounted renderer and stable UIAxes.
    properties (Dependent, SetAccess=private)
        % Application-owned PlotContent currently mounted in this host.
        Content
        % Stable UIAxes used by renderers and future tools.
        Axes
    end

    % Graphics, listener, and content references owned by the host lifecycle.
    properties (Access={?matlabx.ui.axes.PlotAxesTool, ...
            ?matlabx.ui.axes.PlotAxesToolManager}, Transient, NonCopyable)
        % Grid containing the stable axes.
        Grid matlab.ui.container.GridLayout
        % UIAxes retained while renderer content changes.
        MainAxes matlab.ui.control.UIAxes
        % Listener that detaches content before axes graphics are destroyed.
        AxesLifetimeListener event.listener = event.listener.empty()
        % Backing reference for the currently mounted content.
        Content_ (:,1) matlabx.ui.axes.PlotContent = matlabx.ui.axes.PlotContent.empty(0,1)
        % Shared figure event router used by this stable host.
        Hub matlabx.ui.interaction.FigureEventHub
        % Registration identifier assigned by FigureEventHub.
        RouterId double = NaN
        % Tool lifecycle, toolbar, context-menu, and hotkey collaborators.
        ToolManager matlabx.ui.axes.PlotAxesToolManager
        HotkeyRegistry matlabx.ui.axes.PlotAxesHotkeyRegistry
        ContextMenuManager matlabx.ui.axes.PlotAxesContextMenuManager
        % Toolbar buttons keyed by installed tool name.
        ToolbarButtons struct = struct()
        % Currently enabled exclusive tool, when present.
        ActiveExclusiveTool = []
        % Status report window owned by this host.
        StatusWindow matlabx.app.TextWindow
    end

    properties (Access=private, AbortSet)
        % Backing built-in context-menu configuration.
        ContextMenuItems_ (1,:) string = ["Display","ResetView","Status"]
        % Backing requested toolbar visibility.
        ToolbarVisible_ (1,1) matlab.lang.OnOffSwitchState = "on"
        % Backing major-grid visibility.
        GridVisible_ (1,1) matlab.lang.OnOffSwitchState = "off"
        % Backing axes-box visibility.
        BoxVisible_ (1,1) matlab.lang.OnOffSwitchState = "off"
        % Whether the status report window is currently open.
        StatusWindowOpen_ (1,1) logical = false
        % Whether tool teardown has already run for this host.
        ToolsTornDown_ (1,1) logical = false
    end

    % Notifications emitted when the mounted content relationship changes.
    events
        % Emitted after content is mounted, transferred, or cleared.
        ContentChanged
    end

    methods

        function content = get.Content(obj)
        %GET.CONTENT Return the renderer currently mounted in this host.

            content = obj.Content_;
        end

        function axes = get.Axes(obj)
        %GET.AXES Expose the stable target axes to renderers and future tools.

            axes = obj.MainAxes;
        end

        function tools = get.Tools(obj)
        %GET.TOOLS Return installed PlotAxesTool objects keyed by name.
            tools = obj.ToolManager.Tools;
        end

        function set.Tools(obj,toolNames)
        %SET.TOOLS Replace the installed set of manager-owned built-in tools.
            obj.ToolManager.setInstalledNames(toolNames);
        end

        function items = get.ContextMenuItems(obj)
        %GET.CONTEXTMENUITEMS Return configured built-in menu tokens.
            items = obj.ContextMenuItems_;
        end

        function set.ContextMenuItems(obj,items)
        %SET.CONTEXTMENUITEMS Validate and rebuild the built-in context menu.
            items = matlabx.ui.axes.PlotAxesContextMenuManager.validateBuiltinItems(items);
            obj.ContextMenuItems_ = items;
            if ~isempty(obj.ContextMenuManager) && isvalid(obj.ContextMenuManager)
                obj.ContextMenuManager.setBuiltinItems(items);
            end
        end

        function value = get.ToolbarVisible(obj)
        %GET.TOOLBARVISIBLE Return requested toolbar visibility.
            value = obj.ToolbarVisible_;
        end

        function set.ToolbarVisible(obj,value)
        %SET.TOOLBARVISIBLE Show or hide the hosted axes toolbar.
            obj.ToolbarVisible_ = value;
            if ~isempty(obj.MainAxes) && isvalid(obj.MainAxes) && ...
                    ~isempty(obj.MainAxes.Toolbar) && isvalid(obj.MainAxes.Toolbar)
                obj.MainAxes.Toolbar.Visible = value;
            end
            obj.refreshContextMenu();
        end

        function value = get.GridVisible(obj)
        %GET.GRIDVISIBLE Return major-grid visibility.
            value = obj.GridVisible_;
        end

        function set.GridVisible(obj,value)
        %SET.GRIDVISIBLE Show or hide both major Cartesian grid directions.
            obj.GridVisible_ = value;
            if ~isempty(obj.MainAxes) && isvalid(obj.MainAxes)
                obj.MainAxes.XGrid = value;
                obj.MainAxes.YGrid = value;
            end
            obj.refreshContextMenu();
        end

        function value = get.BoxVisible(obj)
        %GET.BOXVISIBLE Return axes-box visibility.
            value = obj.BoxVisible_;
        end

        function set.BoxVisible(obj,value)
        %SET.BOXVISIBLE Show or hide the Cartesian axes box.
            obj.BoxVisible_ = value;
            if ~isempty(obj.MainAxes) && isvalid(obj.MainAxes)
                obj.MainAxes.Box = value;
            end
            obj.refreshContextMenu();
        end

        function installTool(obj,toolOrName)
        %INSTALLTOOL Install a built-in name or application-owned PlotAxesTool.
            if ~(isa(toolOrName,'matlabx.ui.axes.PlotAxesTool'))
                name = string(toolOrName);
                if isempty(obj.ToolManager.getLoaded(name))
                    obj.ToolManager.load(name);
                end
            end
            obj.ToolManager.install(toolOrName);
        end

        function uninstallTool(obj,toolOrName)
        %UNINSTALLTOOL Remove tool contributions without deleting borrowed tools.
            obj.ToolManager.uninstall(toolOrName);
        end

        function tool = getInstalledTool(obj,name)
        %GETINSTALLEDTOOL Return an installed PlotAxesTool by name.
            tool = obj.ToolManager.getInstalled(name);
        end

        function registerTool(obj,tool)
        %REGISTERTOOL Register a PlotAxesTool and construct its contributions.
            obj.ToolManager.register(tool);
        end

        function unregisterTool(obj,tool)
        %UNREGISTERTOOL Remove one tool's host-owned contributions.
            obj.ToolManager.unregister(tool);
        end

        function registerToolHotkeys(obj,tool)
        %REGISTERTOOLHOTKEYS Register one tool's optional toggle hotkey.
            if strlength(tool.ToggleHotkey) == 0, return; end
            obj.HotkeyRegistry.add(tool.ToggleHotkey, ...
                @(E) obj.onToolToggleHotkey(tool.Name,E), ...
                Owner=tool,Description=tool.Name + " toggle", ...
                Priority=tool.Priority);
        end

        function disableActiveExclusive(obj)
        %DISABLEACTIVEEXCLUSIVE Disable the currently enabled exclusive tool.
            obj.ToolManager.disableActiveExclusive();
        end

        function onToolPush(obj,name)
        %ONTOOLPUSH Run the push tool associated with a toolbar button.
            obj.ToolManager.push(name);
        end

        function onToolToggle(obj,value,name)
        %ONTOOLTOGGLE Apply a toolbar state-button change to its tool.
            obj.ToolManager.toggle(logical(value),name);
        end

        function onToolToggleHotkey(obj,name,event)
        %ONTOOLTOGGLEHOTKEY Run or toggle a tool from its registered hotkey.
            tool = obj.getInstalledTool(name);
            if isempty(tool), return; end
            event.stop();
            if strcmp(tool.Style,'push')
                obj.ToolManager.run(name);
            elseif tool.Enabled
                obj.ToolManager.disable(name);
            else
                obj.ToolManager.enable(name);
            end
        end

        function resetView(obj)
        %RESETVIEW Restore the mounted renderer's intended presentation.
        %   The host baseline is restored first so presentation left by user
        %   navigation or axes interaction cannot leak into the refreshed
        %   renderer. The renderer then reapplies its stored data and style,
        %   including deliberate limits such as violin category margins.
            obj.resetAxes();
            if ~isempty(obj.Content_) && isvalid(obj.Content_)
                obj.Content_.refresh();
            end
        end

        function toggleToolbar(obj)
        %TOGGLETOOLBAR Toggle the requested toolbar visibility.
            obj.ToolbarVisible = ~logical(obj.ToolbarVisible);
        end

        function toggleGrid(obj)
        %TOGGLEGRID Toggle both major Cartesian grid directions.
            obj.GridVisible = ~logical(obj.GridVisible);
        end

        function toggleBox(obj)
        %TOGGLEBOX Toggle the axes box.
            obj.BoxVisible = ~logical(obj.BoxVisible);
        end

        function S = getStatusSummary(obj)
        %GETSTATUSSUMMARY Return a compact host/content/tool status report.
            contentClass = "";
            if ~isempty(obj.Content_), contentClass = string(class(obj.Content_)); end
            S = struct( ...
                "Name",obj.Name, ...
                "ContentClass",contentClass, ...
                "XLim",obj.MainAxes.XLim, ...
                "YLim",obj.MainAxes.YLim, ...
                "XScale",string(obj.MainAxes.XScale), ...
                "YScale",string(obj.MainAxes.YScale), ...
                "ToolbarVisible",string(obj.ToolbarVisible), ...
                "GridVisible",string(obj.GridVisible), ...
                "BoxVisible",string(obj.BoxVisible), ...
                "Tools",string(fieldnames(obj.Tools)).');
        end

        function openStatusWindow(obj)
        %OPENSTATUSWINDOW Open the PlotAxes operational status report.
            if obj.StatusWindowOpen_ && ~isempty(obj.StatusWindow) && ...
                    isvalid(obj.StatusWindow)
                return
            end
            lines = cellstr(matlabx.struct.prettyPrint( ...
                obj.getStatusSummary(),StringArrayStyle="lines"));
            obj.StatusWindow = matlabx.app.TextWindow( ...
                Title="PlotAxes Status",Text=lines, ...
                ClosedFcn=@(~,~) obj.onStatusWindowClosed_());
            obj.StatusWindowOpen_ = true;
        end

        function exportPlot(obj,filename,opts)
        %EXPORTPLOT Export the assembled plot axes as vector or raster graphics.
            arguments
                obj (1,1) matlabx.ui.axes.PlotAxes
                filename (1,1) string {mustBeNonzeroLengthText}
                opts.ContentType (1,1) string {mustBeMember(opts.ContentType, ...
                    ["auto","vector","image"])} = "auto"
                opts.BackgroundColor = obj.BackgroundColor
                opts.Resolution (1,1) double {mustBePositive} = 300
            end
            exportgraphics(obj.MainAxes,filename, ...
                ContentType=opts.ContentType, ...
                BackgroundColor=opts.BackgroundColor, ...
                Resolution=opts.Resolution);
        end

        function filename = chooseExportPlot(obj)
        %CHOOSEEXPORTPLOT Choose a vector or raster file and export the plot.
            filename = "";
            [file,path,filterIndex] = uiputfile( ...
                {'*.pdf','PDF vector graphics (*.pdf)'; ...
                 '*.svg','SVG vector graphics (*.svg)'; ...
                 '*.png','PNG raster image (*.png)'; ...
                 '*.tif;*.tiff','TIFF raster image (*.tif, *.tiff)'}, ...
                'Export Plot','plot.pdf');
            if isequal(file,0), return; end
            [~,~,extension] = fileparts(file);
            if isempty(extension)
                extensions = [".pdf",".svg",".png",".tif"];
                file = char(string(file) + extensions(filterIndex));
            end
            filename = string(fullfile(path,file));
            [~,~,extension] = fileparts(filename);
            extension = lower(string(extension));
            contentType = "image";
            if any(extension == [".pdf",".svg"]), contentType = "vector"; end
            obj.exportPlot(filename,ContentType=contentType);
        end

        function copyPlot(obj,opts)
        %COPYPLOT Copy the assembled plot to the system clipboard.
            arguments
                obj (1,1) matlabx.ui.axes.PlotAxes
                opts.ContentType (1,1) string {mustBeMember(opts.ContentType, ...
                    ["auto","vector","image"])} = "vector"
                opts.BackgroundColor = obj.BackgroundColor
            end
            copygraphics(obj.MainAxes,ContentType=opts.ContentType, ...
                BackgroundColor=opts.BackgroundColor);
        end

        function mount(obj,content)
        %MOUNT Transfer one renderer into this host and render its stored state.

            validateattributes(content,{'matlabx.ui.axes.PlotContent'},{'scalar'});

            if ~isempty(obj.Content_) && obj.Content_ == content
                content.refresh();
                return;
            end

            obj.clear();

            % Remove axes presentation left by the previous renderer. Graphics
            % primitives are preserved because their renderer may be mounted
            % in this or another host again later.
            obj.resetAxes();

            % A renderer has one host. Release the previous host before moving
            % primitives; neither ComponentContainer changes layout parents.
            if ~isempty(content.Host) && isvalid(content.Host)
                content.Host.clear(content);
            end

            obj.Content_ = content;

            try
                content.attach(obj);
                % Content-specific commands share the host menu but remain
                % scoped to the mounted content's lifecycle.
                content.contributeContextMenu(obj.ContextMenuManager);
            catch ME
                % A failed refresh must not leave a half-mounted host/content pair.
                obj.ContextMenuManager.removeOwner(content);
                obj.clear(content);
                rethrow(ME);
            end
            notify(obj,'ContentChanged');
        end

        function clear(obj,content)
        %CLEAR Detach mounted content, optionally only when it matches CONTENT.

            if isempty(obj.Content_)
                return;
            end

            if nargin > 1 && obj.Content_ ~= content
                return;
            end

            mounted = obj.Content_;
            obj.Content_ = matlabx.ui.axes.PlotContent.empty(0,1);
            % Remove callbacks which retain the content before detaching it.
            obj.ContextMenuManager.removeOwner(mounted);
            mounted.detach(obj);
            obj.resetAxes();
            notify(obj,'ContentChanged');
        end

        function routeEvent(obj,kind,event)
        %ROUTEEVENT Route tools first, then unconsumed events to content.
            kind = string(kind);
            if kind == "KeyPress"
                obj.HotkeyRegistry.dispatch(event);
                if event.StopPropagation, return; end
            end

            passive = obj.ToolManager.getPriorityPassiveInterceptors(kind);
            for i = 1:numel(passive)
                passive{i}.("onPassive" + kind)(event);
                if event.StopPropagation, return; end
            end

            tool = obj.ToolManager.getPriorityInterceptor(kind);
            if ~isempty(tool)
                tool.("on" + kind)(event);
                if event.StopPropagation, return; end
            end

            if ~isempty(obj.Content_) && isvalid(obj.Content_)
                obj.Content_.handleEvent(string(kind),event);
            end
        end

        function tf = matches(obj,event)
        %MATCHES Return whether a routed event belongs to the stable UIAxes.
            tf = false;
            target = event.Target;
            if isempty(target)
                return;
            end

            % Data-tip interaction can make hittest return internal opaque
            % graphics objects. They support neither isvalid nor every normal
            % handle operation, so keep the entire ancestry query guarded.
            try
                if isequal(target,obj.MainAxes)
                    tf = true;
                    return;
                end
                axes = ancestor(target,'matlab.ui.control.UIAxes');
                tf = ~isempty(axes) && isequal(axes,obj.MainAxes);
            catch
            end
        end

        function onDown(obj,event)
        %ONDOWN Route a pointer-down event and open an unclaimed host menu.
            obj.routeEvent("Down",event);
            if ~event.StopPropagation && event.MouseChord == "contextclick"
                obj.ContextMenuManager.openAt(event.CurrentPointFigure);
            end
        end

        function onMove(obj,event)
        %ONMOVE Forward a routed pointer-move event to mounted content.
            obj.routeEvent("Move",event);
        end

        function onUp(obj,event)
        %ONUP Forward a routed pointer-up event to mounted content.
            obj.routeEvent("Up",event);
        end

        function onScroll(obj,event)
        %ONSCROLL Forward a routed scroll event to mounted content.
            obj.routeEvent("Scroll",event);
        end

        function onKeyPress(obj,event)
        %ONKEYPRESS Forward a routed key-press event to mounted content.
            obj.routeEvent("KeyPress",event);
        end

        function onKeyRelease(obj,event)
        %ONKEYRELEASE Forward a routed key-release event to mounted content.
            obj.routeEvent("KeyRelease",event);
        end

        function onEnter(obj,event)
        %ONENTER Notify installed tools and mounted content.
            obj.ToolManager.notifyHostEnter(event);
            if ~isempty(obj.Content_) && isvalid(obj.Content_)
                obj.Content_.handleEvent("Enter",event);
            end
        end

        function onLeave(obj,event)
        %ONLEAVE Notify installed tools and mounted content.
            obj.ToolManager.notifyHostLeave(event);
            if ~isempty(obj.Content_) && isvalid(obj.Content_)
                obj.Content_.handleEvent("Leave",event);
            end
        end

        function resetAxes(obj)
        %RESETAXES Restore predictable presentation without deleting graphics.
        % Renderers own semantic axes presentation, including ticks, limits,
        % labels, scales, grids, and view. This neutral baseline prevents one
        % renderer's choices from leaking into the next renderer mounted here.

            axes = obj.MainAxes;

            if isempty(axes) || ~isvalid(axes) || axes.BeingDeleted == "on"
                return;
            end

            % Remove annotations and axes-specific helpers created for the
            % outgoing presentation while retaining renderer-owned primitives.
            legend(axes,'off');
            colorbar(axes,'off');
            axes.Title.String = '';
            axes.Subtitle.String = '';
            axes.XLabel.String = '';
            axes.YLabel.String = '';
            axes.ZLabel.String = '';

            % Restore automatic Cartesian dimensions and tick generation.
            axes.XScale = 'linear';
            axes.YScale = 'linear';
            axes.ZScale = 'linear';
            axes.XDir = 'normal';
            axes.YDir = 'normal';
            axes.ZDir = 'normal';
            axes.XLimMode = 'auto';
            axes.YLimMode = 'auto';
            axes.ZLimMode = 'auto';
            axes.XTickMode = 'auto';
            axes.YTickMode = 'auto';
            axes.ZTickMode = 'auto';
            axes.XTickLabelMode = 'auto';
            axes.YTickLabelMode = 'auto';
            axes.ZTickLabelMode = 'auto';
            axes.XAxis.Visible = 'on';
            axes.YAxis.Visible = 'on';
            axes.ZAxis.Visible = 'off';

            % Restore general layout properties that plot types commonly alter.
            axes.DataAspectRatioMode = 'auto';
            axes.PlotBoxAspectRatioMode = 'auto';
            axes.CLimMode = 'auto';
            axes.XGrid = obj.GridVisible_;
            axes.YGrid = obj.GridVisible_;
            axes.ZGrid = 'off';
            axes.XMinorGrid = 'off';
            axes.YMinorGrid = 'off';
            axes.ZMinorGrid = 'off';
            axes.XMinorTick = 'off';
            axes.YMinorTick = 'off';
            axes.ZMinorTick = 'off';
            axes.XAxisLocation = 'bottom';
            axes.YAxisLocation = 'left';
            axes.Box = obj.BoxVisible_;
            axes.TickDir = 'in';
            axes.View = [0 90];
            axes.NextPlot = 'add';
            axes.ColorOrderIndex = 1;

            obj.applyHostAppearance();
        end

        function delete(obj)
        %DELETE Unregister event routing and detach content before teardown.

            for k = 1:numel(obj)

                obj(k).teardownTools_();

                try
                    if ~isempty(obj(k).Hub) && isvalid(obj(k).Hub) && ...
                            ~isnan(obj(k).RouterId)
                        obj(k).Hub.unregister(obj(k).RouterId);
                    end
                catch
                end

                if ~isempty(obj(k).Content_)
                    obj(k).clear();
                end

            end
        end

    end

    methods (Static)

        function names = getToolNames()
        %GETTOOLNAMES Return short names of built-in PlotAxes tools.
            namespace = matlab.metadata.Namespace.fromName( ...
                "matlabx.ui.axes.tools.plot");
            if isempty(namespace)
                names = {};
                return
            end
            classes = {namespace.ClassList.Name};
            names = cell(size(classes));
            for i = 1:numel(classes)
                parts = split(string(classes{i}),'.');
                names{i} = char(parts(end));
            end
        end

        function names = getDefaultTools()
        %GETDEFAULTTOOLS Return built-in tools installed on new PlotAxes hosts.
            names = {'Export','CopyGraphics'};
        end

        function [hosts,renderers,fig] = demo(opts)
        %DEMO Show transferable scatter and violin content in two stable hosts.
        %   hosts.Second.mount(renderers.Scatter) transfers the same renderer
        %   and primitive handles, leaving hosts.First empty. The displaced
        %   renderers.Violin remains available for mounting again.

            arguments
                opts.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
            end

            fig = uifigure('Name','Transferable Plot Content','Visible','off');
            grid = uigridlayout(fig,[1 2]);
            hosts.First = matlabx.ui.axes.PlotAxes(grid);
            hosts.Second = matlabx.ui.axes.PlotAxes(grid);
            renderers.Scatter = matlabx.ui.axes.plot.ScatterRenderer();
            renderers.Violin = matlabx.ui.axes.plot.ViolinRenderer();
            x = linspace(0,2*pi,40);
            renderers.Scatter.update(matlabx.ui.axes.plot.ScatterData( ...
                XData={x},YData={sin(x)},SeriesNames="Sine",CData={[0.2 0.5 0.8]}), ...
                matlabx.ui.axes.plot.ScatterStyle(Title="Scatter",XLabel="x",YLabel="sin(x)"));
            renderers.Violin.update(matlabx.ui.axes.plot.ViolinData( ...
                Values={sin(x),cos(x)+1},SeriesNames=["A" "B"], ...
                CData={[0.2 0.5 0.8],[0.8 0.4 0.2]}), ...
                matlabx.ui.axes.plot.ViolinStyle(Title="Distributions",YLabel="Value"));
            hosts.First.mount(renderers.Scatter);
            hosts.Second.mount(renderers.Violin);
            movegui(fig,"center");
            fig.Visible = opts.Visible;
        end

    end

    methods (Access=protected)

        function setup(obj)
        %SETUP Create the stable layout and UIAxes owned by this host.

            obj.Grid = uigridlayout(obj,[1 1], ...
                'ColumnWidth',{'1x'},'RowHeight',{'1x'}, ...
                'Padding',0,'BackgroundColor',obj.BackgroundColor);

            obj.MainAxes = uiaxes(obj.Grid, ...
                'Box','off','NextPlot','add','TickDir','in', ...
                'FontSize',obj.FontSize,'Color',obj.BackgroundColor, ...
                'XColor',obj.ForegroundColor,'YColor',obj.ForegroundColor);
            obj.MainAxes.Layout.Row = 1;
            obj.MainAxes.Layout.Column = 1;
            obj.MainAxes.Interactions = dataTipInteraction;
            obj.MainAxes.Toolbar = axtoolbar(obj.MainAxes,{});
            obj.MainAxes.Toolbar.Visible = obj.ToolbarVisible_;
            obj.MainAxes.Tag = char(obj.Name);

            obj.ToolManager = matlabx.ui.axes.PlotAxesToolManager(obj);
            obj.HotkeyRegistry = matlabx.ui.axes.PlotAxesHotkeyRegistry();

            fig = ancestor(obj.Parent,'figure');
            obj.ContextMenuManager = ...
                matlabx.ui.axes.PlotAxesContextMenuManager(obj,fig);
            obj.ContextMenuManager.setBuiltinItems(obj.ContextMenuItems_);
            obj.MainAxes.ContextMenu = obj.ContextMenuManager.Menu;
            obj.ToolManager.setInstalledNames(obj.getDefaultTools());

            obj.Hub = matlabx.ui.interaction.FigureEventHub.ensure(fig);
            obj.RouterId = obj.Hub.register(obj,'Priority',10);

            % ComponentContainer can destroy children before the subclass delete
            % method runs. Detach at the axes destruction event while its owned
            % primitives can still be moved out of the graphics hierarchy.
            obj.AxesLifetimeListener = addlistener(obj.MainAxes, ...
                'ObjectBeingDestroyed', @(~,~) obj.teardownAxes_());
        end

        function update(obj)
        %UPDATE Apply host-owned presentation without touching renderer graphics.

            if isempty(obj.MainAxes) || ~isvalid(obj.MainAxes)
                return;
            end

            obj.applyHostAppearance();
            obj.MainAxes.Tag = char(obj.Name);
        end

    end

    methods (Access=private)

        function applyHostAppearance(obj)
        %APPLYHOSTAPPEARANCE Restore colors and typography owned by PlotAxes.
            if isempty(obj.MainAxes) || ~isvalid(obj.MainAxes) || ...
                    obj.MainAxes.BeingDeleted == "on"
                return;
            end

            obj.Grid.BackgroundColor = obj.BackgroundColor;
            obj.MainAxes.Color = obj.BackgroundColor;
            obj.MainAxes.XColor = obj.ForegroundColor;
            obj.MainAxes.YColor = obj.ForegroundColor;
            obj.MainAxes.ZColor = obj.ForegroundColor;
            obj.MainAxes.XLabel.Color = obj.ForegroundColor;
            obj.MainAxes.YLabel.Color = obj.ForegroundColor;
            obj.MainAxes.ZLabel.Color = obj.ForegroundColor;
            obj.MainAxes.Title.Color = obj.ForegroundColor;
            obj.MainAxes.Subtitle.Color = obj.ForegroundColor;
            obj.MainAxes.FontSize = obj.FontSize;
            obj.MainAxes.XGrid = obj.GridVisible_;
            obj.MainAxes.YGrid = obj.GridVisible_;
            obj.MainAxes.Box = obj.BoxVisible_;
            if ~isempty(obj.MainAxes.Toolbar) && isvalid(obj.MainAxes.Toolbar)
                obj.MainAxes.Toolbar.Visible = obj.ToolbarVisible_;
            end
        end

        function refreshContextMenu(obj)
        %REFRESHCONTEXTMENU Refresh dynamic menu state when available.
            if ~isempty(obj.ContextMenuManager) && isvalid(obj.ContextMenuManager)
                obj.ContextMenuManager.refresh();
            end
        end

        function onStatusWindowClosed_(obj)
        %ONSTATUSWINDOWCLOSED_ Clear status-window ownership state.
            obj.StatusWindowOpen_ = false;
        end

        function teardownAxes_(obj)
        %TEARDOWNAXES_ Detach content and tools before axes graphics disappear.
            if ~isempty(obj.Content_)
                obj.clear();
            end
            obj.teardownTools_();
        end

        function teardownTools_(obj)
        %TEARDOWNTOOLS_ Uninstall borrowed tools and delete manager-owned tools.
            if obj.ToolsTornDown_, return; end
            obj.ToolsTornDown_ = true;
            if isempty(obj.ToolManager) || ~isvalid(obj.ToolManager), return; end
            obj.ToolManager.uninstallAll();
            obj.ToolManager.unloadAll();
        end

    end

end
