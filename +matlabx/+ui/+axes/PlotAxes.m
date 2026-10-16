classdef PlotAxes < matlab.ui.componentcontainer.ComponentContainer
%PLOTAXES Stable axes host for transferable plot-content renderers.
%
% PlotAxes mirrors the host/content boundary used by ImageAxes without yet
% reproducing its complete event and tool systems. The host owns the axes,
% layout, and presentation state. A PlotContent object owns plot primitives
% and can move between PlotAxes hosts without reparenting this container.
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
% See also matlabx.ui.axes.PlotContent,
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

    % Read-only access to the mounted renderer and stable UIAxes.
    properties (Dependent, SetAccess=private)
        % Application-owned PlotContent currently mounted in this host.
        Content
        % Stable UIAxes used by renderers and future tools.
        Axes
    end

    % Graphics, listener, and content references owned by the host lifecycle.
    properties (Access=private, Transient, NonCopyable)
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
            catch ME
                % A failed refresh must not leave a half-mounted host/content pair.
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
            mounted.detach(obj);
            obj.resetAxes();
            notify(obj,'ContentChanged');
        end

        function routeEvent(obj,kind,event)
        %ROUTEEVENT Forward a normalized hub event to mounted content.

            if ~isempty(obj.Content_)
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
        %ONDOWN Forward a routed pointer-down event to mounted content.
            obj.routeEvent("Down",event);
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
        %ONENTER Forward a routed pointer-enter event to mounted content.
            obj.routeEvent("Enter",event);
        end

        function onLeave(obj,event)
        %ONLEAVE Forward a routed pointer-leave event to mounted content.
            obj.routeEvent("Leave",event);
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
            axes.XGrid = 'off';
            axes.YGrid = 'off';
            axes.ZGrid = 'off';
            axes.XMinorGrid = 'off';
            axes.YMinorGrid = 'off';
            axes.ZMinorGrid = 'off';
            axes.XMinorTick = 'off';
            axes.YMinorTick = 'off';
            axes.ZMinorTick = 'off';
            axes.XAxisLocation = 'bottom';
            axes.YAxisLocation = 'left';
            axes.Box = 'off';
            axes.TickDir = 'in';
            axes.View = [0 90];
            axes.NextPlot = 'add';
            axes.ColorOrderIndex = 1;

            obj.applyHostAppearance();
        end

        function delete(obj)
        %DELETE Unregister event routing and detach content before teardown.

            for k = 1:numel(obj)

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
            obj.MainAxes.Tag = char(obj.Name);

            fig = ancestor(obj.Parent,'figure');
            obj.Hub = matlabx.ui.interaction.FigureEventHub.ensure(fig);
            obj.RouterId = obj.Hub.register(obj,'Priority',10);

            % ComponentContainer can destroy children before the subclass delete
            % method runs. Detach at the axes destruction event while its owned
            % primitives can still be moved out of the graphics hierarchy.
            obj.AxesLifetimeListener = addlistener(obj.MainAxes, ...
                'ObjectBeingDestroyed', @(~,~) obj.clear());
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
        end

    end

end
