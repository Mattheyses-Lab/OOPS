classdef ImageAxes < matlab.ui.componentcontainer.ComponentContainer
%IMAGEAXES Image5D-backed UI image display and interaction component.
%
%   matlabx.ui.axes.ImageAxes displays a selected 2-D plane or RGB
%   composite from a matlabx.image.Image5D object. It also hosts
%   AxesTool subclasses and receives figure-level mouse/key events
%   through matlabx.ui.interaction.FigureEventHub.
%
%   Create an ImageAxes in a UI figure and assign a MATLAB image array:
%
%       fig = uifigure;
%       ax = matlabx.ui.axes.ImageAxes(fig);
%       ax.CData = imread("peppers.png");
%
%   For multidimensional or multicomponent data, assign an Image5D and select
%   the displayed component, Z plane, and time point through C, Z, and T:
%
%       imageData = matlabx.image.Image5D.fromComponents({I1,I2});
%       ax.ImageData = imageData;
%       ax.C = 2;
%       ax.Z = 1;
%       ax.T = 1;
%
%   Properties can also be supplied during construction. Tools may be named
%   built-ins or application-owned AxesTool instances installed afterward:
%
%       ax = matlabx.ui.axes.ImageAxes(fig, ...
%           "CData", I, ...
%           "Tools", ["Zoom","RectangleSelect"]);
%       ax.installTool(myapp.ui.axes.CustomTool(ax));
%
%   Data terminology
%   ----------------
%   ImageData      Canonical source image object. Prefer this for new code.
%   RenderSource   Current selected source plane or computed RGB composite.
%   DisplayCData   Graphics-ready data assigned to the MATLAB image object.
%                  Scalar RenderSource data are contrast-rescaled here.
%   CData          Compatibility alias for setting ImageData from raw MATLAB
%                  image arrays/cells. New code should prefer ImageData.
%
%   Notes
%   -----
%   If multiple ImageAxes instances share a figure, give each a unique Name
%   so figure-event hit testing can distinguish their axes/toolbars.
%
%   Per-component display API
%   -------------------------
%   CLim and Colormap are current-component convenience properties:
%
%       ax.CLim = [low high]
%       ax.Colormap = hot(256)
%
%   ComponentCLims, ComponentColors, and ComponentColormaps are full-state
%   cell-array properties with one entry per component. They update stored
%   display state without changing ComponentColorMode, which makes them useful
%   for restoring saved display state, preloading colors/LUTs, or linking axes:
%
%       ax.ComponentCLims = {[0 100], [0 200]}
%
%   For targeted edits, prefer the helper methods. With no index they update
%   the current component; with a scalar or vector index they apply the same
%   value to those components. setComponentColor activates color mode, and
%   setComponentColormap activates LUT mode:
%
%       ax.setComponentCLim([0 100])
%       ax.setComponentCLim([0 100], [1 3])
%       ax.setComponentColormap(gray(256), 2)
%       ax.setComponentColor("cyan", [1 2])
%
%   Tools API
%   ---------
%   Tools is intentionally asymmetric. Assign a string array or cellstr to
%   choose installed tools. Read Tools to access the installed tool objects:
%
%       ax.Tools = ["Zoom","Box","DrawRectangle"]
%       ax.Tools.Box.BoxSize = 40
%
%   Context menus
%   -------------
%   ImageAxes owns the context menu assigned to its inherited ContextMenu
%   property. Setting ContextMenu directly is not recommended because it
%   bypasses the built-in menu, dynamic state refresh, and tool cleanup.
%   Choose built-in entries with ContextMenuItems. Application tools can add
%   entries by overriding AxesTool.contributeContextMenu and using the supplied
%   ImageAxesContextMenuManager:
%
%       function contributeContextMenu(obj, menu)
%           menu.addItem("MyTool.Action", "Run action", ...
%               @(~,~) obj.runAction(), Owner=obj);
%       end
%
%   Install the tool normally with installTool; its owner-scoped menu entries
%   are then removed automatically when the tool is uninstalled.
%
%   See also matlabx.image.Image5D, matlabx.app.quickshow,
%   matlabx.ui.axes.AxesTool, matlabx.ui.axes.ImageAxesToolManager,
%   matlabx.ui.axes.ImageAxesHotkeyRegistry,
%   matlabx.ui.axes.ImageAxesContextMenuManager,
%   matlabx.ui.axes.ImageAxesOverlayManager,
%   matlabx.ui.axes.ImageAxesOverlay, matlabx.ui.axes.ImageAxesOverlayContent,
%   matlabx.ui.axes.ImageAxesOverlayMount,
%   matlabx.ui.axes.ImageAxesDisplayRenderer,
%   matlabx.ui.axes.ImageAxesComponentDisplayState,
%   matlabx.ui.axes.ImageAxesViewState, matlabx.ui.axes.ImageAxesResizeLayout,
%   matlabx.ui.axes.ImageAxesLinkManager,
%   matlabx.ui.interaction.FigureEventHub, matlabx.ui.interaction.HubEvent

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

    %% Tool and native overlay integration

    % Public access to installed tools and the native overlay registry.
    properties (Dependent)
        % Assign names to install tools; read back installed tool objects.
        Tools
        % Overlay manager for image-space annotations and visual aids.
        Overlays
    end

    % Collaborators used by the tool manager to register tools and hotkeys.
    properties (Access={?matlabx.ui.axes.ImageAxesToolManager})
        % manager for tool lifecycle, routing lookup, and installed tool objects
        ToolManager matlabx.ui.axes.ImageAxesToolManager
        % registry of host/tool hotkeys
        HotkeyRegistry matlabx.ui.axes.ImageAxesHotkeyRegistry
    end

    % Shared tool state accessible to AxesTool and ImageAxesToolManager.
    properties (Access={?matlabx.ui.axes.AxesTool, ?matlabx.ui.axes.ImageAxesToolManager})
        % the currently enabled tool with IsExclusive=true (if it exists)
        ActiveExclusiveTool
        % struct() of ToolbarButtons, fieldnames match tool Name
        ToolbarButtons struct = struct()
    end

    %% Public configuration
    % Public host identity used by graphics and event routing.
    properties (AbortSet)
        % Identifier used to tag hosted axes for event hit testing.
        Name (1,1) string = ""
    end

    % Configurable host UI presentation properties.
    properties (Dependent, AbortSet)
        % ImageAxes built-in context menu items to show.
        ContextMenuItems
        % Whether the viewport overview graphics are visible.
        ViewportBoxVisible (1,1) matlab.lang.OnOffSwitchState
        % Whether the axes toolbar is visible.
        ToolbarVisible (1,1) matlab.lang.OnOffSwitchState
    end

    % Passthrough properties for hosted MATLAB graphics.
    properties (Dependent)
        % Visibility of the rendered image primitive.
        ImageVisible
        % Visibility of the primary hosted UIAxes.
        AxesVisible
        % Visibility of the hosted colorbar.
        ColorbarVisible
        % Effective display map for the current component.
        Colormap (256,3) double
        % Maximum rendered resolution passed to the image primitive.
        MaxRenderedResolution
    end

    %% Image model, render state, and display state

    % Canonical image input and raw-array compatibility input.
    properties (Dependent, AbortSet)
        % Canonical multidimensional image model displayed by this component.
        ImageData           (1,1) matlabx.image.Image5D
        % Raw-array compatibility input and current render-source output.
        CData               {mustBeA(CData,{'double','single','uint8','uint16','logical','cell'})}
    end

    % Observable view selection and image display controls.
    properties (Dependent, AbortSet, SetObservable)
        % One-based component index currently selected for display.
        C (1,1) double
        % One-based Z-plane index currently selected for display.
        Z (1,1) double
        % One-based time-point index currently selected for display.
        T (1,1) double
        % Optional logical Y-by-X display mask; cleared when image data changes.
        Mask
        % Whether the stored image mask affects rendering.
        MaskEnabled         (1,1) matlab.lang.OnOffSwitchState
        % Global visibility switch for native managed overlays.
        OverlaysVisible     (1,1) matlab.lang.OnOffSwitchState
        % Whether mergeable components are rendered as an RGB composite.
        ShowComposite       (1,1) matlab.lang.OnOffSwitchState
        % Display limits for the current scalar component.
        CLim                (1,2) double
        % Whether component display limits are automatic or manual.
        CLimMode            (1,:) char {mustBeMember(CLimMode,{'auto','manual'})}
        % Stored display limits for every image component.
        ComponentCLims      (1,:) cell
        % Stored display color for every image component.
        ComponentColors     (1,:) cell
        % Stored colormap for every image component.
        ComponentColormaps  (1,:) cell
        % Whether components use solid colors or colormap LUTs.
        ComponentColorMode  (1,:) char {mustBeMember(ComponentColorMode,{'colors','luts'})}
    end

    % Read-only information about the current rendered image state.
    properties (Dependent, SetAccess=private)
        % Selected source plane or generated RGB composite before display mapping.
        RenderSource
        % Whether RenderSource is scalar or RGB data.
        RenderSourceKind       (1,:) char {mustBeMember(RenderSourceKind,{'scalar','rgb'})}
        % Spatial size of the current render source.
        RenderSourceSize       (1,:) double
        % MATLAB numeric class of the current render source.
        RenderSourceClass      (1,:) char {mustBeMember(RenderSourceClass,{'double','single','uint8','uint16','logical',''})}
        % Graphics-ready data assigned to the image primitive.
        DisplayCData
        % Whether current components can form a composite image.
        CanMergeComponents  (1,1) logical

        % Compatibility aliases for RenderSource* metadata.
        CDataKind       (1,:) char {mustBeMember(CDataKind,{'scalar','rgb'})}
        % Compatibility alias for RenderSourceSize.
        CDataSize       (1,:) double
        % Compatibility alias for RenderSourceClass.
        CDataClass      (1,:) char {mustBeMember(CDataClass,{'double','single','uint8','uint16','logical',''})}
        
        % Number of components in ImageData.
        NumComponents         (1,1) double
        % Whether ImageData contains more than one component.
        MultiComponent        (1,1) matlab.lang.OnOffSwitchState
        % Aggregate scalar/RGB kind of the image components.
        MultiComponentKind    (1,:) {mustBeMember(MultiComponentKind,{'scalar','rgb','mixed','none'})}
    end

    % Private canonical image, view, mask, and component display state.
    properties (Access=private)
        % Current view coordinates and display modes.
        ViewState_ (1,1) matlabx.ui.axes.ImageAxesViewState = matlabx.ui.axes.ImageAxesViewState()

        % Backing value for native overlay visibility.
        OverlaysVisible_ (1,1) matlab.lang.OnOffSwitchState = "on"
        % Stored logical image mask.
        Mask_ = []
        % Backing value for mask display state.
        MaskEnabled_ (1,1) matlab.lang.OnOffSwitchState = "off"

        % Canonical Image5D data model.
        ImageData_ (1,1) matlabx.image.Image5D = matlabx.image.Image5D.fromComponents(zeros(256,256,3))

        % Selected source plane or computed composite, before display scaling.
        RenderSource_ (:,:,:) = matlabx.ui.axes.ImageAxes.placeholderImage

        % Per-component contrast/color/LUT display state.
        ComponentDisplay_ (1,:) matlabx.ui.axes.ImageAxesComponentDisplayState = matlabx.ui.axes.ImageAxesComponentDisplayState.empty()
    end

    %% Hosted graphics, layout, and UI collaborators

    % Transient graphics handles and general listener storage.
    properties (Access=private, Transient, NonCopyable)
        % UI components
        Grid matlab.ui.container.GridLayout
        % Panel containing the primary and static axes.
        Panel matlab.ui.container.Panel
        % Full-image coordinate axes used for labels and viewport graphics.
        staticAxes matlab.ui.control.UIAxes
        % MATLAB image primitive displaying DisplayCData.
        hImage matlab.graphics.primitive.Image
        % Cursor, pixel-value, and tool-status text graphic.
        BottomLabel (1,1) matlab.graphics.primitive.Text
        % Colorbar associated with the primary image axes.
        Colorbar matlab.graphics.illustration.ColorBar
        % Three-by-three grid used for aspect-preserving layout.
        sizingGrid matlab.ui.container.GridLayout
        % Patch showing the full-image extent in the overview.
        ViewportBoxFull (1,1) matlab.graphics.primitive.Patch
        % Patch showing the current visible viewport in the overview.
        ViewportBox (1,1) matlab.graphics.primitive.Patch

        % Internal listener that maintains the aspect-preserving layout.
        ResizeListener event.listener = event.listener.empty
        % One-shot listener used when toolbar buttons are created while hidden.
        InitialToolbarFocusListener event.listener = event.listener.empty
        % General listener storage retained for component-owned listeners.
        L event.listener

    end

    % Host-owned managers exposed only to lifecycle collaborators.
    properties (Access={?matlabx.ui.axes.ImageAxesToolManager}, Transient, NonCopyable)
        % manager for the host-owned context menu
        ContextMenuManager matlabx.ui.axes.ImageAxesContextMenuManager
        % manager for host-owned overlays
        OverlayManager matlabx.ui.axes.ImageAxesOverlayManager
    end

    % Primary UIAxes shared with tools and the tool manager.
    properties (Access={?matlabx.ui.axes.AxesTool, ?matlabx.ui.axes.ImageAxesToolManager})
        % Primary axes containing the image and overlay graphics.
        mainAxes matlab.ui.control.UIAxes
    end

    % Cached UI calibration used by resize calculations.
    properties (Access=private)
        % uipanelOverheadPx_ (1,1) double = NaN
        UICal matlabx.ui.calibration.UICalibration
    end

    % Public typography configuration.
    properties (Dependent, AbortSet)
        % Font size used by the panel title and bottom label.
        FontSize (1,1) double
    end

    % Backing values for dependent host UI properties.
    properties (Access=private, AbortSet)
        % Backing value for FontSize.
        FontSize_ (1,1) double = 12
        % Calibrated panel title/chrome height in pixels.
        uipanelOverheadPx_ (1,1) double = 19
        % Backing value for ContextMenuItems.
        ContextMenuItems_ (1,:) string = ["Image","Display","ResetView","Status"]
        % Backing value for ViewportBoxVisible.
        ViewportBoxVisible_ (1,1) matlab.lang.OnOffSwitchState = "off"
        % Requested toolbar visibility, independent of temporary startup hiding.
        ToolbarVisible_ (1,1) matlab.lang.OnOffSwitchState = "on"
    end


    % Flags and cached keys used to coalesce host updates.
    properties (Access=private)
        % flags to help coalesce/manage updates
        pendingSizeUpdate (1,1) logical = false
        % Input key for the most recently applied resize layout.
        LastResizeLayoutKey_ (1,5) double = NaN(1,5)
        % Whether the ComponentContainer still has its first update pending.
        FirstUpdatePending (1,1) logical = true
        % Whether semantic viewport notifications are temporarily suppressed.
        SuppressViewportChanged_ (1,1) logical = false
    end

    %% Auxiliary windows

    % Transient auxiliary windows owned by this ImageAxes.
    properties (Access=private, Transient, NonCopyable)
        % Window used to edit component display limits.
        displayLimitsWindow (:,1) matlabx.ui.axes.ImageAxesDisplayLimitsWindow
        % Window displaying source image metadata.
        metadataWindow matlabx.app.TextWindow
        % Window displaying generated image properties.
        imagePropertiesWindow matlabx.app.TextWindow
        % Window displaying ImageAxes operational status.
        statusWindow matlabx.app.TextWindow
        % Window displaying help for an installed tool.
        toolHelpWindow matlabx.app.TextWindow
    end

    % Open-state flags for auxiliary windows.
    properties (Access=private)
        % Whether the metadata window is open.
        metadataWindowOpen (1,1) logical = false
        % Whether the image-properties window is open.
        imagePropertiesWindowOpen (1,1) logical = false
        % Whether the status window is open.
        statusWindowOpen (1,1) logical = false
        % Whether the tool-help window is open.
        toolHelpWindowOpen (1,1) logical = false
    end

    %% Tool-facing geometry and event-routing state
    % Derived host geometry and cursor information exposed to tools.
    properties (Access=?matlabx.ui.axes.AxesTool, Dependent)
        % Ancestor figure that owns this component.
        ParentFig
        % Spatial size of the current render source.
        ImageSize
        % Width of the current render source in pixels.
        ImageWidth
        % Height of the current render source in pixels.
        ImageHeight
        % Full-image X limits in pixel-centered coordinates.
        defaultXLim
        % Full-image Y limits in pixel-centered coordinates.
        defaultYLim
        % Current pointer position in mainAxes image coordinates.
        cursorPosition
        % Current pointer position in staticAxes full-image coordinates.
        cursorPositionStatic
        % Integer pixel currently under the pointer, or empty outside the image.
        activePixel
    end

    % Optional tool-provided overrides for restored image limits.
    properties (Access=?matlabx.ui.axes.AxesTool)
        % control XLim and YLim of axes holding the image (if empty, lims will be set to default)
        XLim = []
        % Optional Y-limit override used when restoring the view.
        YLim = []
    end

    % FigureEventHub registration state.
    properties (Access=private)
        % Figure-level event hub serving this component.
        Hub matlabx.ui.interaction.FigureEventHub
        % Registration identifier assigned by FigureEventHub.
        RouterId double = NaN
    end

    %% Events
    events (NotifyAccess=protected)
        % Emitted after the selected plane or generated composite changes.
        RenderSourceChanged
        % Emitted after a display-facing property changes.
        DisplayStateChanged
        % Emitted after the canonical ImageData object is replaced.
        ImageDataChanged
        % Emitted after the visible region or viewport controller state changes.
        ViewportChanged
    end

    %% ComponentContainer lifecycle (setup/update)
    methods (Access=protected)

        function setup(obj)
        %SETUP Construct graphics, managers, routing, and initial display state.
            % Match the native UIAxes default; constructor values override it.
            obj.Position = [10 10 400 300];

            % Use the parent's initial color; do not track later changes.
            parent = obj.Parent;
            if isprop(parent, "BackgroundColor")
                obj.BackgroundColor = parent.BackgroundColor;
            elseif isprop(parent, "Color")
                obj.BackgroundColor = parent.Color;
            end

            % perform/retrieve calibration first
            obj.UICal = matlabx.UICal.get();
            obj.uipanelOverheadPx_ = ...
                obj.UICal.uipanelTopChromeHeightPx(obj.FontSize_);

            obj.Interruptible = 'off';
            obj.BusyAction = 'cancel';

            % Main grid
            obj.Grid = uigridlayout(obj,[1,1], ...
                'RowHeight',{'fit'},...
                'ColumnWidth',{'fit'},...
                'RowSpacing',0,...
                'ColumnSpacing',0,...
                'Padding',[0 0 0 0], ...
                'BackgroundColor',[1 1 1]);

            obj.sizingGrid = uigridlayout(obj.Grid,[3,3],...
                'RowHeight',{0,300,0},...
                'ColumnWidth',{0,300,0},...
                'ColumnSpacing',0,...
                'RowSpacing',0,...
                'Padding',[0 0 0 0],...
                'BackgroundColor',[0 0 0]);

            % Panel to hold the axes
            obj.Panel = uipanel(obj.sizingGrid, ...
                'BackgroundColor',[0 0 0],...
                'AutoResizeChildren','off',...
                'BorderWidth',0,...
                'FontSize',obj.FontSize_,...
                'FontUnits','pixels');
            obj.Panel.Layout.Row = 2;
            obj.Panel.Layout.Column = 2;

            obj.Panel.Title = "";

            % Main axes
            obj.mainAxes = uiaxes(obj.Panel, ...
                'Units','normalized', ...
                'InnerPosition',[0 0 1 1], ...
                'YDir','reverse', ...
                'YLim',[0 1], ...
                'XLim',[0 1], ...
                'XTick',[], ...
                'YTick',[], ...
                'Color',[0 0 0], ...
                'XColor','none', ...
                'YColor','none', ...
                'Visible','off', ...
                'PositionConstraint','innerposition', ...
                'NextPlot','add', ...
                'HitTest','on', ...
                'PickableParts','all');
            obj.mainAxes.Toolbar = axtoolbar(obj.mainAxes,{}, ...
                "Expanded","on");
            obj.mainAxes.Interactions = [];
            disableDefaultInteractivity(obj.mainAxes);

            % Static axes (used for cursor-follow zoom math)
            obj.staticAxes = uiaxes(obj.Panel, ...
                'Units','normalized', ...
                'InnerPosition',[0 0 1 1], ...
                'YDir','reverse', ...
                'YLim',[0 1], ...
                'XLim',[0 1], ...
                'XTick',[], ...
                'YTick',[], ...
                'Color',[0 0 0], ...
                'XColor','none', ...
                'YColor','none', ...
                'Visible','off', ...
                'PositionConstraint','innerposition', ...
                'HitTest','off', ...
                'PickableParts','none');
            % obj.staticAxes.Toolbar = axtoolbar(obj.staticAxes,{});
            obj.staticAxes.Toolbar = [];
            obj.staticAxes.Interactions = [];
            disableDefaultInteractivity(obj.staticAxes);
            obj.staticAxes.PlotBoxAspectRatio = [1 1 1];
            obj.staticAxes.DataAspectRatio = [1 1 1];

            % setup and store colorbar
            obj.Colorbar = colorbar(obj.mainAxes,"east","Visible","off","PickableParts","none","HitTest","off");

            % initialize overlay/tool lifecycle/hotkey managers
            obj.OverlayManager = matlabx.ui.axes.ImageAxesOverlayManager(obj);
            obj.ToolManager = matlabx.ui.axes.ImageAxesToolManager(obj);
            % Uninstall borrowed tools before axes toolbar graphics disappear.
            obj.ToolLifetimeListener = addlistener(obj.mainAxes, ...
                'ObjectBeingDestroyed',@(~,~) obj.ToolManager.uninstallAll());
            obj.HotkeyRegistry = matlabx.ui.axes.ImageAxesHotkeyRegistry();

            % Hub registration (one hub per figure; this instance registers itself)
            obj.Hub = matlabx.ui.interaction.FigureEventHub.ensure(obj.ParentFig);
            obj.RouterId = obj.Hub.register(obj,'Priority',10,'CaptureDuringDrag',true);

            % Image
            obj.hImage = image(obj.mainAxes,[],...
                'CDataMapping','scaled',...
                'HitTest','off',...
                'PickableParts','none');

            % This group is created immediately above the image and before
            % interactive graphics. Child ordering keeps all mounted content
            % below interactive overlays, including content mounted later.
            obj.mainAxes.SortMethod = 'childorder';
            obj.ApplicationOverlayLayer = hggroup(obj.mainAxes, ...
                'Tag','ApplicationOverlayLayer', ...
                'HitTest','off','PickableParts','none');
            % Detach before axes children are destroyed (ComponentContainer
            % teardown can precede the ImageAxes destructor).
            obj.ApplicationOverlayLifetimeListener = addlistener(obj.mainAxes, ...
                'ObjectBeingDestroyed',@(~,~) obj.detachApplicationOverlays());

            % Update CLim, PlotBoxAspectRatio, and DataAspectRatio *after* creating image object
            obj.mainAxes.CLim               = [0 1];
            obj.mainAxes.PlotBoxAspectRatio = [1 1 1];
            obj.mainAxes.DataAspectRatio    = [1 1 1];

            % Keep internal layout handling independent of the public
            % SizeChangedFcn so applications may assign their own callback.
            obj.ResizeListener = addlistener(obj, ...
                'SizeChanged',@(~,~) obj.updateOnResize());

            % label in bottom-left corner
            obj.BottomLabel = text('Parent',obj.staticAxes,...
                'Units','normalized',...
                'Position',[0.005 0.005],...
                'Color',[1 1 1],...
                'BackgroundColor',[0 0 0 0.5],...
                'String','',...
                'FontSize',obj.FontSize_,...
                'Clipping','on',...
                'Margin',3,...
                'HorizontalAlignment','left',...
                'VerticalAlignment','bottom');

            % set up ViewportBox patches
            obj.ViewportBoxFull = patch(obj.staticAxes, ...
                'XData',NaN, ...
                'YData',NaN, ...
                'EdgeColor',obj.ViewportBoxEdgeColor, ...
                'FaceColor',obj.ViewportBoxFaceColor, ...
                'FaceAlpha',obj.ViewportBoxFaceAlpha, ...
                'HitTest','on', ...
                'PickableParts','all', ...
                'LineWidth', obj.ViewportBoxLineWidth, ...
                'Visible','off', ...
                'Tag','ViewportBoxFull');
            obj.ViewportBox = patch(obj.staticAxes, ...
                'XData',NaN, ...
                'YData',NaN, ...
                'EdgeColor',obj.ViewportBoxEdgeColor, ...
                'FaceColor',obj.ViewportBoxFaceColor, ...
                'FaceAlpha',obj.ViewportBoxFaceAlpha, ...
                'HitTest','on', ...
                'PickableParts','all', ...
                'LineWidth', obj.ViewportBoxLineWidth, ...
                'Visible','off', ...
                'Tag','ViewportBox');

            % set up ContextMenu
            obj.setupContextMenu();

            % initialize display state from ImageData
            obj.syncViewStateToImageData();
            
            % initial render
            obj.syncRenderSourceToView(ResetView=true);
        end

        function update(obj)
        %UPDATE Apply ComponentContainer property changes to hosted graphics.
            isFirstUpdate = obj.FirstUpdatePending;
            obj.FirstUpdatePending = false;

            % set the Tag property of the axes used for event routing
            obj.mainAxes.Tag = obj.Name;
            obj.staticAxes.Tag = obj.Name;

            % set BackgroundColor
            obj.Grid.BackgroundColor = obj.BackgroundColor;
            % obj.Panel.BackgroundColor = obj.BackgroundColor;

            obj.sizingGrid.BackgroundColor = obj.BackgroundColor;

            obj.updateOnResize();

            % Reveal constructor-specified buttons only after the host figure
            % is visible, then immediately move focus away from the toolbar.
            if isFirstUpdate
                if isempty(fieldnames(obj.ToolbarButtons))
                    obj.mainAxes.Toolbar.Visible = obj.ToolbarVisible_;
                else
                    obj.mainAxes.Toolbar.Visible = 'off';
                    obj.showInitialToolbar();
                end
            end

        end

        function setupContextMenu(obj)
        %SETUPCONTEXTMENU Create the host-owned context-menu manager.
            obj.ContextMenuManager = matlabx.ui.axes.ImageAxesContextMenuManager(obj, obj.ParentFig);
            obj.ContextMenuManager.setBuiltinItems(obj.ContextMenuItems_);
        end

    end



    %% Zoom / cursor-follow navigation
    %
    % ImageAxes represents the visible zoomed region as ordinary image axes
    % limits on mainAxes:
    %
    %   XLim = [xLower, xLower + viewWidth]
    %   YLim = [yLower, yLower + viewHeight]
    %
    % A ZoomLevel is the fraction of the full image currently visible. Thus
    % ZoomLevel==1 displays the full image, while ZoomLevel==0.5 is a 2x zoom
    % showing half the image width and height.
    %
    % Cursor-follow navigation uses staticAxes, whose limits stay fixed to the
    % full image. The cursor position in staticAxes is normalized and mapped to
    % the available travel of the zoomed viewport box. FollowCursorLims define the
    % active normalized control interval. Positions outside that interval act as
    % dead zones and pin the view to the corresponding image edge.
    %
    % To avoid a jump when FollowCursor is re-enabled at a new cursor location,
    % the current cursor/view relationship is stored as a per-axis anchor. The
    % mapping then interpolates smoothly from that anchor to the reachable edges.
    % Once an axis reaches a follow bound, that axis releases its anchor and
    % returns to the ordinary absolute cursor-follow mapping.

    % Private zoom, cursor-follow, and viewport-box geometry state.
    properties (Access=private)
        % Zoom_ stores zoom interaction state. The visible viewport is the source
        % of truth for ZoomLevel/ZoomFactor; PresetFactors are only convenient
        % stops for click, key, and context-menu zoom commands. LastCursorXY is in
        % mainAxes image coordinates and is used as a fallback anchor when enabling
        % zoom with no active cursor over the image.
        Zoom_ = struct( ...
            'PresetFactors', [1 2 3 4 5 10 15 20], ...
            'MinFactor', 1, ...
            'MaxFactor', 20, ...
            'LastCursorXY', [], ...
            'LastFactor', 1, ...
            'Enabled', false)

        % FollowCursor_ stores cursor-follow state. Lims are normalized staticAxes
        % control bounds. AnchorNorm/AnchorLower are per-axis no-jump anchors;
        % NaN/empty means the axis uses absolute mapping. LastCursorXY is in
        % staticAxes full-image coordinates.
        FollowCursor_ = struct( ...
            'Lims', [0.10 0.90], ...
            'Enabled', true, ...
            'AnchorNorm', [], ...
            'AnchorLower', [], ...
            'LastCursorXY', [])

        % ViewportBoxGeometry_ stores miniature overview geometry on staticAxes.
        % XFull/YFull draw the full-image frame. XViewportBase/YViewportBase draw
        % a zero-offset viewport box sized for the current ZoomLevel;
        % applyViewportLimits shifts that base according to the actual view lower
        % limits.
        ViewportBoxGeometry_ = struct( ...
            'Top', [], ...
            'Left', [], ...
            'XBase', [], ...
            'YBase', [], ...
            'XFull', [], ...
            'YFull', [], ...
            'XViewportBase', [], ...
            'YViewportBase', [])
    end

    % Public viewport navigation state.
    properties (Dependent)
        % Whether zoomed viewport behavior is active.
        ZoomEnabled
        % Visible fraction of the full image along each spatial dimension.
        ZoomLevel
        % Magnification factor derived from the current viewport.
        ZoomFactor

        % Whether pointer movement repositions the zoomed viewport.
        FollowCursorEnabled
        % Normalized static-axes interval controlling cursor-follow travel.
        FollowCursorLims
    end

    % Viewport overview appearance and placement.
    properties
        % Overview size relative to the full static axes.
        ViewportBoxScale = 0.1
        % Edge color of viewport overview patches.
        ViewportBoxEdgeColor = [0 0 0]
        % Face color of viewport overview patches.
        ViewportBoxFaceColor = [1 1 1]
        % Face transparency of viewport overview patches.
        ViewportBoxFaceAlpha = 0.25
        % Line width of viewport overview patches.
        ViewportBoxLineWidth = 1

        % Normalized top inset of the viewport overview.
        ViewportBoxTop = 0.01
        % Normalized left inset of the viewport overview.
        ViewportBoxLeft = 0.01
    end

    % Private zoom / cursor-follow helpers
    methods
        function followCursor(obj)
            %FOLLOWCURSOR  Move the zoom view according to static-axes cursor position.

            XY = obj.cursorPositionStatic;

            if isempty(XY)
                return
            end

            obj.applyFollowCursorLims(XY);
        end

        function zoomViewToCursor(obj)
            %ZOOMVIEWTOCURSOR  Change zoom while preserving the pixel under the cursor

            XY = obj.cursorPosition;

            if isempty(XY)
                return
            end

            % These are still the limits from the previous zoom level because the
            % axes limits have not yet been updated.
            oldXLim = obj.mainAxes.XLim;
            oldYLim = obj.mainAxes.YLim;

            obj.applyCursorAnchoredZoomLims(XY,oldXLim,oldYLim);
        end

        function [XLim,YLim] = getFollowCursorLims(obj,XY)
            %GETFOLLOWCURSORLIMS  Calculate cursor-following zoom limits
            %
            %   [XLim,YLim] = getFollowCursorLims(obj,XY) maps XY from the
            %   full-sized static axes into the available cursor-follow range.
            %   FollowCursorLims define the active normalized cursor interval; values
            %   outside this interval form dead zones that pin the view to the image
            %   edges.
            %
            %   XY must be expressed in the coordinate system of the full-sized static
            %   axes.

            arguments
                obj
                XY (1,2) double
            end

            % Image dimensions
            sz = obj.RenderSourceSize;
            H = sz(1);
            W = sz(2);

            % Current zoomed-window dimensions
            viewWidth  = obj.ZoomLevel * W;
            viewHeight = obj.ZoomLevel * H;

            % Full image limits
            defXLim = [0.5, W + 0.5];
            defYLim = [0.5, H + 0.5];

            % Calculate the lower limits from the static cursor.
            lower = obj.getFollowCursorLowerLimit(XY);

            % Constrain the view to the full image
            lower(1) = min(max(lower(1),defXLim(1)), ...
                defXLim(2) - viewWidth);

            lower(2) = min(max(lower(2),defYLim(1)), ...
                defYLim(2) - viewHeight);

            % Construct limits
            XLim = lower(1) + [0,viewWidth];
            YLim = lower(2) + [0,viewHeight];
        end

        function [XLim,YLim] = getCursorAnchoredZoomLims(obj,XY,oldXLim,oldYLim,factor)
            %GETCURSORANCHOREDZOOMLIMS  Calculate cursor-anchored zoom limits
            %
            %   [XLim,YLim] = getCursorAnchoredZoomLims(obj,XY,oldXLim,oldYLim)
            %   returns axes limits for the target zoom factor such that image
            %   coordinate XY remains under the same relative cursor position as it
            %   occupied in oldXLim/oldYLim. This is the click/scroll zoom behavior:
            %
            %       - clicking at the current view center keeps the view centered
            %       - clicking off-center shifts the view so the clicked pixel stays
            %         under the cursor as much as image bounds allow
            %       - bounds clamping necessarily breaks the invariant near edges
            %
            %   XY must be expressed in image/data coordinates.

            arguments
                obj
                XY (1,2) double
                oldXLim (1,2) double
                oldYLim (1,2) double
                factor (1,1) double = obj.ZoomFactor
            end

            % Image dimensions
            sz = obj.RenderSourceSize;
            H = sz(1);
            W = sz(2);
            factor = obj.clampZoomFactor(factor);

            % Full image limits
            defXLim = [0.5, W + 0.5];
            defYLim = [0.5, H + 0.5];

            % New visible dimensions
            newWidth  = W / factor;
            newHeight = H / factor;

            % Cursor position within the current visible window
            xFrac = (XY(1) - oldXLim(1)) / diff(oldXLim);
            yFrac = (XY(2) - oldYLim(1)) / diff(oldYLim);

            % Guard against a cursor coordinate slightly outside the axes
            xFrac = min(max(xFrac,0),1);
            yFrac = min(max(yFrac,0),1);

            % Preserve the cursor's fractional position within the view
            xLower = XY(1) - xFrac * newWidth;
            yLower = XY(2) - yFrac * newHeight;

            % Constrain the view to the full image
            xLower = min(max(xLower,defXLim(1)), ...
                defXLim(2) - newWidth);

            yLower = min(max(yLower,defYLim(1)), ...
                defYLim(2) - newHeight);

            % Construct limits
            XLim = xLower + [0,newWidth];
            YLim = yLower + [0,newHeight];
        end

        function lower = getFollowCursorLowerLimit(obj,XY)
            %GETFOLLOWCURSORLOWERLIMIT  Map static cursor position to view lower limit
            %
            %   lower = getFollowCursorLowerLimit(obj,XY) returns the lower-left
            %   image coordinate of the zoomed viewport box implied by the current
            %   static-axes cursor coordinate XY.
            %
            %   Without an active anchor, this is the absolute mapping:
            %
            %       FollowCursorLims(1) -> image top/left edge
            %       FollowCursorLims(2) -> image bottom/right edge
            %
            %   With an active per-axis anchor, the function instead preserves the
            %   cursor/view relationship that existed when FollowCursor was enabled
            %   or recalibrated. Each axis interpolates from that anchor toward its
            %   reachable edges, then releases the anchor after it reaches a follow
            %   bound. Released axes use absolute mapping again.

            % Image dimensions
            sz = obj.RenderSourceSize;
            H = sz(1);
            W = sz(2);

            % Current zoomed-window dimensions
            viewWidth  = obj.ZoomLevel * W;
            viewHeight = obj.ZoomLevel * H;

            % Available travel of the zoomed view
            travel = [W - viewWidth, H - viewHeight];

            % Follow-cursor limits in normalized static-axes coordinates.
            % Values outside this interval form the cursor-follow dead zones.
            [XYNorm, followCursorLims] = obj.getFollowCursorNormalizedPosition(XY);
            a = followCursorLims(1);
            b = followCursorLims(2);

            if b <= a
                error('FollowCursorLims must contain two increasing values.')
            end

            lowerMin = [0.5,0.5];
            lowerMax = lowerMin + travel;

            [anchorNorm, anchorLower] = obj.getFollowCursorAnchor();

            % Anchored mapping: preserve the current cursor/view relationship when
            % follow-cursor is enabled, then interpolate smoothly from that anchor
            % to the reachable image edges. Each axis releases its anchor after it
            % reaches a follow bound, returning that axis to absolute mapping with no
            % position jump.
            XYNorm = min(max(XYNorm,0),1);

            lower = zeros(1,2);
            releasedAnchor = false(1,2);

            for k = 1:2
                if ~isfinite(anchorNorm(k)) || ~isfinite(anchorLower(k))
                    n = min(max(XYNorm(k),a),b);
                    followFrac = (n - a) / (b - a);
                    lower(k) = lowerMin(k) + followFrac * travel(k);
                    continue
                end

                leftNorm = a;
                rightNorm = b;

                if anchorNorm(k) < a
                    leftNorm = 0;
                elseif anchorNorm(k) > b
                    rightNorm = 1;
                end

                n = min(max(XYNorm(k),leftNorm),rightNorm);
                anchor = min(max(anchorNorm(k),leftNorm),rightNorm);
                anchorLower(k) = min(max(anchorLower(k),lowerMin(k)),lowerMax(k));

                if n <= anchor
                    denom = anchor - leftNorm;
                    if denom <= eps
                        lower(k) = anchorLower(k);
                    else
                        t = (n - leftNorm) / denom;
                        lower(k) = lowerMin(k) + t * (anchorLower(k) - lowerMin(k));
                    end
                else
                    denom = rightNorm - anchor;
                    if denom <= eps
                        lower(k) = anchorLower(k);
                    else
                        t = (n - anchor) / denom;
                        lower(k) = anchorLower(k) + t * (lowerMax(k) - anchorLower(k));
                    end
                end

                if n <= leftNorm + eps || n >= rightNorm - eps
                    releasedAnchor(k) = true;
                end
            end

            if any(releasedAnchor)
                anchorNorm(releasedAnchor) = NaN;
                anchorLower(releasedAnchor) = NaN;
                obj.FollowCursor_.AnchorNorm = anchorNorm;
                obj.FollowCursor_.AnchorLower = anchorLower;
            end
        end

        function [XYNorm, followCursorLims] = getFollowCursorNormalizedPosition(obj,XY)
            %GETFOLLOWCURSORNORMALIZEDPOSITION  Normalize static cursor for follow mode.

            sz = obj.RenderSourceSize;
            H = sz(1);
            W = sz(2);

            XYNorm = (XY - 0.5) ./ [W,H];
            followCursorLims = obj.FollowCursorLims;
        end

        function calibrateFollowCursorAnchor(obj,XYStatic)
            %CALIBRATEFOLLOWCURSORANCHOR  Anchor follow-cursor at current view
            %
            %   calibrateFollowCursorAnchor(obj,XYStatic) records a no-jump anchor
            %   that maps the current static-axes cursor location to the current
            %   mainAxes lower limits. This lets FollowCursor be disabled, the mouse
            %   moved elsewhere, and FollowCursor re-enabled without immediately
            %   snapping the viewport box to the absolute cursor-follow mapping.
            %
            %   The anchor is per-axis and may later release independently in
            %   getFollowCursorLowerLimit after reaching the corresponding follow
            %   bound.

            if isempty(XYStatic)
                obj.clearFollowCursorAnchor();
                return
            end

            [XYNorm, ~] = obj.getFollowCursorNormalizedPosition(XYStatic);
            currentLower = [obj.mainAxes.XLim(1), obj.mainAxes.YLim(1)];

            obj.FollowCursor_.AnchorNorm = XYNorm;
            obj.FollowCursor_.AnchorLower = currentLower;
            obj.FollowCursor_.LastCursorXY = XYStatic;
        end

        function [anchorNorm, anchorLower] = getFollowCursorAnchor(obj)
            %GETFOLLOWCURSORANCHOR  Return per-axis cursor-follow anchors.
            %
            %   anchorNorm is the normalized static-axes cursor position at which
            %   the anchor was created. anchorLower is the corresponding mainAxes
            %   lower limit. NaN means the axis has no active anchor and should use
            %   absolute cursor-follow mapping.

            anchorNorm = obj.FollowCursor_.AnchorNorm;
            anchorLower = obj.FollowCursor_.AnchorLower;

            if ~isnumeric(anchorNorm) || numel(anchorNorm) ~= 2
                anchorNorm = [NaN,NaN];
            end

            if ~isnumeric(anchorLower) || numel(anchorLower) ~= 2
                anchorLower = [NaN,NaN];
            end
        end

        function clearFollowCursorAnchor(obj)
            %CLEARFOLLOWCURSORANCHOR  Clear the no-jump cursor-follow anchor.

            obj.FollowCursor_.AnchorNorm = [NaN,NaN];
            obj.FollowCursor_.AnchorLower = [NaN,NaN];
            obj.FollowCursor_.LastCursorXY = [];
        end

        function XY = currentViewCenter(obj)
            %CURRENTVIEWCENTER Return the center of the current main-axes view.
            if isempty(obj.mainAxes) || ~isvalid(obj.mainAxes)
                sz = obj.RenderSourceSize;
                XY = [(sz(2) + 1)/2, (sz(1) + 1)/2];
                return
            end

            XY = [mean(obj.mainAxes.XLim), mean(obj.mainAxes.YLim)];
        end

        function factor = clampZoomFactor(obj, factor)
            %CLAMPZOOMFACTOR Constrain a visual zoom factor to supported bounds.
            factor = min(max(factor, obj.Zoom_.MinFactor), obj.Zoom_.MaxFactor);
        end

        function level = zoomFactorToLevel(obj, factor)
            %ZOOMFACTORTOLEVEL Convert visual zoom factor to visible fraction.
            level = 1 ./ obj.clampZoomFactor(factor);
        end

        function factor = zoomLevelToFactor(obj, level)
            %ZOOMLEVELTOFACTOR Convert visible fraction to visual zoom factor.
            factor = obj.clampZoomFactor(1 ./ level);
        end

        function factor = zoomFactorFromViewportSize(obj, viewportSize)
            %ZOOMFACTORFROMVIEWPORTSIZE Return aspect-locked factor for a size request.
            sz = obj.RenderSourceSize;
            imageSize = [sz(2), sz(1)];
            viewportSize = max(double(viewportSize), eps);
            factor = max(imageSize ./ viewportSize);
            factor = obj.clampZoomFactor(factor);
        end

        function [XLim,YLim] = getCenterAnchoredViewportLimits(obj, center, factor)
            %GETCENTERANCHOREDVIEWPORTLIMITS Return aspect-locked limits.
            sz = obj.RenderSourceSize;
            H = sz(1);
            W = sz(2);

            factor = obj.clampZoomFactor(factor);
            viewWidth = W / factor;
            viewHeight = H / factor;

            defXLim = [0.5, W + 0.5];
            defYLim = [0.5, H + 0.5];

            xLower = center(1) - viewWidth/2;
            yLower = center(2) - viewHeight/2;

            xLower = min(max(xLower,defXLim(1)), defXLim(2) - viewWidth);
            yLower = min(max(yLower,defYLim(1)), defYLim(2) - viewHeight);

            XLim = xLower + [0,viewWidth];
            YLim = yLower + [0,viewHeight];
        end

        function applyViewportLimits(obj,XLim,YLim)
            %APPLYVIEWPORTLIMITS Apply already-normalized image-space limits.
            %
            %   This is the final low-level sink for view changes. Public viewport
            %   setters normalize requests before they get here, so this method can
            %   stay small and simply push limits into the graphics objects.
            oldXLim = obj.mainAxes.XLim;
            oldYLim = obj.mainAxes.YLim;
            set(obj.mainAxes,...
                'XLim',XLim,...
                'YLim',YLim);

            obj.updateViewportBoxGeometry();

            XViewportBase = obj.ViewportBoxGeometry_.XViewportBase;
            YViewportBase = obj.ViewportBoxGeometry_.YViewportBase;

            set(obj.ViewportBox,...
                "XData",XViewportBase + (XLim(1) - 0.5)*obj.ViewportBoxScale,...
                "YData",YViewportBase + (YLim(1) - 0.5)*obj.ViewportBoxScale);

            obj.updateViewportBoxVisibility();

            if ~obj.SuppressViewportChanged_ && ...
                    (~isequaln(oldXLim,obj.mainAxes.XLim) || ...
                     ~isequaln(oldYLim,obj.mainAxes.YLim))
                notify(obj,'ViewportChanged');
            end
        end

        function updateViewportBoxVisibility(obj)
            %UPDATEVIEWPORTBOXVISIBILITY Apply ImageAxes viewport-box visibility policy.
            %
            %   ViewportBoxVisible is the sole ImageAxes-owned visibility switch. Tools
            %   that want temporary visibility, such as Zoom, should save/restore
            %   this property rather than relying on an implicit effective state.

            if isempty(obj.ViewportBoxFull) || ~isvalid(obj.ViewportBoxFull) || ...
                    isempty(obj.ViewportBox) || ~isvalid(obj.ViewportBox)
                return
            end

            obj.ViewportBoxFull.Visible = obj.ViewportBoxVisible;
            obj.ViewportBox.Visible = obj.ViewportBoxVisible;
        end

        function resetZoomViewState(obj)
            %RESETZOOMVIEWSTATE  Restore default zoom/follow view state.
            %
            %   This resets the host navigation state that determines the visible
            %   viewport box without enabling or disabling any tool. If the Zoom tool is
            %   still enabled, the overview patches remain visible and reflect the
            %   full-image view. If zoom is not enabled, the patches stay hidden.

            obj.Zoom_.LastCursorXY = [];
            obj.Zoom_.LastFactor = 1;
            obj.clearFollowCursorAnchor();
            obj.resetViewport();

            obj.updateViewportBoxVisibility();
        end

        function applyFollowCursorLims(obj,XY)
            %APPLYFOLLOWCURSORLIMS  Apply cursor-following zoom limits
            %
            %   applyFollowCursorLims(obj,XY) computes the zoomed viewport-box limits
            %   implied by static-axes cursor coordinate XY, applies them to mainAxes,
            %   updates the miniature viewport box, and logs the mapping when debug output
            %   is enabled.
            %
            %   XY must be expressed in full-sized static-axes coordinates, not in
            %   the current zoomed mainAxes coordinate system.

            if nargin < 2 || isempty(XY)
                XY = obj.cursorPositionStatic;
            end

            if isempty(XY)
                return
            end

            [XViewportLim,YViewportLim] = obj.getFollowCursorLims(XY);
            obj.applyZoomLims(XViewportLim,YViewportLim);

            % This field now always contains static-axes coordinates
            obj.FollowCursor_.LastCursorXY = XY;
        end

        function applyCursorAnchoredZoomLims(obj,XY,oldXLim,oldYLim,factor)
            %APPLYCURSORANCHOREDZOOMLIMS  Apply a zoom step around image coordinate XY
            %
            %   applyCursorAnchoredZoomLims(obj,XY,oldXLim,oldYLim) applies the
            %   current ZoomLevel using oldXLim/oldYLim as the pre-zoom visible view.
            %   It preserves XY at the same relative position inside the view where
            %   possible, then recalibrates the follow-cursor anchor so the next
            %   cursor-follow move does not jump.
            %
            %   XY must be expressed in image/data coordinates from mainAxes.

            if nargin < 2 || isempty(XY)
                XY = obj.cursorPosition;
            end

            if isempty(XY)
                return
            end

            if nargin < 3 || isempty(oldXLim)
                oldXLim = obj.mainAxes.XLim;
            end

            if nargin < 4 || isempty(oldYLim)
                oldYLim = obj.mainAxes.YLim;
            end

            if nargin < 5 || isempty(factor)
                factor = obj.ZoomFactor;
            end

            [XViewportLim,YViewportLim] = ...
                obj.getCursorAnchoredZoomLims(XY,oldXLim,oldYLim,factor);

            obj.applyZoomLims(XViewportLim,YViewportLim);

            % This field now always contains image/data coordinates
            obj.Zoom_.LastCursorXY = XY;
            obj.Zoom_.LastFactor = obj.ZoomFactor;

            if obj.ZoomEnabled && obj.FollowCursorEnabled
                obj.calibrateFollowCursorAnchor(obj.cursorPositionStatic);
            end
        end

        function applyCenterAnchoredZoomLims(obj,XY,factor)
            %APPLYCENTERANCHOREDZOOMLIMS Apply zoom factor centered on XY.
            %
            %   Stored zoom anchors represent the region the user was viewing when
            %   zoom was disabled. Treat them as desired view centers, not as live
            %   cursor positions inside the current full-image axes limits.

            if nargin < 3 || isempty(factor)
                factor = obj.ZoomFactor;
            end

            [xLimits,yLimits] = obj.getCenterAnchoredViewportLimits(XY,factor);
            obj.applyViewportLimits(xLimits,yLimits);
            obj.Zoom_.LastCursorXY = XY;
            obj.Zoom_.LastFactor = obj.ZoomFactor;

            if obj.ZoomEnabled && obj.FollowCursorEnabled
                obj.calibrateFollowCursorAnchor(obj.cursorPositionStatic);
            end
        end

        function applyZoomLims(obj,XLim,YLim)
            %APPLYZOOMLIMS  Compatibility alias for applying viewport limits.
            %
            %   Older zoom helpers still call applyZoomLims. Keep the name as a
            %   narrow internal bridge while viewport terminology becomes primary.
            obj.applyViewportLimits(XLim,YLim);
        end

        function updateViewportBoxGeometry(obj)
            %UPDATEVIEWPORTBOXGEOMETRY Update miniature viewport-box geometry.
            %
            %   Recomputes the staticAxes patch coordinates used for the full-image
            %   frame and the current-size viewport box. The viewport box stored
            %   here is intentionally zero-offset relative to the image;
            %   applyViewportLimits translates it based on XLim(1)/YLim(1).
            %
            %   This must be called when the rendered image size or ZoomLevel changes.

            sz = obj.RenderSourceSize;
            H = sz(1);
            W = sz(2);

            S = struct();

            S.Top  = (obj.ViewportBoxTop  * H) + 0.5;
            S.Left = (obj.ViewportBoxLeft * W) + 0.5;

            S.XBase = [0,0,W,W] .* obj.ViewportBoxScale;
            S.YBase = [0,H,H,0] .* obj.ViewportBoxScale;

            S.XFull = S.XBase + S.Left;
            S.YFull = S.YBase + S.Top;

            zoomLevel = obj.ZoomLevel;

            S.XViewportBase = S.XBase .* zoomLevel + S.Left;
            S.YViewportBase = S.YBase .* zoomLevel + S.Top;

            % Update coordinates struct
            obj.ViewportBoxGeometry_ = S;

            % Always update full-size box when coordinates change
            set(obj.ViewportBoxFull,...
                "XData",S.XFull,...
                "YData",S.YFull);
        end

    end

    % Public zoom / cursor-follow API
    methods

        function z = get.ZoomEnabled(obj)
        %GET.ZOOMENABLED Return whether zoom navigation is enabled.
            %ZOOMENABLED  True when mainAxes displays a zoomed viewport box.
            %
            %   Setting ZoomEnabled=true shows the miniature viewport boxes and applies
            %   the current ZoomLevel around the cursor when possible. Setting it
            %   false hides viewport boxes and restores full-image limits.

            z = obj.Zoom_.Enabled;
        end

        function set.ZoomEnabled(obj,tf)
        %SET.ZOOMENABLED Enable or disable zoom navigation.
            %ZOOMENABLED  Enable or disable zoom navigation.
            % Route public assignments through the installed Zoom tool when
            % available so controller state and toolbar presentation cannot
            % disagree with the host's viewport mode. Zoom.onEnabled/onDisabled
            % call enableZoom/disableZoom directly, so this does not recurse.
            zoomTool = obj.getInstalledTool("Zoom");
            if ~isempty(zoomTool) && isvalid(zoomTool)
                if tf
                    zoomTool.enable();
                else
                    zoomTool.disable();
                end
            elseif tf
                obj.enableZoom();
            else
                obj.disableZoom();
            end
        end

        function p = get.FollowCursorEnabled(obj)
        %GET.FOLLOWCURSORENABLED Return whether cursor-follow navigation is enabled.
            %FOLLOWCURSORENABLED  True when the zoomed view follows cursor motion.
            %
            %   FollowCursor only affects motion while ZoomEnabled is true. When
            %   re-enabled, the current cursor/view relationship is anchored so the
            %   view does not jump to the absolute cursor-follow position.

            p = obj.FollowCursor_.Enabled;
        end

        function set.FollowCursorEnabled(obj,tf)
        %SET.FOLLOWCURSORENABLED Enable or disable cursor-follow navigation.
            %FOLLOWCURSORENABLED  Enable or disable cursor-follow navigation.

            if tf
                obj.enableFollowCursor();
            else
                obj.disableFollowCursor();
            end
        end

        function p = get.FollowCursorLims(obj)
        %GET.FOLLOWCURSORLIMS Return the normalized cursor-follow control interval.
            %FOLLOWCURSORLIMS  Normalized cursor-follow active interval.
            %
            %   FollowCursorLims is a two-element vector [a b] in normalized
            %   staticAxes coordinates. For each axis:
            %
            %       cursor norm <= a  -> viewport box pinned to top/left edge
            %       cursor norm >= b  -> viewport box pinned to bottom/right edge
            %       a < norm < b      -> viewport box interpolates through image travel
            %
            %   Wider intervals such as [0.10 0.90] produce a gentler control feel
            %   and make anchor release less noticeable. Narrower intervals make the
            %   view reach image edges with less cursor travel.

            p = obj.FollowCursor_.Lims;
        end

        function set.FollowCursorLims(obj,lims)
        %SET.FOLLOWCURSORLIMS Set the normalized cursor-follow control interval.
            %FOLLOWCURSORLIMS  Set cursor-follow active interval.
            %
            %   If zoom and cursor-follow are currently active, changing the limits
            %   recalibrates the anchor at the current cursor position so the view
            %   does not jump immediately after the setting changes.

            obj.FollowCursor_.Lims = lims;

            if obj.ZoomEnabled && obj.FollowCursorEnabled
                obj.calibrateFollowCursorAnchor(obj.cursorPositionStatic);
            end
        end

        function z = get.ZoomLevel(obj)
        %GET.ZOOMLEVEL Return the visible fraction of the full image.
            %ZOOMLEVEL  Fraction of the full image visible in the zoomed view.
            %
            %   ZoomLevel==1 means the full image is visible. ZoomLevel==0.5 means
            %   the viewport box is half the image width and height, corresponding to a
            %   2x visual zoom.

            sz = obj.RenderSourceSize;
            if isempty(sz) || numel(sz) < 2 || any(sz(1:2) <= 0)
                z = 1;
                return
            end

            if isempty(obj.mainAxes) || ~isvalid(obj.mainAxes)
                z = 1;
                return
            end

            xLevel = diff(obj.mainAxes.XLim) / sz(2);
            yLevel = diff(obj.mainAxes.YLim) / sz(1);

            % The viewport is aspect-locked, so these should match. Use the larger
            % visible fraction to be conservative if MATLAB reports tiny numerical
            % differences after limit updates.
            z = max([xLevel,yLevel]);
            z = min(max(z, 1 / obj.Zoom_.MaxFactor), 1 / obj.Zoom_.MinFactor);
        end

        function f = get.ZoomFactor(obj)
        %GET.ZOOMFACTOR Return the current visual magnification factor.
            %ZOOMFACTOR  Visual magnification factor, equal to 1/ZoomLevel.

            f = obj.clampZoomFactor(1 / obj.ZoomLevel);
        end

        function factors = getZoomFactors(obj)
        %GETZOOMFACTORS Return supported preset visual zoom factors.
            factors = obj.Zoom_.PresetFactors;
        end

        function S = getViewport(obj)
        %GETVIEWPORT Return current aspect-locked viewport state.
        %
        %   S = ax.getViewport() returns a struct with image-space XLim/YLim,
        %   Center, Size, ZoomLevel, and ZoomFactor. The returned limits are the
        %   authoritative view state used by both ImageAxes and the Zoom tool.

            xlim = obj.mainAxes.XLim;
            ylim = obj.mainAxes.YLim;

            S = struct( ...
                "XLim", xlim, ...
                "YLim", ylim, ...
                "Center", [mean(xlim), mean(ylim)], ...
                "Size", [diff(xlim), diff(ylim)], ...
                "ZoomLevel", obj.ZoomLevel, ...
                "ZoomFactor", obj.ZoomFactor);
        end

        function setViewportLimits(obj,xlim,ylim)
        %SETVIEWPORTLIMITS Set viewport from requested image-space limits.
        %
        %   ax.setViewportLimits(xlim,ylim) treats the requested limits as a target
        %   region but still preserves ImageAxes' image aspect ratio. If the
        %   requested width and height do not match the image aspect ratio, the
        %   resulting viewport is the largest aspect-correct view that fits inside
        %   that requested region, centered on the requested region.

            center = [mean(xlim), mean(ylim)];
            requestedSize = [diff(xlim), diff(ylim)];
            obj.setViewportCenterAndSize(center,requestedSize);
        end

        function setViewportCenter(obj,center)
        %SETVIEWPORTCENTER Move the current viewport to a new center.

            obj.setViewportCenterAndZoomFactor(center,obj.ZoomFactor);
        end

        function setViewportSize(obj,viewportSize)
        %SETVIEWPORTSIZE Set viewport size while preserving current center.
        %
        %   viewportSize is [width height] in image pixels. Non-aspect-matched
        %   requests are normalized using the same policy as setViewportLimits.

            obj.setViewportCenterAndSize(obj.currentViewCenter(),viewportSize);
        end

        function setViewportCenterAndSize(obj,center,viewportSize)
        %SETVIEWPORTCENTERANDSIZE Set viewport center and requested size.

            factor = obj.zoomFactorFromViewportSize(viewportSize);
            obj.setViewportCenterAndZoomFactor(center,factor);
        end

        function setViewportCenterAndZoomFactor(obj,center,factor)
        %SETVIEWPORTCENTERANDZOOMFACTOR Set viewport center and magnification.

            [xLimits,yLimits] = obj.getCenterAnchoredViewportLimits(center,factor);
            obj.applyViewportLimits(xLimits,yLimits);

            obj.Zoom_.LastCursorXY = [mean(xLimits), mean(yLimits)];
            obj.Zoom_.LastFactor = obj.ZoomFactor;
        end

        function resetViewport(obj,opts)
        %RESETVIEWPORT Restore full-image viewport limits.
        %
        %   resetViewport() is a public view reset, so it clears the saved zoom
        %   anchor/factor. Internal callers that are temporarily showing the full
        %   image, such as disableZoom, can preserve that state.

            arguments
                obj
                opts.PreserveZoomState (1,1) logical = false
            end

            if ~opts.PreserveZoomState
                obj.Zoom_.LastCursorXY = [];
                obj.Zoom_.LastFactor = 1;
                obj.clearFollowCursorAnchor();
            end

            obj.staticAxes.XLim = obj.defaultXLim;
            obj.staticAxes.YLim = obj.defaultYLim;
            obj.applyViewportLimits(obj.defaultXLim,obj.defaultYLim);
        end

        function setZoomFactor(obj, factor)
        %SETZOOMFACTOR Set the current visual zoom factor.
            obj.setViewportCenterAndZoomFactor(obj.currentViewCenter(),factor);
        end

        function setZoomLevel(obj, level)
        %SETZOOMLEVEL Set the current visible-image fraction.
            obj.setZoomFactor(1 ./ level);
        end

        function setZoomFactorAtCursor(obj, factor)
        %SETZOOMFACTORATCURSOR Set visual zoom factor around the cursor.
            obj.setZoomLevelAtCursor(1 ./ factor);
        end

        function setZoomLevelAtCursor(obj, level)
        %SETZOOMLEVELATCURSOR Set visible-image fraction around the cursor.
            factor = obj.zoomLevelToFactor(level);
            oldCenter = obj.currentViewCenter();
            oldXLim = obj.mainAxes.XLim;
            oldYLim = obj.mainAxes.YLim;

            if ~obj.ZoomEnabled
                obj.setViewportCenterAndZoomFactor(oldCenter,factor);
                return
            end

            XY = obj.cursorPosition;
            if isempty(XY)
                obj.applyCenterAnchoredZoomLims(oldCenter,factor);
            else
                obj.applyCursorAnchoredZoomLims(XY,oldXLim,oldYLim,factor);
            end
        end

        function stepZoomPresetAtCursor(obj, direction)
        %STEPZOOMPRESETATCURSOR Move to the next preset zoom factor at cursor.
            direction = sign(direction);
            if direction == 0
                return
            end

            factors = sort(obj.getZoomFactors(), 'ascend');
            currentFactor = obj.ZoomFactor;
            tol = 1e-10;

            if direction > 0
                idx = find(factors > currentFactor + tol, 1, 'first');
            else
                idx = find(factors < currentFactor - tol, 1, 'last');
            end

            if isempty(idx)
                return
            end

            obj.setZoomFactorAtCursor(factors(idx));
        end

        function stepZoomContinuousAtCursor(obj, direction, multiplier)
        %STEPZOOMCONTINUOUSATCURSOR Apply multiplicative zoom step at cursor.
            arguments
                obj
                direction (1,1) double
                multiplier (1,1) double {mustBeGreaterThan(multiplier,1)}
            end

            direction = sign(direction);
            if direction == 0
                return
            end

            factor = obj.ZoomFactor .* multiplier .^ direction;
            obj.setZoomFactorAtCursor(factor);
        end

        function enableZoom(obj)
            %ENABLEZOOM  Enable zoom navigation.
            %
            %   Shows the full-image and zoomed-view miniature boxes, then applies
            %   the current ZoomLevel around the best available anchor:
            %
            %       1. most recent image-space zoom anchor
            %       2. current image-space cursor position in mainAxes
            %       3. image center
            %
            %   Stored anchors are preferred so toolbar clicks used to re-enable
            %   zoom do not accidentally move the viewport box toward the toolbar.
            %
            %   If FollowCursor is already enabled, a follow-cursor anchor is
            %   calibrated afterward so the next mouse move does not jump.

            if obj.ZoomEnabled
                return
            end

            oldXLim = obj.mainAxes.XLim;
            oldYLim = obj.mainAxes.YLim;
            obj.Zoom_.Enabled = true;

            targetFactor = obj.ZoomFactor;

            % Prefer the most recent image-space zoom anchor.
            XY = [];
            useStoredAnchor = false;
            if isfield(obj.Zoom_,'LastCursorXY')
                XY = obj.Zoom_.LastCursorXY;
                useStoredAnchor = ~isempty(XY);
            end

            if useStoredAnchor && isfield(obj.Zoom_,'LastFactor') && ...
                    ~isempty(obj.Zoom_.LastFactor)
                targetFactor = obj.Zoom_.LastFactor;
            end

            % Fall back to the current image coordinate under the cursor.
            if isempty(XY)
                XY = obj.cursorPosition;
            end

            % Final fallback: center of the image
            if isempty(XY)
                sz = obj.RenderSourceSize;
                XY = [(sz(2) + 1)/2, (sz(1) + 1)/2];
            end

            if useStoredAnchor
                obj.applyCenterAnchoredZoomLims(XY,targetFactor);
            else
                obj.applyCursorAnchoredZoomLims(XY,oldXLim,oldYLim,targetFactor);
            end

            if obj.FollowCursorEnabled
                obj.calibrateFollowCursorAnchor(obj.cursorPositionStatic);
            end

            % A mode change is part of linked Viewport state even when the
            % current limits happen to remain at the full-image view.
            if ~obj.SuppressViewportChanged_ && ...
                    isequaln(oldXLim,obj.mainAxes.XLim) && ...
                    isequaln(oldYLim,obj.mainAxes.YLim)
                notify(obj,'ViewportChanged');
            end
        end

        function disableZoom(obj)
            %DISABLEZOOM  Disable zoom navigation and restore full-image view.

            if ~obj.ZoomEnabled
                return
            end

            oldXLim = obj.mainAxes.XLim;
            oldYLim = obj.mainAxes.YLim;
            % Remember the current view center before restoring full-image limits.
            % Re-enabling zoom should return to the same region, not to wherever
            % the cursor happens to be when a toolbar button is clicked.
            obj.Zoom_.LastCursorXY = obj.currentViewCenter();
            obj.Zoom_.LastFactor = obj.ZoomFactor;

            % Set the semantic mode before resetViewport emits the linked state.
            obj.Zoom_.Enabled = false;

            % Restore full-image limits while preserving the stored zoom anchor.
            obj.resetViewport(PreserveZoomState=true);

            obj.clearFollowCursorAnchor();

            if ~obj.SuppressViewportChanged_ && ...
                    isequaln(oldXLim,obj.mainAxes.XLim) && ...
                    isequaln(oldYLim,obj.mainAxes.YLim)
                notify(obj,'ViewportChanged');
            end
        end

        function toggleZoomEnabled(obj)
            %TOGGLEZOOMENABLED  Flip state of ZoomEnabled.

            obj.ZoomEnabled = ~obj.Zoom_.Enabled;
        end

        function increaseZoom(obj)
            %INCREASEZOOM  Step forward to the next preset ZoomLevel.
            %
            %   The new view is anchored around the current image-space cursor
            %   position so the pixel under the cursor remains under the cursor as
            %   much as image bounds allow.
            obj.stepZoomPresetAtCursor(1);
        end

        function decreaseZoom(obj)
            %DECREASEZOOM  Step backward to the previous preset ZoomLevel.
            %
            %   The new view is anchored around the current image-space cursor
            %   position so the pixel under the cursor remains under the cursor as
            %   much as image bounds allow.
            obj.stepZoomPresetAtCursor(-1);
        end

        function enableFollowCursor(obj)
            %ENABLEFOLLOWCURSOR  Enable cursor-follow navigation.
            %
            %   If zoom is active, this records the current cursor/view relationship
            %   as a no-jump anchor. Subsequent mouse motion follows smoothly from
            %   that anchor toward the reachable image edges.

            if obj.FollowCursorEnabled
                return
            end

            obj.FollowCursor_.Enabled = true;

            if obj.ZoomEnabled
                obj.calibrateFollowCursorAnchor(obj.cursorPositionStatic);
            end

            if ~obj.SuppressViewportChanged_
                notify(obj,'ViewportChanged');
            end
        end

        function disableFollowCursor(obj)
            %DISABLEFOLLOWCURSOR  Disable cursor-follow navigation.
            %
            %   The current zoomed view remains where it is. The cursor-follow anchor
            %   is cleared so the next enable creates a fresh no-jump anchor at the
            %   then-current cursor/view relationship.

            if ~obj.FollowCursorEnabled
                return
            end

            obj.FollowCursor_.Enabled = false;
            obj.clearFollowCursorAnchor();

            if ~obj.SuppressViewportChanged_
                notify(obj,'ViewportChanged');
            end
        end

        function toggleFollowCursorEnabled(obj)
            %TOGGLEFOLLOWCURSORENABLED  Flip state of FollowCursorEnabled.

            obj.FollowCursorEnabled = ~obj.FollowCursor_.Enabled;
        end

    end

    %% Axes linking
    % Link-group status writable only by ImageAxesLinkManager.
    properties (SetAccess=?matlabx.ui.axes.ImageAxesLinkManager)
        % Whether this axes belongs to an active link group.
        hasLinks        (1,1) logical = false
    end

    % Link-group peers, properties, and synchronization listeners.
    properties (Access=?matlabx.ui.axes.ImageAxesLinkManager)
        % Other ImageAxes instances in the current link group.
        linkedAxes      (1,:) = []
        % Property names synchronized across the current link group.
        linkedProps     (1,:) cell = {}
        % Listeners that propagate linked state changes.
        LinkListener    event.listener
    end

    methods

        function addLink(obj, links, props)
            %ADDLINK Link selected ImageAxes properties across multiple axes.
            %
            % The link is bidirectional: this axes listens for changes and pushes
            % them to every linked axes, and each linked axes does the same for the
            % same property set. Ordinary entries are SetObservable properties;
            % "Viewport" is a semantic state backed by ViewportChanged.

            arguments
                obj     (1,1) matlabx.ui.axes.ImageAxes
                links   (1,:) matlabx.ui.axes.ImageAxes
                props   (1,:) cell = matlabx.ui.axes.ImageAxes.getLinkableProperties()
            end

            matlabx.ui.axes.ImageAxesLinkManager.add(obj, links, props);
        end

        function removeLinks(obj)
            %REMOVELINKS Remove all links from this ImageAxes link group.
            %
            % Calling this on any linked axes disconnects the whole group by clearing
            % peer references, deleting link listeners, and resetting link state.

            matlabx.ui.axes.ImageAxesLinkManager.remove(obj);
        end

        function syncPeersToSelf(obj,~,evt)
            %SYNCPEERSTOSELF Propagate a linked property change to linked axes.
            matlabx.ui.axes.ImageAxesLinkManager.syncPeersToSource(obj, evt);
        end

        function syncSelfFromFirstLinkedPeer(obj)
            %SYNCSELFFROMFIRSTLINKEDPEER Re-apply linked state after data reset.
            %
            % Replacing ImageData rebuilds view/display state from the new image.
            % That internal rebuild bypasses the observable linked-property
            % setters, so this axes explicitly pulls linked values back from an
            % existing peer before the final render.

            matlabx.ui.axes.ImageAxesLinkManager.syncFromFirstPeer(obj);
        end

        function syncSelfToLinkSource(obj, source, props)
            %SYNCSELFTOLINKSOURCE Pull linked property values from source.
            %
            % The local link listener is disabled while values are applied so a
            % data-reset reconciliation does not push startup defaults or partially
            % synchronized values back out to the rest of the link group.

            matlabx.ui.axes.ImageAxesLinkManager.syncFromSource(obj, source, props);
        end

    end

    methods (Access=?matlabx.ui.axes.ImageAxesLinkManager)

        function state = getLinkedViewportState(obj)
        %GETLINKEDVIEWPORTSTATE Return the atomic state shared by Viewport links.
            viewport = obj.getViewport();
            state = struct( ...
                'Center',viewport.Center, ...
                'ZoomFactor',viewport.ZoomFactor, ...
                'ZoomEnabled',obj.ZoomEnabled, ...
                'FollowCursorEnabled',obj.FollowCursorEnabled);
        end

        function applyLinkedViewportState(obj,state)
        %APPLYLINKEDVIEWPORTSTATE Apply view and Zoom controller state once.
        %   Use an installed Zoom tool's ordinary lifecycle so its Enabled flag,
        %   toolbar value, and viewport-box preference remain coherent.
            oldViewport = obj.getViewport();
            oldZoomEnabled = obj.ZoomEnabled;
            oldFollowCursorEnabled = obj.FollowCursorEnabled;
            obj.SuppressViewportChanged_ = true;
            cleanup = onCleanup(@() obj.restoreViewportNotifications_()); %#ok<NASGU>

            zoomTool = obj.getInstalledTool("Zoom");
            if ~isempty(zoomTool) && isvalid(zoomTool)
                if state.ZoomEnabled
                    zoomTool.enable();
                else
                    zoomTool.disable();
                end
            else
                obj.ZoomEnabled = state.ZoomEnabled;
            end

            if state.ZoomEnabled
                obj.setViewportCenterAndZoomFactor( ...
                    state.Center,state.ZoomFactor);
            else
                obj.resetViewport();
            end

            obj.FollowCursorEnabled = state.FollowCursorEnabled;
            if obj.ZoomEnabled && obj.FollowCursorEnabled
                % This peer is normally inactive while another linked viewer is
                % producing movement. Its UIAxes CurrentPoint can therefore be the
                % last position seen before the pointer left, and must not become a
                % new anchor for the synchronized viewport. The entering viewer
                % establishes a fresh absolute mapping in onEnter instead.
                obj.clearFollowCursorAnchor();
            end

            newViewport = obj.getViewport();
            changed = oldZoomEnabled ~= obj.ZoomEnabled || ...
                oldFollowCursorEnabled ~= obj.FollowCursorEnabled || ...
                ~isequaln(oldViewport.XLim,newViewport.XLim) || ...
                ~isequaln(oldViewport.YLim,newViewport.YLim);
            obj.SuppressViewportChanged_ = false;
            if changed
                notify(obj,'ViewportChanged');
            end
        end

    end







    %% UI helpers
    methods (Access=private)
        %% --- UI refresh helpers ---

        function showInitialToolbar(obj)
        %SHOWINITIALTOOLBAR Reveal the constructed toolbar and release its focus.
            fig = obj.ParentFig;
            if isempty(fig) || ~isvalid(fig)
                return
            end

            if strcmp(fig.Visible, 'on')
                obj.clearInitialToolbarFocusListener();
                obj.mainAxes.Toolbar.Visible = obj.ToolbarVisible_;
                if strcmp(obj.ToolbarVisible_, 'on')
                    obj.releaseToolbarFocus();
                end
            elseif isempty(obj.InitialToolbarFocusListener) || ...
                    ~isvalid(obj.InitialToolbarFocusListener)
                obj.InitialToolbarFocusListener = addlistener(fig, ...
                    'Visible','PostSet',@(~,~) obj.showInitialToolbar());
            end
        end

        function releaseToolbarFocus(obj)
        %RELEASETOOLBARFOCUS Return keyboard focus from the axes toolbar to its figure.
            fig = obj.ParentFig;
            if isempty(fig) || ~isvalid(fig)
                return
            end

            if strcmp(fig.Visible, 'on')
                focus(fig);
            end
        end

        function clearInitialToolbarFocusListener(obj)
        %CLEARINITIALTOOLBARFOCUSLISTENER Remove the pending visibility listener.
            if ~isempty(obj.InitialToolbarFocusListener)
                delete(obj.InitialToolbarFocusListener( ...
                    isvalid(obj.InitialToolbarFocusListener)));
            end
            obj.InitialToolbarFocusListener = event.listener.empty;
        end

        function restoreViewportNotifications_(obj)
        %RESTOREVIEWPORTNOTIFICATIONS_ Recover suppression after errors.
            if ~isempty(obj) && isvalid(obj)
                obj.SuppressViewportChanged_ = false;
            end
        end

        function updateOnResize(obj)
        %UPDATEONRESIZE Recompute and apply the aspect-preserving component layout.
            if ~isvalid(obj); return; end

            if obj.pendingSizeUpdate
                return
            end

            obj.pendingSizeUpdate = true;
            cleanupPendingFlag = onCleanup(@() obj.clearPendingSizeUpdate());

            S = obj.computeResizeLayout();
            if ~S.IsValid
                return
            end

            layoutKey = S.LayoutKey;
            if isequal(layoutKey, obj.LastResizeLayoutKey_)
                return
            end

            matlabx.ui.axes.ImageAxesResizeLayout.apply(obj.sizingGrid, S);
            obj.LastResizeLayoutKey_ = layoutKey;
        end

        function clearPendingSizeUpdate(obj)
        %CLEARPENDINGSIZEUPDATE Clear the resize coalescing flag.
            if isvalid(obj)
                obj.pendingSizeUpdate = false;
            end
        end

        function S = computeResizeLayout(obj)
        %COMPUTERESIZELAYOUT Compute the current aspect-preserving layout.
            S = matlabx.ui.axes.ImageAxesResizeLayout.compute( ...
                obj, ...
                obj.ImageData_.SizeY, ...
                obj.ImageData_.SizeX, ...
                obj.uipanelOverheadPx_);
        end

        function S = getSizeDiagnostics(obj)
        %GETSIZEDIAGNOSTICS Return calculated and realized layout diagnostics.
            S = obj.computeResizeLayout();
            S = matlabx.ui.axes.ImageAxesResizeLayout.addDiagnostics( ...
                S, ...
                obj, ...
                obj.Grid, ...
                obj.sizingGrid, ...
                obj.Panel, ...
                obj.mainAxes, ...
                obj.staticAxes, ...
                LastResizeLayoutKey=obj.LastResizeLayoutKey_, ...
                PendingSizeUpdate=obj.pendingSizeUpdate);
        end

        function S = getDebugStatus(obj, includeSizeDiagnostics)
        %GETDEBUGSTATUS Build the complete ImageAxes debugging report.
            toolStruct = obj.Tools;
            toolNames = string(fieldnames(toolStruct));

            enabledMask = false(size(toolNames));
            for i = 1:numel(toolNames)
                tool = toolStruct.(char(toolNames(i)));
                if isvalid(tool) && tool.Enabled
                    enabledMask(i) = true;
                end
            end
            enabledTools = toolNames(enabledMask);

            S = struct();
            S.Class = string(class(obj));
            S.Name = obj.Name;
            S.IsValid = isvalid(obj);
            S.ParentFigure = string(class(obj.ParentFig));
            S.ImageDataClass = string(class(obj.ImageData_));
            S.ImageSize = [obj.ImageData_.SizeY, obj.ImageData_.SizeX];
            S.NumComponents = obj.NumComponents;
            S.RenderSourceSize = obj.RenderSourceSize;
            S.RenderSourceKind = string(obj.RenderSourceKind);
            S.RenderSourceClass = string(obj.RenderSourceClass);
            S.View = struct( ...
                "C", obj.C, ...
                "Z", obj.Z, ...
                "T", obj.T, ...
                "ShowComposite", string(obj.ShowComposite), ...
                "CLimMode", string(obj.CLimMode), ...
                "ComponentColorMode", string(obj.ComponentColorMode));
            S.Tools = struct( ...
                "Installed", toolNames(:).', ...
                "Enabled", enabledTools(:).');
            S.Zoom = struct( ...
                "ZoomEnabled", obj.ZoomEnabled, ...
                "FollowCursorEnabled", obj.FollowCursorEnabled, ...
                "XLim", obj.mainAxes.XLim, ...
                "YLim", obj.mainAxes.YLim);
            S.UpdateState = struct( ...
                "PendingSizeUpdate", obj.pendingSizeUpdate, ...
                "LastResizeLayoutKey", obj.LastResizeLayoutKey_, ...
                "FirstUpdatePending", obj.FirstUpdatePending);

            if includeSizeDiagnostics
                S.SizeDiagnostics = obj.getSizeDiagnostics();
            end
        end

        function S = getToolStatusSummary(obj)
            %GETTOOLSTATUSSUMMARY Return installed tool names grouped by style.
            toolStruct = obj.Tools;
            toolNames = string(fieldnames(toolStruct));

            stateTools = struct();
            pushTools = strings(1,0);

            for i = 1:numel(toolNames)
                name = toolNames(i);
                tool = toolStruct.(char(name));

                if isempty(tool) || ~isvalid(tool)
                    continue
                end

                switch string(tool.Style)
                    case "state"
                        fieldName = matlab.lang.makeValidName(char(name));
                        stateTools.(fieldName) = string(matlab.lang.OnOffSwitchState(tool.Enabled));
                    case "push"
                        pushTools(end+1) = name; %#ok<AGROW>
                end
            end

            S = struct( ...
                "Installed", toolNames(:).', ...
                "StateTools", stateTools, ...
                "PushTools", pushTools);
        end

        function S = getLinkStatusSummary(obj)
            %GETLINKSTATUSSUMMARY Return compact axes-linking state.
            peerNames = strings(1,0);
            if obj.hasLinks
                for i = 1:numel(obj.linkedAxes)
                    peer = obj.linkedAxes(i);
                    if isempty(peer) || ~isvalid(peer)
                        continue
                    end

                    if strlength(peer.Name) > 0
                        peerNames(end+1) = peer.Name; %#ok<AGROW>
                    else
                        peerNames(end+1) = string(class(peer)); %#ok<AGROW>
                    end
                end
            end

            S = struct( ...
                "HasLinks", obj.hasLinks, ...
                "LinkedPeerCount", numel(peerNames), ...
                "LinkedPeers", peerNames, ...
                "LinkedProperties", string(obj.linkedProps));
        end

        function updateBottomLabelText(obj)
        %UPDATEBOTTOMLABELTEXT Update cursor coordinates, pixel values, and tool status text.
        
            px = obj.activePixel;
        
            if isempty(px), obj.BottomLabel.String ='Hover over image to interact'; return; end
        
            posStr = sprintf('Pixel: (%0.f,%0.f)',px(1),px(2));
        
            if obj.ViewState_.ShowComposite
                activeData = obj.ImageData_.getPlane(obj.ViewState_.C,obj.ViewState_.Z,obj.ViewState_.T);
                activeKind = obj.ImageData_.getComponentKind(obj.ViewState_.C);
                activeClass = obj.ImageData_.getComponentClass(obj.ViewState_.C);
            else
                activeData = obj.RenderSource;
                activeKind = obj.RenderSourceKind;
                activeClass = obj.RenderSourceClass;
            end
        
            switch activeKind
                case 'scalar'
                    switch activeClass
                        case {'double','single'}
                            valStr = sprintf('Intensity: %0.2f', activeData(px(2),px(1)));
                        case {'uint8','uint16'}
                            valStr = sprintf('Intensity: %i', activeData(px(2),px(1)));
                        case 'logical'
                            valStr = sprintf('Value: %i', activeData(px(2),px(1)));
                        otherwise
                            valStr = '';
                    end
                case 'rgb'
                    switch activeClass
                        case {'double','single'}
                            valStr = sprintf('RGB: [%0.2f, %0.2f, %0.2f]', activeData(px(2),px(1),1:3));
                        case {'uint8','uint16'}
                            valStr = sprintf('RGB: [%i, %i, %i]', activeData(px(2),px(1),1:3));
                        otherwise
                            valStr = '';
                    end
                otherwise
                    valStr = '';
            end
        
            tools = obj.ToolManager.prioritySort();
            txt = cell(1,numel(tools));
        
            for i = 1:numel(tools)
                txt{i} = tools{i}.getLabelString();
            end
        
            txt = [posStr, valStr, txt];
            txt(ismember(txt,'')) = [];
            txt = strjoin(txt,' | ');
        
            obj.BottomLabel.String = [' ',txt];
        end

        function updateTopLabelText(obj)
        %UPDATETOPLABELTEXT Update the panel title with current image and view information.
            sizeStr = obj.getImageSizeString();
            bitDepthStr = obj.getImageBitDepthString();
            compStr = obj.getComponentInfoString();
            zStr = obj.getZInfoString();
            tStr = obj.getTInfoString();

            txt = {sizeStr,bitDepthStr,compStr,zStr,tStr};
            % remove empty entries
            txt(ismember(txt,'')) = [];
            % join each fragment with spaced pipe
            txt = strjoin(txt,' | ');
            %obj.TopLabel.String = [' ',txt];

            obj.Panel.Title = txt;
        end

        function updatePointer(obj)
        %UPDATEPOINTER Select the highest-priority pointer requested by installed tools.
            % invalid pixel, set pointer to 'arrow'
            if isempty(obj.activePixel), obj.ParentFig.Pointer = 'arrow'; return; end

            % get cell array of installed tools, sorted by priority
            tools = obj.ToolManager.prioritySort();

            % no tools found, set pointer to 'arrow'
            if isempty(tools), obj.ParentFig.Pointer = 'arrow'; return; end

            for i = 1:numel(tools)
                pointer = tools{i}.getPreferredPointer();

                if isempty(pointer)
                    continue
                end

                switch pointer
                    case 'default'
                        % do nothing (let the pointer be set normally)
                        return
                    otherwise
                        % a valid pointer is returned, set it and return
                        obj.ParentFig.Pointer = pointer;
                        return
                end

            end

            % no valid pointer was returned, set pointer to 'arrow'
            obj.ParentFig.Pointer = 'arrow';

        end

        function updateImageCData(obj)
        %UPDATEIMAGECDATA Render the current display data into the image primitive.
            matlabx.ui.axes.ImageAxesDisplayRenderer.updateImageCData( ...
                obj.hImage, obj.DisplayCData);
            obj.updateImageMask();
        end

        function updateImageMask(obj)
        %UPDATEIMAGEMASK Apply the stored mask to the image primitive alpha data.
            if isempty(obj.hImage) || ~isgraphics(obj.hImage)
                return
            end
            matlabx.ui.axes.ImageAxesDisplayRenderer.updateImageMask( ...
                obj.hImage, obj.Mask_, obj.MaskEnabled_);
        end

        function updateColorbar(obj)
        %UPDATECOLORBAR Update colorbar visibility and limits for the current display.
            matlabx.ui.axes.ImageAxesDisplayRenderer.updateColorbar( ...
                obj.Colorbar, ...
                obj.ImageData_, ...
                obj.ComponentDisplay_, ...
                obj.ViewState_.C);
        end

        function updateAxesColormap(obj)
        %UPDATEAXESCOLORMAP Apply the current component display map to the axes.
            matlabx.ui.axes.ImageAxesDisplayRenderer.updateAxesColormap( ...
                obj.mainAxes, ...
                obj.ComponentDisplay_, ...
                obj.ViewState_.C);
        end

        function updateFontSizes(obj)
        %UPDATEFONTSIZES Apply the configured font size and refresh panel calibration.
            obj.Panel.FontSize = obj.FontSize_;
            obj.BottomLabel.FontSize = obj.FontSize_;
            obj.uipanelOverheadPx_ = obj.UICal.uipanelTopChromeHeightPx(obj.FontSize_);
        end

        function refreshView(obj)
            %REFRESHVIEW Compatibility wrapper for a full view refresh.
            obj.refreshDisplay(ResetView=true);
        end

        function refreshDisplay(obj, opts)
            %REFRESHDISPLAY Update graphics that depend on current render/display state.
            arguments
                obj
                opts.ResetView (1,1) logical = false
                opts.UpdateImage (1,1) logical = true
                opts.UpdateColormap (1,1) logical = true
                opts.UpdateColorbar (1,1) logical = true
                opts.UpdateTopLabel (1,1) logical = true
                opts.UpdateContextMenu (1,1) logical = true
            end

            if opts.UpdateImage
                obj.updateImageCData();
            end

            if opts.UpdateColormap
                obj.updateAxesColormap();
            end

            if opts.UpdateColorbar
                obj.updateColorbar();
            end

            if opts.ResetView
                obj.restoreDefaultLimits();
            end

            if opts.UpdateTopLabel
                obj.updateTopLabelText();
            end

            if opts.UpdateContextMenu
                obj.refreshContextMenu();
            end
        end

        function refreshContextMenu(obj)
        %REFRESHCONTEXTMENU Refresh dynamic context-menu state.
            obj.ContextMenuManager.refresh();
        end


        %% --- UI text helpers ---

        function s = getImageInfoString(obj)
        %GETIMAGEINFOSTRING Return a compact description of the current render source.
            s1 = sprintf(strjoin(repmat({'%i'},1,numel(obj.RenderSourceSize)),'x'),obj.RenderSourceSize);
            s2 = sprintf('%s (%s)',obj.RenderSourceClass,obj.RenderSourceKind);
            s = [s1,' ',s2];
        end

        function s = getComponentInfoString(obj)
        %GETCOMPONENTINFOSTRING Return label text for the current component.
            c = obj.ViewState_.C;
            nm = obj.ImageData_.getComponentName(c);
        
            if strlength(nm) > 0
                base = sprintf('C: %i/%i (%s)', c, obj.NumComponents, char(nm));
            else
                base = sprintf('C: %i/%i', c, obj.NumComponents);
            end
        
            if obj.ViewState_.ShowComposite
                s = [base, ' (composite)'];
            else
                s = base;
            end
        end

        function s = getZInfoString(obj)
        %GETZINFOSTRING Return label text for the current Z plane.
            if obj.ImageData_.SizeZ > 1
                s = sprintf('Z: %i/%i', obj.ViewState_.Z, obj.ImageData_.SizeZ);
            else
                s = '';
            end
        end

        function s = getTInfoString(obj)
        %GETTINFOSTRING Return label text for the current time point.
            if obj.ImageData_.SizeT > 1
                s = sprintf('T: %i/%i', obj.ViewState_.T, obj.ImageData_.SizeT);
            else
                s = '';
            end
        end

        function s = getImageSizeString(obj)
        %GETIMAGESIZESTRING Return formatted spatial image dimensions.
            sz = obj.RenderSourceSize;
            % list size up to but not including the first singleton dimension
            idx = find(sz==1,1,"first");
            if ~isempty(idx) && idx>2
                idx = idx-1;
                sz = sz(1:idx);
            end
            s = sprintf(strjoin(repmat({'%i'},1,numel(sz)),'x'),sz);
        end

        function s = getImageBitDepthString(obj)
        %GETIMAGEBITDEPTHSTRING Return formatted image class and bit-depth information.

            if strcmpi(obj.RenderSourceKind,'rgb')
                s = '';
                return
            end

            switch obj.RenderSourceClass
                case 'uint8'
                    s = '8-bit';
                case 'uint16'
                    s = '16-bit';
                case 'single'
                    s = '32-bit float';
                case 'double'
                    s = '64-bit float';
                case 'logical'
                    s = 'binary';
            end
        end

    end

    %% Public API: image model, render source, and display state
    methods
    
        % --- ImageData: canonical source image object ---
        function v = get.ImageData(obj)
        %GET.IMAGEDATA Return the current image data value.
            v = obj.ImageData_;
        end
    
        function set.ImageData(obj, val)
        %SET.IMAGEDATA Set image data and update dependent state.
            arguments
                obj
                val (1,1) matlabx.image.Image5D
            end

            oldSummary = obj.getImageDataEventSummary_();
            obj.ImageData_ = val;
            obj.Mask_ = [];
            obj.syncViewStateToImageData();
            obj.syncSelfFromFirstLinkedPeer();
            obj.syncRenderSourceToView(ResetView=true);
            obj.notifyImageDataChanged_(oldSummary, obj.getImageDataEventSummary_());
        end
    
        % --- CData: compatibility alias for raw image input/current source ---
        function v = get.CData(obj)
        %GET.CDATA Return the current cdata value.
            v = obj.RenderSource;
        end
    
        function set.CData(obj, cdata)
        %SET.CDATA Replace ImageData from a raw MATLAB image value.
            % Convenience wrapper to set ImageData without constructing an Image5D.
            if isempty(cdata)
                cdata = matlabx.ui.axes.ImageAxes.placeholderImage();
            end

            oldSummary = obj.getImageDataEventSummary_();
            obj.ImageData_ = matlabx.image.Image5D.fromComponents(cdata);
            obj.Mask_ = [];

            obj.syncViewStateToImageData();
            obj.syncSelfFromFirstLinkedPeer();
            obj.syncRenderSourceToView(ResetView=true);
            obj.notifyImageDataChanged_(oldSummary, obj.getImageDataEventSummary_());
        end

        function value = get.Mask(obj)
        %GET.MASK Return the current mask value.
            value = obj.Mask_;
        end

        function set.Mask(obj, value)
        %SET.MASK Set mask and update dependent state.
            if ~isempty(value) && (~islogical(value) || ~ismatrix(value) || ...
                    ~isequal(size(value), [obj.ImageData_.SizeY obj.ImageData_.SizeX]))
                error('matlabx:ui:axes:ImageAxes:InvalidMask', ...
                    'Mask must be empty or a logical array matching the image Y-by-X dimensions.');
            end
            if isempty(value), value = []; end
            previous = obj.Mask_;
            obj.Mask_ = value;
            obj.updateImageMask();
            obj.refreshContextMenu();
            obj.notifyDisplayStateChanged_("Mask", [], previous, value);
        end

        function value = get.MaskEnabled(obj)
        %GET.MASKENABLED Return the current mask enabled value.
            value = obj.MaskEnabled_;
        end

        function set.MaskEnabled(obj, value)
        %SET.MASKENABLED Set mask enabled and update dependent state.
            previous = obj.MaskEnabled_;
            obj.MaskEnabled_ = value;
            obj.updateImageMask();
            obj.refreshContextMenu();
            obj.notifyDisplayStateChanged_("MaskEnabled", [], previous, value);
        end

        function value = get.OverlaysVisible(obj)
        %GET.OVERLAYSVISIBLE Return the current overlays visible value.
            value = obj.OverlaysVisible_;
        end

        function set.OverlaysVisible(obj, value)
        %SET.OVERLAYSVISIBLE Set overlays visible and update dependent state.
            previous = obj.OverlaysVisible_;
            obj.OverlaysVisible_ = value;
            if ~isempty(obj.OverlayManager)
                obj.OverlayManager.refreshVisibility();
            end
            obj.refreshContextMenu();
            obj.notifyDisplayStateChanged_("OverlaysVisible", [], previous, value);
        end

        function toggleOverlays(obj)
        %TOGGLEOVERLAYS Show/hide overlays without changing their own Visible flags.
            obj.OverlaysVisible = ~obj.OverlaysVisible;
        end

        function toggleMask(obj)
        %TOGGLEMASK Toggle display masking without changing the stored mask.
            obj.MaskEnabled = ~obj.MaskEnabled;
        end

        function toggleToolbar(obj)
        %TOGGLETOOLBAR Show or hide the toolbar without changing installed tools.
            obj.ToolbarVisible = ~obj.ToolbarVisible;
        end

        % --- RenderSource: selected plane or computed composite ---
        function v = get.RenderSource(obj)
        %GET.RENDERSOURCE Return the current render source value.
            v = obj.RenderSource_;
        end

        function v = get.RenderSourceSize(obj)
        %GET.RENDERSOURCESIZE Return the current render source size value.
            if obj.ViewState_.ShowComposite
                v = size(obj.RenderSource_);
            else
                v = obj.ImageData_.getComponentSize(obj.ViewState_.C);
            end
        end
    
        function v = get.RenderSourceKind(obj)
        %GET.RENDERSOURCEKIND Return the current render source kind value.
            if obj.ViewState_.ShowComposite
                v = 'rgb';
            else
                v = obj.ImageData_.getComponentKind(obj.ViewState_.C);
            end
        end
    
        function v = get.RenderSourceClass(obj)
        %GET.RENDERSOURCECLASS Return the current render source class value.
            if obj.ViewState_.ShowComposite
                v = class(obj.RenderSource_);
            else
                v = obj.ImageData_.getComponentClass(obj.ViewState_.C);
            end
        end

        % --- CData metadata compatibility aliases ---
        function v = get.CDataSize(obj)
        %GET.CDATASIZE Return the current cdata size value.
            v = obj.RenderSourceSize;
        end
        function v = get.CDataKind(obj)
        %GET.CDATAKIND Return the current cdata kind value.
            v = obj.RenderSourceKind;
        end
        function v = get.CDataClass(obj)
        %GET.CDATACLASS Return the current cdata class value.
            v = obj.RenderSourceClass;
        end

        % --- DisplayCData: graphics-ready image CData ---
        function v = get.DisplayCData(obj)
        %GET.DISPLAYCDATA Return the current display cdata value.
            v = matlabx.ui.axes.ImageAxesDisplayRenderer.getDisplayCData( ...
                obj.RenderSource_, ...
                obj.ImageData_, ...
                obj.ComponentDisplay_, ...
                obj.ViewState_);
        end

        % --- CLim ---
        function v = get.CLim(obj)
        %GET.CLIM Return the current clim value.
            idx = obj.ViewState_.C;
            clim = obj.ComponentDisplay_(idx).CLim;
    
            if isempty(clim)
                v = [0 1];
            else
                v = clim;
            end
        end
    
        function set.CLim(obj, val)
        %SET.CLIM Set clim and update dependent state.
            obj.setComponentCLim(double(val), obj.ViewState_.C);
        end

        % --- CLimMode ---
        function v = get.CLimMode(obj)
        %GET.CLIMMODE Return the current clim mode value.
            v = obj.ViewState_.CLimMode;
        end
    
        function set.CLimMode(obj, val)
        %SET.CLIMMODE Set clim mode and update dependent state.
            if strcmp(obj.ViewState_.CLimMode, val)
                return
            end

            previousMode = obj.ViewState_.CLimMode;
            previousCLims = obj.ComponentCLims;
            obj.ViewState_.CLimMode = val;
            changed = true;
    
            if strcmp(val, 'auto')
                clims = cell(1, obj.NumComponents);
                for i = 1:obj.NumComponents
                    clims{i} = obj.ImageData_.getComponentDataRange(i);
                end
                changed = obj.setComponentCLims_(clims, 1:obj.NumComponents);
            end

            if changed
                obj.updateDisplayMapping();
            end

            obj.notifyDisplayStateChanged_( ...
                "CLimMode", [], previousMode, obj.ViewState_.CLimMode);

            if strcmp(val, 'auto') && ~isequaln(previousCLims, obj.ComponentCLims)
                obj.notifyDisplayStateChanged_( ...
                    "ComponentCLims", 1:obj.NumComponents, previousCLims, obj.ComponentCLims);
            end
        end
    
        % --- NumComponents ---
        function v = get.NumComponents(obj)
        %GET.NUMCOMPONENTS Return the current num components value.
            v = obj.ImageData_.NumComponents;
        end

        % --- MultiComponent ---
        function v = get.MultiComponent(obj)
        %GET.MULTICOMPONENT Return the current multi component value.
            v = obj.ImageData_.MultiComponent;
        end

        % --- MultiComponentKind ---
        function v = get.MultiComponentKind(obj)
        %GET.MULTICOMPONENTKIND Return the current multi component kind value.
            v = obj.ImageData_.MultiComponentKind;
        end

        % --- CanMergeComponents ---
        function tf = get.CanMergeComponents(obj)
        %GET.CANMERGECOMPONENTS Return the current can merge components value.
            tf = obj.ImageData_.CanMergeComponents;
        end


        % --- ShowComposite ---
        function v = get.ShowComposite(obj)
        %GET.SHOWCOMPOSITE Return the current show composite value.
            v = matlab.lang.OnOffSwitchState(obj.ViewState_.ShowComposite);
        end
    
        function set.ShowComposite(obj, val)
        %SET.SHOWCOMPOSITE Set show composite and update dependent state.
            newVal = logical(val) && obj.CanMergeComponents;

            if obj.ViewState_.ShowComposite == newVal
                return
            end

            obj.ViewState_.ShowComposite = newVal;
            obj.syncRenderSourceToView();
        end
    
        % --- toggleComposite ---
        function toggleComposite(obj)
        %TOGGLECOMPOSITE Toggle composite.
            obj.ShowComposite = ~obj.ViewState_.ShowComposite;
        end


        %% C/Z/T control

        % --- nextComponent ---
        function nextComponent(obj)
        %NEXTCOMPONENT Select the next component, wrapping at the end.
            obj.C = matlabx.utils.math.wrapStep(obj.C,1,1,obj.NumComponents);
        end
    
        % --- previousComponent ---
        function previousComponent(obj)
        %PREVIOUSCOMPONENT Select the previous component, wrapping at the beginning.
            obj.C = matlabx.utils.math.wrapStep(obj.C,-1,1,obj.NumComponents);
        end
    
        % --- C ---
        function v = get.C(obj)
        %GET.C Return the current c value.
            v = obj.ViewState_.C;
        end
    
        function set.C(obj, val)
        %SET.C Set c and update dependent state.
            newVal = clip(val, 1, obj.NumComponents);

            if obj.ViewState_.C == newVal
                return
            end

            obj.ViewState_.C = newVal;
            obj.syncRenderSourceToView();
        end


        % --- nextZ ---
        function nextZ(obj)
        %NEXTZ Select the next Z plane, wrapping at the end.
            obj.Z = matlabx.utils.math.wrapStep(obj.Z,1,1,obj.ImageData_.SizeZ);
        end
    
        % --- previousZ ---
        function previousZ(obj)
        %PREVIOUSZ Select the previous Z plane, wrapping at the beginning.
            obj.Z = matlabx.utils.math.wrapStep(obj.Z,-1,1,obj.ImageData_.SizeZ);
        end
    
        % --- Z ---
        function v = get.Z(obj)
        %GET.Z Return the current z value.
            v = obj.ViewState_.Z;
        end
    
        function set.Z(obj, val)
        %SET.Z Set z and update dependent state.
            newVal = clip(val, 1, obj.ImageData_.SizeZ);

            if obj.ViewState_.Z == newVal
                return
            end

            obj.ViewState_.Z = newVal;
            obj.syncRenderSourceToView();
        end

        % --- nextT ---
        function nextT(obj)
        %NEXTT Select the next time point, wrapping at the end.
            obj.T = matlabx.utils.math.wrapStep(obj.T,1,1,obj.ImageData_.SizeT);
        end
    
        % --- previousT ---
        function previousT(obj)
        %PREVIOUST Select the previous time point, wrapping at the beginning.
            obj.T = matlabx.utils.math.wrapStep(obj.T,-1,1,obj.ImageData_.SizeT);
        end
    
        % --- T ---
        function v = get.T(obj)
        %GET.T Return the current t value.
            v = obj.ViewState_.T;
        end
    
        function set.T(obj, val)
        %SET.T Set t and update dependent state.
            newVal = clip(val, 1, obj.ImageData_.SizeT);

            if obj.ViewState_.T == newVal
                return
            end

            obj.ViewState_.T = newVal;
            obj.syncRenderSourceToView();
        end


        %% Component-specific set/get

        % --- Colormap ---
        function v = get.Colormap(obj)
        %GET.COLORMAP Return the current colormap value.
            v = obj.ComponentDisplay_(obj.ViewState_.C).DisplayMap;
        end

        function set.Colormap(obj, val)
        %SET.COLORMAP Set colormap and update dependent state.
            idx = obj.ViewState_.C;
            obj.setComponentColormap(double(val), idx);
        end


        % --- ComponentColors ---
        function val = get.ComponentColors(obj)
        %GET.COMPONENTCOLORS Return the current component colors value.
            val = cell(1, obj.NumComponents);
            for i = 1:obj.NumComponents
                val{i} = char(obj.ComponentDisplay_(i).ColorName);
            end
        end
    
        function set.ComponentColors(obj, val)
        %SET.COMPONENTCOLORS Set component colors and update dependent state.
            obj.validateFullComponentCell(val, 'ComponentColors');

            previousValue = obj.ComponentColors;
            changed = obj.setComponentColors_(val, 1:obj.NumComponents);

            if changed
                obj.updateAllDisplayMaps();
                obj.updateDisplayMapping();
                obj.notifyDisplayStateChanged_( ...
                    "ComponentColors", 1:obj.NumComponents, previousValue, obj.ComponentColors);
            end
        end
    
        % --- ComponentColormaps ---
        function val = get.ComponentColormaps(obj)
        %GET.COMPONENTCOLORMAPS Return the current component colormaps value.
            val = cell(1, obj.NumComponents);
            for i = 1:obj.NumComponents
                val{i} = obj.ComponentDisplay_(i).Colormap;
            end
        end
    
        function set.ComponentColormaps(obj, val)
        %SET.COMPONENTCOLORMAPS Set component colormaps and update dependent state.
            obj.validateFullComponentCell(val, 'ComponentColormaps');

            previousValue = obj.ComponentColormaps;
            changed = obj.setComponentColormaps_(val, 1:obj.NumComponents);

            if changed
                obj.updateAllDisplayMaps();
                obj.updateDisplayMapping();
                obj.notifyDisplayStateChanged_( ...
                    "ComponentColormaps", 1:obj.NumComponents, previousValue, obj.ComponentColormaps);
            end
        end

        % --- ComponentColorMode ---
        function v = get.ComponentColorMode(obj)
        %GET.COMPONENTCOLORMODE Return the current component color mode value.
            v = obj.ViewState_.ComponentColorMode;
        end
    
        function set.ComponentColorMode(obj, val)
        %SET.COMPONENTCOLORMODE Set component color mode and update dependent state.
            if strcmp(obj.ViewState_.ComponentColorMode, val)
                return
            end

            previousValue = obj.ViewState_.ComponentColorMode;
            obj.ViewState_.ComponentColorMode = val;
            obj.updateAllDisplayMaps();
            obj.updateDisplayMapping();
            obj.notifyDisplayStateChanged_( ...
                "ComponentColorMode", [], previousValue, obj.ViewState_.ComponentColorMode);
        end

        % --- ComponentCLims ---
        function val = get.ComponentCLims(obj)
        %GET.COMPONENTCLIMS Return the current component clims value.
            val = cell(1, obj.NumComponents);
            for i = 1:obj.NumComponents
                val{i} = obj.ComponentDisplay_(i).CLim;
            end
        end
    
        function set.ComponentCLims(obj, val)
        %SET.COMPONENTCLIMS Set component clims and update dependent state.
            obj.validateFullComponentCell(val, 'ComponentCLims');

            previousValue = obj.ComponentCLims;
            previousMode = obj.ViewState_.CLimMode;
            changed = obj.setComponentCLims_(val, 1:obj.NumComponents);
            obj.ViewState_.CLimMode = 'manual';

            if changed
                obj.updateDisplayMapping();
                obj.notifyDisplayStateChanged_( ...
                    "ComponentCLims", 1:obj.NumComponents, previousValue, obj.ComponentCLims);
            end

            if ~strcmp(previousMode, obj.ViewState_.CLimMode)
                obj.notifyDisplayStateChanged_( ...
                    "CLimMode", [], previousMode, obj.ViewState_.CLimMode);
            end
        end

        % --- setComponentCLim ---
        function setComponentCLim(obj, clim, idx)
        %SETCOMPONENTCLIM Set one CLim on the current component or selected components.
            arguments
                obj (1,1) matlabx.ui.axes.ImageAxes
                clim (1,2) double
                idx (:,1) = []
            end
    
            if isempty(idx)
                idx = obj.C;
            end
    
            idx = obj.validateComponentIndices(idx);
            clims = obj.ComponentCLims;
            clims(idx) = repmat({double(clim)}, 1, numel(idx));
            obj.ComponentCLims = clims;
        end


        % --- chooseColormap ---
        function chooseColormap(obj)
        %CHOOSECOLORMAP Open the colormap selector for the current component.
            component = obj.C;
            previousMap = obj.ComponentColormaps{component};
            previousMode = obj.ComponentColorMode;

            [cmap, accepted] = matlabx.app.ColormapSelector( ...
                PreviewFcn=@(preview) obj.setComponentColormap(preview, component));

            if accepted
                obj.setComponentColormap(cmap, component);
            elseif ~isequal(obj.ComponentColormaps{component}, previousMap) || ...
                    ~strcmp(obj.ComponentColorMode, previousMode)
                obj.setComponentColormap(previousMap, component);
                obj.ComponentColorMode = previousMode;
            end
        end

        % --- setComponentColormap ---
        function setComponentColormap(obj, cmap, idx)
        %SETCOMPONENTCOLORMAP Set one colormap on the current component or selected components.
            arguments
                obj (1,1) matlabx.ui.axes.ImageAxes
                cmap (256,3) double
                idx (:,1) = []
            end

            if isempty(idx)
                idx = obj.C;
            end

            idx = obj.validateComponentIndices(idx);

            obj.ComponentColorMode = 'luts';
            cmaps = obj.ComponentColormaps;
            cmaps(idx) = repmat({double(cmap)}, 1, numel(idx));
            obj.ComponentColormaps = cmaps;
        end

        % --- setComponentColor ---
        function setComponentColor(obj, colorName, idx)
        %SETCOMPONENTCOLOR Set one named color on the current component or selected components.
            arguments
                obj (1,1) matlabx.ui.axes.ImageAxes
                colorName
                idx (:,1) = []
            end

            if isempty(idx)
                idx = obj.C;
            end

            idx = obj.validateComponentIndices(idx);
            obj.ComponentColorMode = 'colors';
            colors = obj.ComponentColors;
            colors(idx) = repmat({colorName}, 1, numel(idx));
            obj.ComponentColors = colors;
        end


    end

    %% Private helpers: ImageData/DisplayState/ViewState
    methods (Access=private)
    
        function syncViewStateToImageData(obj)
        %SYNCVIEWSTATETOIMAGEDATA Reconcile view and component display state with ImageData.
            n = obj.NumComponents;
    
            % clip C, Z, T to valid range
            obj.ViewState_.C = clip(obj.ViewState_.C, 1, n);
            obj.ViewState_.Z = clip(obj.ViewState_.Z, 1, obj.ImageData_.SizeZ);
            obj.ViewState_.T = clip(obj.ViewState_.T, 1, obj.ImageData_.SizeT);
    
            % resize per-component display state while preserving old values
            obj.ComponentDisplay_ = obj.initializeComponentDisplayState(n);
    
            % composite only allowed when mergeable
            if obj.ViewState_.ShowComposite && ~obj.ImageData_.CanMergeComponents
                obj.ViewState_.ShowComposite = false;
            end
        end
    
        function displayState = initializeComponentDisplayState(obj, n)
        %INITIALIZECOMPONENTDISPLAYSTATE Build per-component display state for the current image.
            old = obj.ComponentDisplay_;

            displayState = repmat(matlabx.ui.axes.ImageAxesComponentDisplayState(), 1, n);

            defaultColors = matlabx.ui.axes.ImageAxes.getColorNames();
    
            % initialize component display state using info from ImageData
            for i = 1:n
                % get next component
                comp = obj.ImageData_.Components(i);

                % flag indicating whether there is a previous display state entry for this component idx
                hasOldEntry = i <= numel(old);

                % CLim
                displayState(i).CLim = comp.DataRange;

                % Color/ColorName
                if ~isempty(comp.Color)
                    displayState(i).Color = comp.Color;
                    displayState(i).ColorName = matlabx.ui.axes.ImageAxes.canonicalComponentColorName( ...
                        matlabx.colors.names.fromRGB(comp.Color,"Palette","MATLAB"));
                elseif hasOldEntry && ~isempty(old(i).Color)
                    displayState(i).Color = old(i).Color;
                    displayState(i).ColorName = matlabx.ui.axes.ImageAxes.canonicalComponentColorName( ...
                        matlabx.colors.names.fromRGB(old(i).Color,"Palette","MATLAB"));
                else
                    displayState(i).ColorName = string(defaultColors{1 + mod(i-1, numel(defaultColors))});
                    displayState(i).Color = matlabx.colors.names.toRGB(displayState(i).ColorName,"Palette","MATLAB");
                end

                % LUT/Colormap
                if ~isempty(comp.LUT)
                    % use Component LUT if it exists
                    displayState(i).Colormap = comp.LUT;
                elseif hasOldEntry && ~isempty(old(i).Colormap)
                    % if not, use prior display state, if valid
                    displayState(i).Colormap = old(i).Colormap;
                else
                    % default fallback
                    displayState(i).Colormap = gray(256);
                end

                displayState(i).DisplayMap = obj.getDisplayMap(displayState(i), obj.ViewState_.ComponentColorMode);
            end
        end

        function validateFullComponentCell(obj, val, propertyName)
        %VALIDATEFULLCOMPONENTCELL Validate bulk per-component property input.
            if ~iscell(val) || numel(val) ~= obj.NumComponents
                error('ImageAxes:InvalidComponentPropertySize', ...
                    '%s must be a cell array with one entry per component (%d entries).', ...
                    propertyName, obj.NumComponents);
            end
        end

        function idx = validateComponentIndices(obj, idx)
        %VALIDATECOMPONENTINDICES Validate and row-vectorize component indices.
            idx = idx(:).';

            if isempty(idx)
                return
            end

            if any(idx < 1) || any(idx > obj.NumComponents) || any(mod(idx,1) ~= 0)
                error('ImageAxes:InvalidComponentIndex', ...
                    'Component indices must be positive integers between 1 and NumComponents (%d).', ...
                    obj.NumComponents);
            end
        end

        function changed = setComponentCLims_(obj, clims, idx)
        %SETCOMPONENTCLIMS_ Set CLim entries without refreshing.
            changed = false;

            for k = 1:numel(idx)
                ii = idx(k);
                comp = obj.ImageData_.Components(ii);

                % CLim is meaningless for RGB/logical components.
                if strcmp(comp.Kind, 'rgb') || strcmp(comp.Class, 'logical')
                    continue
                end

                newVal = double(clims{k});

                if ~isequal(size(newVal), [1 2])
                    error('ImageAxes:InvalidCLim', ...
                        'ComponentCLims{%d} must be a 1x2 numeric vector.', ii);
                end

                if isequaln(obj.ComponentDisplay_(ii).CLim, newVal)
                    continue
                end

                obj.ComponentDisplay_(ii).CLim = newVal;
                changed = true;
            end
        end

        function changed = setComponentColors_(obj, colors, idx)
        %SETCOMPONENTCOLORS_ Set component color names without refreshing.
            changed = false;

            for k = 1:numel(idx)
                ii = idx(k);
                newName = matlabx.ui.axes.ImageAxes.canonicalComponentColorName(colors{k});

                if strcmp(obj.ComponentDisplay_(ii).ColorName, newName)
                    continue
                end

                obj.ComponentDisplay_(ii).ColorName = newName;
                obj.ComponentDisplay_(ii).Color = ...
                    matlabx.colors.names.toRGB(char(newName), "Palette", "MATLAB");
                changed = true;
            end
        end

        function changed = setComponentColormaps_(obj, cmaps, idx)
        %SETCOMPONENTCOLORMAPS_ Set component colormaps without refreshing.
            changed = false;

            for k = 1:numel(idx)
                ii = idx(k);
                newMap = double(cmaps{k});

                if size(newMap, 2) ~= 3
                    error('ImageAxes:InvalidComponentColormap', ...
                        'ComponentColormaps{%d} must be an N-by-3 numeric colormap.', ii);
                end

                if isequaln(obj.ComponentDisplay_(ii).Colormap, newMap)
                    continue
                end

                obj.ComponentDisplay_(ii).Colormap = newMap;
                changed = true;
            end
        end
    
        function syncRenderSourceToView(obj, opts)
        %SYNCRENDERSOURCETOVIEW  Synchronize RenderSource_ with current view.
            arguments
                obj
                opts.ResetView (1,1) logical = false
            end
        
            oldData = obj.RenderSource_;
        
            if obj.ViewState_.ShowComposite
                newData = obj.getCompositeImage();
            else
                newData = obj.ImageData_.getPlane(...
                    obj.ViewState_.C,...
                    obj.ViewState_.Z,...
                    obj.ViewState_.T);
            end
        
            oldSz = size(oldData,[1,2]);
            newSz = size(newData,[1,2]);
        
            sizeChanged = ~isequal(oldSz,newSz);
        
            % Preserve the current view in normalized image coordinates before
            % changing the render source. Pixel-centered image limits are assumed:
            %
            %   XLim = [0.5, W + 0.5]
            %   YLim = [0.5, H + 0.5]
            preserveView = sizeChanged && ...
                           all(oldSz > 0) && ...
                           obj.ZoomEnabled && ...
                           ~opts.ResetView;
        
            if preserveView
                oldXLim = obj.mainAxes.XLim;
                oldYLim = obj.mainAxes.YLim;
        
                normalizedXLim = (oldXLim - 0.5) ./ oldSz(2);
                normalizedYLim = (oldYLim - 0.5) ./ oldSz(1);
            end
        
            % Scale the stored image-space zoom anchor independently of the view
            % limits. Zoom_.LastCursorXY must always remain in image coordinates.
            lastZoomAnchor = obj.Zoom_.LastCursorXY;
        
            if sizeChanged && ~isempty(lastZoomAnchor) && all(oldSz > 0)
                anchorNorm = (lastZoomAnchor - 0.5) ./ [oldSz(2),oldSz(1)];
        
                obj.Zoom_.LastCursorXY = ...
                    0.5 + anchorNorm .* [newSz(2),newSz(1)];
            end
        
            % Update rendered data and perform the normal display refresh.
            obj.RenderSource_ = newData;
            obj.refreshDisplay(ResetView=opts.ResetView || (sizeChanged && ~preserveView));
        
            if preserveView
                % Reconstruct the same relative view for the new image dimensions
                newXLim = 0.5 + normalizedXLim .* newSz(2);
                newYLim = 0.5 + normalizedYLim .* newSz(1);
        
                % Guard against small floating-point excursions
                defXLim = [0.5, newSz(2) + 0.5];
                defYLim = [0.5, newSz(1) + 0.5];
        
                viewWidth  = min(diff(newXLim),diff(defXLim));
                viewHeight = min(diff(newYLim),diff(defYLim));
        
                xLower = min(max(newXLim(1),defXLim(1)), ...
                             defXLim(2) - viewWidth);
        
                yLower = min(max(newYLim(1),defYLim(1)), ...
                             defYLim(2) - viewHeight);
        
                newXLim = xLower + [0,viewWidth];
                newYLim = yLower + [0,viewHeight];
        
                % refreshDisplay may have updated image-dependent geometry, so
                % restore the view afterward. Use the public viewport path so the
                % preserved region is normalized to the new image aspect ratio.
                obj.setViewportLimits(newXLim,newYLim);
        
            elseif sizeChanged
                % No active zoomed view to preserve. Keep the stored anchor valid,
                % defaulting to the center when no previous anchor exists.
                if isempty(obj.Zoom_.LastCursorXY)
                    obj.Zoom_.LastCursorXY = ...
                        [(newSz(2) + 1)/2, (newSz(1) + 1)/2];
                end
            end
        
            evtData = matlabx.ui.axes.events.RenderSourceChangedEventData(...
                oldData,newData);
        
            notify(obj,'RenderSourceChanged',evtData);

            if ~isempty(obj.OverlayManager)
                obj.OverlayManager.refreshVisibility();
            end
        end

        function updateDisplayMapping(obj)
        %UPDATEDISPLAYMAPPING Refresh display after CLim/color/LUT changes.
            if obj.ViewState_.ShowComposite
                obj.syncRenderSourceToView();
                return
            end

            obj.refreshDisplay( ...
                ResetView=false, ...
                UpdateImage=true, ...
                UpdateColormap=true, ...
                UpdateColorbar=true, ...
                UpdateTopLabel=false, ...
                UpdateContextMenu=true);
        end

        function updateAllDisplayMaps(obj)
        %UPDATEALLDISPLAYMAPS Rebuild every component display map for the active color mode.
            obj.ComponentDisplay_ = matlabx.ui.axes.ImageAxesDisplayRenderer.updateAllDisplayMaps( ...
                obj.ComponentDisplay_, obj.ViewState_.ComponentColorMode);
        end
    
        function map = getDisplayMap(~, displayState, mode)
        %GETDISPLAYMAP Return the effective display map for one component state.
            map = matlabx.ui.axes.ImageAxesDisplayRenderer.getDisplayMap(displayState, mode);
        end
    
        function I = getCompositeImage(obj)
        %GETCOMPOSITEIMAGE Render the current multicomponent view as an RGB composite.
            I = matlabx.ui.axes.ImageAxesDisplayRenderer.getCompositeImage( ...
                obj.ImageData_, obj.ComponentDisplay_, obj.ViewState_);
        end

        function notifyDisplayStateChanged_(obj, propertyName, componentIdx, previousValue, currentValue)
        %NOTIFYDISPLAYSTATECHANGED_ Emit a semantic display-state event.
            evtData = matlabx.ui.axes.events.DisplayStateChangedEventData( ...
                Property=string(propertyName), ...
                ComponentIdx=componentIdx, ...
                PreviousValue=previousValue, ...
                CurrentValue=currentValue);

            notify(obj, 'DisplayStateChanged', evtData);
        end

        function notifyImageDataChanged_(obj, oldSummary, newSummary)
        %NOTIFYIMAGEDATACHANGED_ Emit a semantic image-data event.
            evtData = matlabx.ui.axes.events.ImageDataChangedEventData( ...
                PreviousNumComponents=oldSummary.NumComponents, ...
                CurrentNumComponents=newSummary.NumComponents, ...
                PreviousSize=oldSummary.Size, ...
                CurrentSize=newSummary.Size);

            notify(obj, 'ImageDataChanged', evtData);
        end

        function summary = getImageDataEventSummary_(obj)
        %GETIMAGEDATAEVENTSUMMARY_ Return compact ImageData event metadata.
            summary = struct( ...
                "NumComponents", obj.ImageData_.NumComponents, ...
                "Size", [obj.ImageData_.SizeY, obj.ImageData_.SizeX, ...
                         obj.ImageData_.SizeZ, obj.ImageData_.SizeT]);
        end

        function limits = getDisplayLimitsSliderLimits_(~, comp)
        %GETDISPLAYLIMITSSLIDERLIMITS_ Return nondegenerate slider limits.
            limits = double(comp.DataRange);

            if limits(2) > limits(1)
                return
            end

            nativeLimits = double(comp.NativeDisplayRange);
            if nativeLimits(2) > nativeLimits(1)
                limits = nativeLimits;
                return
            end

            center = limits(1);
            delta = max(abs(center) * 0.01, 1);
            limits = center + [-delta, delta];
        end
    
    end

    %% Tool-accessible helpers
    methods (Access=?matlabx.ui.axes.AxesTool, Hidden=true)
        
        function updateFromTool(obj)
        %UPDATEFROMTOOL Refresh cursor-dependent host UI after tool interaction.
            obj.updateBottomLabelText();
            obj.updatePointer();
        end

        function restoreDefaultLimits(obj)
        %RESTOREDEFAULTLIMITS Restore full-image limits on both hosted axes.
            obj.resetViewport();
        end

    end

    %% Derived getters and setters
    methods

        function S = getStatusSummary(obj)
        %GETSTATUSSUMMARY Return compact ImageAxes operational status.
        %
        %   S = ax.getStatusSummary() returns a user-facing/debug-friendly struct
        %   describing the axes identity, current image/view state, installed
        %   tools, link status, and visible display aids.

            viewport = obj.getViewport();

            S = struct();
            S.Name = obj.Name;
            S.Class = string(class(obj));
            S.Image = struct( ...
                "ImageDataClass", string(class(obj.ImageData_)), ...
                "Size", struct( ...
                    "Y", obj.ImageData_.SizeY, ...
                    "X", obj.ImageData_.SizeX, ...
                    "C", obj.ImageData_.NumComponents, ...
                    "Z", obj.ImageData_.SizeZ, ...
                    "T", obj.ImageData_.SizeT), ...
                "RenderSourceKind", string(obj.RenderSourceKind), ...
                "RenderSourceClass", string(obj.RenderSourceClass), ...
                "RenderSourceSize", obj.RenderSourceSize);
            S.View = struct( ...
                "C", obj.C, ...
                "Z", obj.Z, ...
                "T", obj.T, ...
                "ShowComposite", string(obj.ShowComposite), ...
                "CLimMode", string(obj.CLimMode), ...
                "ComponentColorMode", string(obj.ComponentColorMode));
            S.Viewport = struct( ...
                "Center", viewport.Center, ...
                "Size", viewport.Size, ...
                "XLim", viewport.XLim, ...
                "YLim", viewport.YLim, ...
                "ZoomFactor", viewport.ZoomFactor, ...
                "ZoomLevel", viewport.ZoomLevel);
            S.Display = struct( ...
                "MaskEnabled", string(obj.MaskEnabled), ...
                "HasMask", ~isempty(obj.Mask), ...
                "OverlaysVisible", string(obj.OverlaysVisible), ...
                "ColorbarVisible", string(obj.ColorbarVisible), ...
                "ViewportBoxVisible", string(obj.ViewportBoxVisible), ...
                "MaxRenderedResolution", obj.MaxRenderedResolution, ...
                "FontSize", obj.FontSize);
            S.Tools = obj.getToolStatusSummary();
            S.Links = obj.getLinkStatusSummary();
        end

        function S = printSizeDiagnostics(obj)
        %PRINTSIZEDIAGNOSTICS Print temporary ImageAxes layout diagnostics.
        %
        %   ax.printSizeDiagnostics() prints component, grid, panel, axes, and
        %   image aspect-fit sizing values. S = ax.printSizeDiagnostics() returns
        %   the diagnostic struct as well.

            S = obj.getSizeDiagnostics();

            if nargout == 0
                matlabx.struct.prettyPrint(S, StringArrayStyle="lines");
            end
        end

        % cursor position in axes/image
        function cursorPosition = get.cursorPosition(obj)
        %GET.CURSORPOSITION Return the current cursor position value.
            cursorPosition = obj.mainAxes.CurrentPoint(1,[1,2]);
            % return empty if outside limits
            if ~obj.isInLimits(cursorPosition,obj.mainAxes.XLim,obj.mainAxes.YLim)
                cursorPosition = [];
            end
        end

        function cursorPositionStatic = get.cursorPositionStatic(obj)
        %GET.CURSORPOSITIONSTATIC Return the current cursor position static value.
            cursorPositionStatic = obj.staticAxes.CurrentPoint(1,[1,2]);
            % return empty if outside limits
            if ~obj.isInLimits(cursorPositionStatic,obj.staticAxes.XLim,obj.staticAxes.YLim)
                cursorPositionStatic = [];
            end
        end

        function px = get.activePixel(obj)
        %GET.ACTIVEPIXEL Return the integer image pixel currently under the pointer.
            % cursor position in axes
            XY = obj.cursorPosition;
            % empty -> return
            if isempty(XY), px = []; return, end
            % round to integer px indices, clip to image dimensions
            px = [clip(round(XY(1)),1,obj.ImageWidth), clip(round(XY(2)),1,obj.ImageHeight)];
        end

        % image dimensions
        function s = get.ImageSize(obj)
        %GET.IMAGESIZE Return the current image size value.
            s = obj.RenderSourceSize;
        end
        function h = get.ImageHeight(obj)
        %GET.IMAGEHEIGHT Return the current image height value.
            h = obj.ImageSize(1);
        end
        function w = get.ImageWidth(obj)
        %GET.IMAGEWIDTH Return the current image width value.
            w = obj.ImageSize(2);
        end

        % default axes limits (set to prefectly enclose image)
        function x = get.defaultXLim(obj)
        %GET.DEFAULTXLIM Return the current default xlim value.
            x = [0 obj.ImageWidth] + 0.5;
        end
        function y = get.defaultYLim(obj)
        %GET.DEFAULTYLIM Return the current default ylim value.
            y = [0 obj.ImageHeight] + 0.5;
        end

        % retrieve fig/axes handles
        function f = get.ParentFig(obj)
        %GET.PARENTFIG Return the current parent fig value.
            f = ancestor(obj,'Figure');
        end
        function ax = getAxes(obj)
        %GETAXES Return the primary image UIAxes.
            ax = obj.mainAxes;
        end
        function ax = getOverlayAxes(obj)
        %GETOVERLAYAXES Return the static full-image UIAxes.
            ax = obj.staticAxes;
        end

        % axes/image passthroughs (Set/Get)

        % ImageVisible
        function v = get.ImageVisible(obj)
        %GET.IMAGEVISIBLE Return the current image visible value.
            v = obj.hImage.Visible;
        end
        function set.ImageVisible(obj,val)
        %SET.IMAGEVISIBLE Set image visible and update dependent state.
            obj.hImage.Visible = val;
        end
        % AxesVisible
        function v = get.AxesVisible(obj)
        %GET.AXESVISIBLE Return the current axes visible value.
            v = obj.mainAxes.Visible;
        end
        function set.AxesVisible(obj,val)
        %SET.AXESVISIBLE Set axes visible and update dependent state.
            obj.mainAxes.Visible = val;
        end
        % ColorbarVisible
        function v = get.ColorbarVisible(obj)
        %GET.COLORBARVISIBLE Return the current colorbar visible value.
            v = obj.Colorbar.Visible;
        end
        function set.ColorbarVisible(obj,val)
        %SET.COLORBARVISIBLE Set colorbar visible and update dependent state.
            obj.Colorbar.Visible = val;
        end
        % MaxRenderedResolution
        function v = get.MaxRenderedResolution(obj)
        %GET.MAXRENDEREDRESOLUTION Return the current max rendered resolution value.
            v = obj.hImage.MaxRenderedResolution;
        end
        function set.MaxRenderedResolution(obj,val)
        %SET.MAXRENDEREDRESOLUTION Set max rendered resolution and update dependent state.
            obj.hImage.MaxRenderedResolution = val;
        end
        % ContextMenuItems
        function items = get.ContextMenuItems(obj)
        %GET.CONTEXTMENUITEMS Return the current context menu items value.
            items = obj.ContextMenuItems_;
        end
        function set.ContextMenuItems(obj, items)
        %SET.CONTEXTMENUITEMS Set context menu items and update dependent state.
            items = matlabx.ui.axes.ImageAxesContextMenuManager.validateBuiltinItems(items);
            obj.ContextMenuItems_ = items;
            if ~isempty(obj.ContextMenuManager)
                obj.ContextMenuManager.setBuiltinItems(items);
            end
        end
        % ViewportBoxVisible
        function val = get.ViewportBoxVisible(obj)
        %GET.VIEWPORTBOXVISIBLE Return the current viewport box visible value.
            val = obj.ViewportBoxVisible_;
        end
        function set.ViewportBoxVisible(obj,val)
        %SET.VIEWPORTBOXVISIBLE Set viewport box visible and update dependent state.
            obj.ViewportBoxVisible_ = val;
            obj.updateViewportBoxVisibility();
            obj.refreshContextMenu();
        end
        % ToolbarVisible
        function val = get.ToolbarVisible(obj)
        %GET.TOOLBARVISIBLE Return the requested toolbar visibility.
            val = obj.ToolbarVisible_;
        end
        function set.ToolbarVisible(obj,val)
        %SET.TOOLBARVISIBLE Show or hide the toolbar without changing its tools.
            obj.ToolbarVisible_ = val;
            if ~isempty(obj.mainAxes) && isvalid(obj.mainAxes) && ...
                    ~obj.FirstUpdatePending
                obj.mainAxes.Toolbar.Visible = val;
            end
            obj.refreshContextMenu();
        end

        % FontSize
        function set.FontSize(obj,val)
        %SET.FONTSIZE Set font size and update dependent state.
            obj.FontSize_ = val;
            obj.updateFontSizes();
            obj.updateOnResize();
        end

        function v = get.FontSize(obj)
        %GET.FONTSIZE Return the current font size value.
            v = obj.FontSize_;
        end

    end

    %% Hub-facing event handlers (matches | onDown | onMove | onUp | onScroll | onKeyPress | onKeyRelease | onEnter | onLeave)
    methods

        % determine whether this instance should claim event from FigureEventHub
        function tf = matches(obj, E)
        %MATCHES Return whether a routed event belongs to this ImageAxes.
            % E.Target: hittest result from FigureEventHub that we are checking for a match to this component
            % E.Kind: the specific event kind (i.e. 'Move', 'Down', 'Up', 'Scroll', 'KeyPress', or 'KeyRelease')
            % E.RawEvent: event data associated with the event

            % true if child of UIAxes in this ImageAxes
            tf = obj.isChild(E.Target) && obj.isAxesChild(E.Target);

            if tf && obj.isToolbarButtonChild(E.Target)
                tf = strcmp(E.Kind,'Move');
            end
        end

        function onDown(obj, E)
        %ONDOWN Route a pointer-down event to tools and host defaults.
            obj.routeEventToTools(E);

            if E.StopPropagation, return; end

            obj.onDown_(E);
        end

        function onMove(obj, E)
        %ONMOVE Handle routed pointer movement over the component.
            % get the ancestor toolbar button from event target, if it exists
            btn = obj.getToolbarButtonFromTarget(E.Target);

            % button exists
            if ~isempty(btn)
                % set image info label to display button tooltip, return
                obj.BottomLabel.String = sprintf(' %s',btn.Tooltip); return
            end


            % set axes limits and viewport box before routing to tools
            if obj.ZoomEnabled && obj.FollowCursorEnabled
                obj.followCursor();
            end

            obj.routeEventToTools(E);

            % Host maintenance (update label/pointer/etc. on move if desired)
            obj.onMove_();
        end

        function onUp(obj, E)
        %ONUP Route a pointer-up event to installed tools.
            obj.routeEventToTools(E);
        end

        function onScroll(obj, E)
        %ONSCROLL Route a scroll event to installed tools.
            obj.routeEventToTools(E);
        end

        function onKeyPress(obj, E)
        %ONKEYPRESS Dispatch hotkeys, tools, and built-in keyboard commands.
            obj.routeHotkey(E);
            if E.StopPropagation, return; end

            obj.routeEventToTools(E);

            switch E.Hotkey
                case 'shift+meta+m'
                    obj.toggleComposite();
                case 'shift+meta+c'
                    obj.openDisplayLimitsWindow();
                case 'rightarrow'
                    obj.nextComponent();
                case 'leftarrow'
                    obj.previousComponent();
                case 'uparrow'
                    obj.nextZ();
                case 'downarrow'
                    obj.previousZ();
                case 'shift+rightarrow'
                    obj.nextT();
                case 'shift+leftarrow'
                    obj.previousT();
            end
        end

        function onKeyRelease(obj, E)
        %ONKEYRELEASE Route a key-release event to installed tools.
            obj.routeEventToTools(E);
        end

        function onEnter(obj,E)
        %ONENTER Activate hover UI and notify tools when the pointer enters.
            obj.BottomLabel.Visible = "on";

            if obj.ZoomEnabled && obj.FollowCursorEnabled
                % Crossing between viewers starts a new follow interaction. Drop
                % any anchor retained from this axes' previous active period, then
                % map the newly entered cursor position directly. This lets entry
                % from the left move a viewport that was linked at the right edge
                % back toward the left immediately.
                obj.clearFollowCursorAnchor();
                obj.followCursor();
            end

            obj.ToolManager.notifyHostEnter(E);
        end

        function onLeave(obj,E)
        %ONLEAVE Handle the pointer leaving the component.
            % hide label
            obj.BottomLabel.Visible = "off";
            % reset pointer to arrow
            if isvalid(obj.ParentFig)
                obj.ParentFig.Pointer = 'arrow';
            end
            obj.ToolManager.notifyHostLeave(E);
        end

    end

    %% Internal behaviors
    methods (Access=private)

        % executes on mouse move after PassiveInterceptors/Interceptors
        function onMove_(obj)
        %ONMOVE_ Refresh the cursor label and pointer after movement.
            obj.updateBottomLabelText();
            obj.updatePointer();
        end

        function onDown_(obj,E)
        %ONDOWN_ Open the host menu for an unclaimed context click.

            if E.StopPropagation
                return
            end

            if E.MouseChord == "contextclick"
                XY = E.CurrentPointFigure;
                obj.ContextMenuManager.openAt(XY);
            end
        end

    end

    %% Private Hub helpers
    methods (Access=private)

        function tf = isChild(obj,h)
        %ISCHILD Return whether a graphics object belongs to this component.
            % true if h is child of this ImageAxes
            ia = ancestor(h,'matlabx.ui.axes.ImageAxes');

            if isempty(ia)
                tf = false;
            else
                tf = ia == obj;
            end
        end

        function tf = isAxesChild(obj,h)
        %ISAXESCHILD Return whether a graphics object belongs to a hosted UIAxes.
            % true if h is child of UIAxes belonging to this ImageAxes
            ax = ancestor(h,'matlab.ui.control.UIAxes');
            tf = ~isempty(ax) && strcmp(ax.Tag,obj.Name);
        end

        function tf = isToolbarButtonChild(~,h)
        %ISTOOLBARBUTTONCHILD Return whether a graphics object belongs to an axes toolbar button.
            % true if h is child of ToolbarStateButton or ToolbarPushButton (in any axes)
            % btn = ancestor(h,'matlab.ui.controls.ToolbarStateButton');
            % if isempty(btn)
            %     btn = ancestor(h,'matlab.ui.controls.ToolbarPushButton');
            % end

            tf = ~isempty(ancestor(h,'matlab.ui.controls.ToolbarStateButton')) || ...
                ~isempty(ancestor(h,'matlab.ui.controls.ToolbarPushButton'));
        end

        function btn = getToolbarButtonFromTarget(~,target)
        %GETTOOLBARBUTTONFROMTARGET Return the toolbar button containing an event target.
            % get the ancestor toolbar button from event target, if it exists
            % look for "state" buttons first
            btn = ancestor(target,'matlab.ui.controls.ToolbarStateButton');
            % none found -> look for "push" buttons
            if isempty(btn)
                btn = ancestor(target,'matlab.ui.controls.ToolbarPushButton');
            end
        end

    end

    %% Tool event routing
    methods

        function routeEventToTools(obj,E)
        %ROUTEEVENTTOTOOLS Route event to tools.

            obj.routeToPassiveInterceptors(E);
            if E.StopPropagation, return; end

            % get highest priority Interceptor for event kind
            t = obj.getPriorityInterceptor(E.Kind);

            % Forward the event to the active interceptor, but do not mark it
            % consumed merely because a tool saw it. Tools should call E.stop()
            % only when they actually claim the event; this lets host defaults
            % such as bare contextclick menus still run while non-exclusive tools
            % like Zoom are enabled.
            if ~isempty(t)
                t.("on"+E.Kind)(E);
            end
        end

        function routeHotkey(obj,E)
        %ROUTEHOTKEY Route hotkey.
            if isempty(obj.HotkeyRegistry)
                return
            end

            obj.HotkeyRegistry.dispatch(E);
        end

        function routeToPassiveInterceptors(obj,E)
        %ROUTETOPASSIVEINTERCEPTORS Route an event to every matching passive interceptor.
            % cell array of PassiveInterceptors for this eventType, sorted by Priority
            passiveInterceptors = obj.getPriorityPassiveInterceptors(E.Kind);

            % no PassiveInterceptors for this eventType, return early
            if isempty(passiveInterceptors), return; end

            % pass event to each PassiveInterceptor
            for i = 1:numel(passiveInterceptors)
                passiveInterceptors{i}.("onPassive"+E.Kind)(E);
            end

        end

    end

    %% Tool management (register/unregister, load/unload, install/uninstall)
    methods

        % register a tool (add it to the installed tool registry) - tools call this themselves
        function registerTool(obj, tool)
        %REGISTERTOOL Register an installed tool and construct its contributions.
            obj.ToolManager.register(tool);
        end

        % remove tool from installed tool registry - it remains loaded
        function unregisterTool(obj, tool)
        %UNREGISTERTOOL Remove a tool and all of its host-owned contributions.
            obj.ToolManager.unregister(tool);
        end

        % load all tools in matlabx.ui.axes.tools
        function loadAllTools(obj)
        %LOADALLTOOLS Load all tools.
            obj.ToolManager.loadAll();
        end

        % unload all currently loaded tools
        function unloadAllTools(obj)
        %UNLOADALLTOOLS Unload all tools.
            obj.ToolManager.unloadAll();
        end

        % load tools specified by toolNames (cell array of char vectors)
        function loadTools(obj,toolNames)
        %LOADTOOLS Construct one or more manager-owned built-in tools.
            obj.ToolManager.loadMany(toolNames);
        end

        % load tool specified by name
        function loadTool(obj, name)
        %LOADTOOL Load tool.
            obj.ToolManager.load(name);
        end

        % unload tool specified by name
        function unloadTool(obj, name)
        %UNLOADTOOL Unload tool.
            obj.ToolManager.unload(name);
        end

        % install tools specified by toolNames (cell array of char vectors)
        function installTools(obj,toolNames)
        %INSTALLTOOLS Install one or more loaded built-in tools by name.
            obj.ToolManager.installMany(toolNames);
        end

        % install tool specified by name
        function installTool(obj,name)
        %INSTALLTOOL Install a loaded built-in name or an application AxesTool.
        %   Object inputs must belong to this host and remain application-owned.
            obj.ToolManager.install(name);
        end

        % uninstall tool specified by name
        function uninstallTool(obj,name)
        %UNINSTALLTOOL Remove contributions by name or object without deletion.
            obj.ToolManager.uninstall(name);
        end

    end

    %% Hotkey management
    methods

        function registerToolHotkeys(obj, tool)
        %REGISTERTOOLHOTKEYS Register the hotkeys declared by an installed tool.
            if strlength(tool.ToggleHotkey) == 0
                return
            end

            obj.HotkeyRegistry.add( ...
                tool.ToggleHotkey, ...
                @(E) obj.onToolToggleHotkey(tool.Name, E), ...
                "Owner", tool, ...
                "Description", tool.Name + " toggle", ...
                "Priority", tool.Priority);
        end

        function onToolToggleHotkey(obj, name, E)
        %ONTOOLTOGGLEHOTKEY Toggle a state tool in response to its registered hotkey.
            t = obj.getInstalledTool(name);

            if isempty(t)
                return
            end

            E.stop();

            switch t.Style
                case 'push'
                    obj.runTool(name);
                case 'state'
                    if t.Enabled
                        obj.disableTool(name);
                    else
                        obj.enableTool(name);
                    end
            end
        end

    end

    %% Toolbar management (add, remove, reorder toolbar buttons)
    methods

        % add a toolbar button for the tool (tool calls this on install)
        function addToolbarButton(obj, tool)
        %ADDTOOLBARBUTTON Add toolbar button.
            obj.ToolManager.addToolbarButton(tool);
        end

        % add a toolbar button for the tool (tool calls this on uninstall)
        function removeToolbarButton(obj, tool)
        %REMOVETOOLBARBUTTON Remove toolbar button.
            obj.ToolManager.removeToolbarButton(tool);
        end

    end

    %% Toggle/query tool state
    methods

        % enable installed tool specified by name
        function enableTool(obj, name)
        %ENABLETOOL Enable an installed state tool by name.
            obj.ToolManager.enable(name);
        end

        % disable installed tool specified by name
        function disableTool(obj, name)
        %DISABLETOOL Disable an installed state tool by name.
            obj.ToolManager.disable(name);
        end

        % query Enabled state of tool specified by name
        function tf = toolEnabled(obj, name)
        %TOOLENABLED Return whether an installed tool is enabled.
            tf = obj.ToolManager.enabled(name);
        end

        % toggle Enabled state of "state" tool specified by name (toolbar button ValueChangedFcn)
        function onToolToggle(obj,toolState,name)
        %ONTOOLTOGGLE Apply a toolbar state-button change to its tool.
            obj.releaseToolbarFocus();
            obj.ToolManager.toggle(toolState, name);
        end

        % run "push" tool specified by name (toolbar button ButtonPushedFcn)
        function onToolPush(obj,name)
        %ONTOOLPUSH Run the tool associated with a toolbar push button.
            obj.ToolManager.push(name);
        end

        % run installed tool specified by name
        function runTool(obj, name)
        %RUNTOOL Run tool.
            obj.ToolManager.run(name);
        end

        % disable ActiveExclusiveTool if it exists
        function disableActiveExclusive(obj)
        %DISABLEACTIVEEXCLUSIVE Disable active exclusive.
            obj.ToolManager.disableActiveExclusive();
        end

    end

    %% Retrieve/sort tools
    methods

        % get installed tool specified by name
        function t = getInstalledTool(obj, name)
        %GETINSTALLEDTOOL Return installed tool.
            t = obj.ToolManager.getInstalled(name);
        end

        % get loaded tool specified by name
        function t = getLoadedTool(obj, name)
        %GETLOADEDTOOL Return loaded tool.
            t = obj.ToolManager.getLoaded(name);
        end

        % get the highest Priority Interceptor for the specified eventType
        function tool = getPriorityInterceptor(obj,eventType)
        %GETPRIORITYINTERCEPTOR Return the enabled interceptor that should receive an event.
            tool = obj.ToolManager.getPriorityInterceptor(eventType);
        end

        % get cell array of PassiveInterceptors for the specified eventType, sorted by descending Priority
        function toolsCell = getPriorityPassiveInterceptors(obj,eventType)
        %GETPRIORITYPASSIVEINTERCEPTORS Return passive interceptors for an event in priority order.
            toolsCell = obj.ToolManager.getPriorityPassiveInterceptors(eventType);
        end

        % given a cell array of tools, return the same cell array sorted by descending Priority
        function toolsCell = prioritySortToolsCell(obj,toolsCell)
        %PRIORITYSORTTOOLSCELL Sort tool objects by descending routing priority.
            toolsCell = obj.ToolManager.prioritySortCell(toolsCell);
        end

    end

    %% User-facing tool management
    methods

        function tools = get.Tools(obj)
        %GET.TOOLS Return installed tool objects as a struct.
            tools = obj.ToolManager.Tools;
        end

        function set.Tools(obj, toolNames)
        %SET.TOOLS Install the named tools and remove tools not listed.
        %
        %   Assignment configures which tools are installed:
        %
        %       ax.Tools = ["Zoom","Box"]
        %
        %   Reading the property returns the installed tool handles:
        %
        %       ax.Tools.Box.BoxSize = 25
            obj.ToolManager.setInstalledNames(toolNames);
        end

        function manager = get.Overlays(obj)
        %GET.OVERLAYS Return the ImageAxes overlay manager.
            manager = obj.OverlayManager;
        end

    end

    %% Popup window management
    methods (Access=?matlabx.ui.axes.ImageAxesDisplayLimitsWindow)

        function state = getDisplayLimitsWindowState(obj)
        %GETDISPLAYLIMITSWINDOWSTATE Return slider-ready display-limit state.
            N = obj.NumComponents;

            state = struct( ...
                "CanOpen", true, ...
                "NumComponents", N, ...
                "Name", {cell(1, N)}, ...
                "Limits", {cell(1, N)}, ...
                "Value", {cell(1, N)}, ...
                "RoundDigits", {cell(1, N)}, ...
                "RoundValues", {cell(1, N)}, ...
                "ValueDisplayFormat", {cell(1, N)}, ...
                "Colormap", {cell(1, N)});

            for i = 1:N
                comp = obj.ImageData_.Components(i);
                compDisplay = obj.ComponentDisplay_(i);

                switch comp.Kind
                    case 'scalar'
                        switch comp.Class
                            case {'double','single'}
                                displayFormat = '%0.2f';
                                roundValues = "off";
                            case {'uint8','uint16'}
                                displayFormat = '%i';
                                roundValues = "on";
                            otherwise
                                state.CanOpen = false;
                                return
                        end
                    otherwise
                        state.CanOpen = false;
                        return
                end

                clim = compDisplay.CLim;
                if isempty(clim)
                    clim = comp.DataRange;
                end

                state.Name{i} = char(comp.Name);
                state.Limits{i} = obj.getDisplayLimitsSliderLimits_(comp);
                state.Value{i} = clim;
                state.RoundDigits{i} = 0;
                state.RoundValues{i} = roundValues;
                state.ValueDisplayFormat{i} = displayFormat;
                state.Colormap{i} = compDisplay.DisplayMap;
            end
        end

    end

    methods

        % --- DisplayLimitsWindow ---

        function openDisplayLimitsWindow(obj)
        %OPENDISPLAYLIMITSWINDOW Open the host-owned CLim slider dialog.
            if isempty(obj.displayLimitsWindow) || ~isvalid(obj.displayLimitsWindow)
                obj.displayLimitsWindow = matlabx.ui.axes.ImageAxesDisplayLimitsWindow(obj);
            end

            obj.displayLimitsWindow.open();
        end

        % --- MetadataWindow ---
        function openMetadataWindow(obj)
        %OPENMETADATAWINDOW Open a text report of ImageData source metadata.
            if obj.metadataWindowOpen
                return
            end

            metadata = obj.ImageData_.AllMetadata;
            metadataLines = cellstr(matlabx.struct.prettyPrint(metadata));

            obj.metadataWindow = matlabx.app.TextWindow( ...
                "Title","Metadata", ...
                "Text",metadataLines, ...
                "ClosedFcn",@(~,~) obj.onMetadataWindowClosed());

            obj.metadataWindowOpen = true;
        end

        function onMetadataWindowClosed(obj)
        %ONMETADATAWINDOWCLOSED Clear metadata-window ownership state.
            obj.metadataWindowOpen = false;
        end

        % --- ImagePropertiesWindow ---
        function openImagePropertiesWindow(obj)
        %OPENIMAGEPROPERTIESWINDOW Open a generated ImageData and view summary.
            if obj.imagePropertiesWindowOpen
                return
            end

            properties = obj.getImagePropertiesSummary();
            propertyLines = cellstr(matlabx.struct.prettyPrint( ...
                properties, StringArrayStyle="lines"));

            obj.imagePropertiesWindow = matlabx.app.TextWindow( ...
                "Title","Image Properties", ...
                "Text",propertyLines, ...
                "ClosedFcn",@(~,~) obj.onImagePropertiesWindowClosed());

            obj.imagePropertiesWindowOpen = true;
        end

        function onImagePropertiesWindowClosed(obj)
        %ONIMAGEPROPERTIESWINDOWCLOSED Clear image-properties window ownership state.
            obj.imagePropertiesWindowOpen = false;
        end

        % --- StatusWindow ---
        function openStatusWindow(obj)
        %OPENSTATUSWINDOW Open the ImageAxes operational status report.
            if obj.statusWindowOpen
                return
            end

            status = obj.getStatusSummary();
            statusLines = cellstr(matlabx.struct.prettyPrint( ...
                status, StringArrayStyle="lines"));

            obj.statusWindow = matlabx.app.TextWindow( ...
                "Title","ImageAxes Status", ...
                "Text",statusLines, ...
                "ClosedFcn",@(~,~) obj.onStatusWindowClosed());

            obj.statusWindowOpen = true;
        end

        function onStatusWindowClosed(obj)
        %ONSTATUSWINDOWCLOSED Clear status-window ownership state.
            obj.statusWindowOpen = false;
        end

        % --- ToolHelpWindow ---
        function openToolHelpWindow(obj, tool)
            %OPENTOOLHELPWINDOW Open a help report for an installed tool.
            if obj.toolHelpWindowOpen
                return
            end

            if ischar(tool) || (isstring(tool) && isscalar(tool))
                tool = obj.getInstalledTool(tool);
            end

            if isempty(tool) || ~isvalid(tool)
                warning("ImageAxes:InvalidToolHelp", ...
                    "Cannot open tool help because the requested tool is not installed.")
                return
            end

            helpInfo = tool.getHelpInfo();
            helpLines = cellstr(matlabx.struct.prettyPrint( ...
                helpInfo, StringArrayStyle="lines"));

            obj.toolHelpWindow = matlabx.app.TextWindow( ...
                "Title",char(tool.Name + " Help"), ...
                "Text",helpLines, ...
                "WordWrap","on", ...
                "Position",[0 0 600 600], ...
                "ClosedFcn",@(~,~) obj.onToolHelpWindowClosed());

            obj.toolHelpWindowOpen = true;
        end

        function onToolHelpWindowClosed(obj)
        %ONTOOLHELPWINDOWCLOSED Clear tool-help window ownership state.
            obj.toolHelpWindowOpen = false;
        end

    end

    %% Context menu callbacks
    methods

        function setComponentColorMode(obj,mode)
        %SETCOMPONENTCOLORMODE Select solid-color or LUT component rendering.
            obj.ComponentColorMode = mode;
        end

        function resetView(obj)
        %RESETVIEW Restore default image-space limits and zoom view state.
            obj.resetZoomViewState();
        end

        function toggleViewportBoxVisible(obj)
        %TOGGLEVIEWPORTBOXVISIBLE Toggle persistent viewport-box overlay visibility.
            obj.ViewportBoxVisible = matlab.lang.OnOffSwitchState(obj.ViewportBoxVisible == "off");
        end

    end

    %% Context menu support
    methods (Access=?matlabx.ui.axes.ImageAxesContextMenuManager)
        function tf = currentComponentCanHaveColor(obj)
        %CURRENTCOMPONENTCANHAVECOLOR True for scalar, non-logical components.
            if isempty(obj.ComponentDisplay_) || obj.C < 1 || obj.C > obj.NumComponents
                tf = false;
                return
            end

            comp = obj.ImageData_.Components(obj.C);
            tf = strcmp(comp.Kind, 'scalar') && ~strcmp(comp.Class, 'logical');
        end

        function name = currentComponentColorName(obj)
        %CURRENTCOMPONENTCOLORNAME Return the current component's color name.
            if isempty(obj.ComponentDisplay_) || obj.C < 1 || obj.C > obj.NumComponents
                name = "";
                return
            end

            name = obj.ComponentDisplay_(obj.C).ColorName;
        end

        function S = getImagePropertiesSummary(obj)
        %GETIMAGEPROPERTIESSUMMARY Return a compact ImageData/view summary.
            imageData = obj.ImageData_;

            S = struct();
            S.ImageDataClass = string(class(imageData));
            S.SourceClass = string(class(imageData.Source));
            S.IsLoaded = imageData.IsLoaded;
            S.IsFileBacked = imageData.IsFileBacked;
            S.Size = struct( ...
                "Y", imageData.SizeY, ...
                "X", imageData.SizeX, ...
                "C", imageData.NumComponents, ...
                "Z", imageData.SizeZ, ...
                "T", imageData.SizeT);
            S.ComponentsAreChannels = imageData.ComponentsAreChannels;
            S.MultiComponentKind = string(imageData.MultiComponentKind);
            S.CanMergeComponents = imageData.CanMergeComponents;
            S.View = struct( ...
                "C", obj.C, ...
                "Z", obj.Z, ...
                "T", obj.T, ...
                "ShowComposite", string(obj.ShowComposite), ...
                "ComponentColorMode", string(obj.ComponentColorMode), ...
                "CLimMode", string(obj.CLimMode));
            S.RenderSource = struct( ...
                "Kind", string(obj.RenderSourceKind), ...
                "Class", string(obj.RenderSourceClass), ...
                "Size", obj.RenderSourceSize);

            components = repmat(struct( ...
                "Index", [], ...
                "Name", "", ...
                "Kind", "", ...
                "Class", "", ...
                "Size", [], ...
                "DataRange", [], ...
                "CLim", [], ...
                "ColorName", "", ...
                "HasLUT", false), 1, imageData.NumComponents);

            for i = 1:imageData.NumComponents
                comp = imageData.Components(i);
                displayState = obj.ComponentDisplay_(i);
                components(i).Index = i;
                components(i).Name = comp.Name;
                components(i).Kind = comp.Kind;
                components(i).Class = comp.Class;
                components(i).Size = comp.Size;
                components(i).DataRange = comp.DataRange;
                components(i).CLim = displayState.CLim;
                components(i).ColorName = displayState.ColorName;
                components(i).HasLUT = ~isempty(displayState.Colormap);
            end

            S.Components = components;
        end
    end

    %% Debugging helpers
    methods (Hidden)
        function S = debug(obj, opts)
        %DEBUG Print ImageAxes status and optionally enter keyboard debug mode.
        %
        %   ax.debug() prints a compact status report with view, image, tool, and
        %   layout diagnostic values.
        %
        %   S = ax.debug() returns the report struct without printing.
        %
        %   ax.debug("Stop",true) calls KEYBOARD before returning so private state
        %   such as obj.ViewState_, obj.ComponentDisplay_, and the local report S
        %   can be inspected interactively from the command window.

            arguments
                obj (1,1) matlabx.ui.axes.ImageAxes
                opts.Stop (1,1) logical = false
                opts.IncludeSizeDiagnostics (1,1) logical = true
            end

            S = obj.getDebugStatus(opts.IncludeSizeDiagnostics);

            if nargout == 0
                matlabx.struct.prettyPrint(S, StringArrayStyle="lines");
            end

            if opts.Stop
                keyboard %#ok<KEYBOARDFUN>
            end
        end
    end

    %% Private static helpers
    methods (Static, Access=private)

        function tf = isNonEmptyText(x)
        %ISNONEMPTYTEXT Return whether a value is a nonempty text scalar.
            % check if text is non-empty
            tf = (ischar(x) || (isstring(x) && isscalar(x))) && strlength(string(x)) > 0;
        end

        function tf = isInLimits(XY,XLim,YLim)
        %ISINLIMITS Return whether a point lies inside the supplied axes limits.
            % check if the point, XY, is within limits, XLim and YLim
            x = XY(1); y = XY(2);
            tf = x >= XLim(1) && x <= XLim(2) && y >= YLim(1) && y <= YLim(2);
        end

        function I = placeholderImage()
        %PLACEHOLDERIMAGE Return the placeholder image used during startup.
            % return a placeholder image for startup
            I = zeros([256,256,3]); % all black truecolor array
        end

    end

    %% Public static helpers
    methods (Static)

        function names = getToolClassNames()
        %GETTOOLCLASSNAMES Return fully qualified built-in tool class names.
            % get cell array of char vectors of tool class names in matlabx.ui.axes.tools
            names = {matlab.metadata.Namespace.fromName("matlabx.ui.axes.tools").ClassList.Name}';
        end

        function names = getToolNames()
        %GETTOOLNAMES Return the short names of available built-in tools.
            % return names of all tool classes (just the last part)

            classNames = matlabx.ui.axes.ImageAxes.getToolClassNames();
            if numel(classNames)==0
                names = {};
                return
            else
                names = cell(1,numel(classNames));
                for i = 1:numel(classNames)
                    % split name with '.' delimeter
                    temp = strsplit(classNames{i},'.');
                    % tool name is after the final '.'
                    names(i) = temp(end);
                end
            end

        end

        function names = getContextMenuItemNames()
            %GETCONTEXTMENUITEMNAMES Return names of available built-in context items.
            names = cellstr(matlabx.ui.axes.ImageAxesContextMenuManager.availableBuiltinItems());
        end

        function names = getColorNames()
        %GETCOLORNAMES Return supported component color names.
            % return names of allowed component colors
            names = {'cyan','magenta','yellow','red','green','blue'};
        end

        function name = canonicalComponentColorName(name)
            %CANONICALCOMPONENTCOLORNAME Normalize to ImageAxes color names.
            %
            % matlabx.colors.names.fromRGB returns display-cased MATLAB palette
            % names. ImageAxes exposes lowercase component color names, so keep
            % internal ColorName state canonical before it reaches getters/links.

            name = string(name);
            if ~isscalar(name)
                error('ImageAxes:InvalidComponentColor', ...
                    'Component color must be a text scalar.');
            end

            canonicalNames = string(matlabx.ui.axes.ImageAxes.getColorNames());
            matchIdx = find(strcmpi(name, canonicalNames), 1, 'first');

            if isempty(matchIdx)
                error('ImageAxes:InvalidComponentColor', ...
                    'Component color "%s" must be one of: %s.', ...
                    char(name), strjoin(cellstr(canonicalNames), ', '));
            end

            name = canonicalNames(matchIdx);
        end

        function names = getDefaultTools()
        %GETDEFAULTTOOLS Return default tools.
            names = {'Zoom','Colorbar','ChooseColormap','DisplayLimits'};
        end

        function props = getLinkableProperties()
        %GETLINKABLEPROPERTIES Return linkable properties.
            props = { ...
                'C', ...
                'Z', ...
                'T', ...
                'Viewport', ...
                'ComponentColorMode', ...
                'ComponentColormaps', ...
                'ComponentColors', ...
                'ShowComposite', ...
                'ComponentCLims'};
        end

        function ax = demo(name)
        %DEMO Open one of the built-in ImageAxes demonstrations.
            arguments
                name (1,:) char {mustBeMember(name,{'default','multicomponent','empty'})}
            end

            fig = uifigure("WindowStyle","alwaysontop",...
                "Position",[0 0 500 500],...
                "Visible","off");

            switch name
                case 'default'
                    ax = matlabx.ui.axes.ImageAxes(fig,...
                        "Tools",{'Zoom','Colorbar'},...
                        "Units","normalized",...
                        "Position",[0 0 1 1],...
                        "CData",imread("rice.png"),...
                        "CLim",[0 1],...
                        "Colormap",gray);
                case 'empty'
                    ax = matlabx.ui.axes.ImageAxes(fig,...
                        "CData",[],...
                        "Tools",{'Zoom','Colorbar'},...
                        "Units","normalized",...
                        "Position",[0 0 1 1],...
                        "CLim",[0 1]);
                case 'multicomponent'
                    I1 = imread("rice.png");
                    I2 = imgaussfilt(I1);
                    cdata = {I1,I2};
                    ax = matlabx.ui.axes.ImageAxes(fig,...
                        "CData",cdata,...
                        "Tools",{'Zoom','Colorbar'},...
                        "Units","normalized",...
                        "Position",[0 0 1 1]);
            end

            movegui(fig,"center")

            fig.Visible = "on";

        end

        function [viewer1,viewer2] = linkDemo()
        %LINKDEMO Open two viewers with linked image and viewport state.
            I = matlabx.image.Image5D.demo();

            [viewer1,~] = matlabx.app.quickshow(I,"Title","Viewer 1","Location","west");

            [viewer2,~] = matlabx.app.quickshow(I,"Title","Viewer 2","Location","east");

            viewer1.addLink(viewer2,{'C','Z','T',...
                'Viewport','ShowComposite','ComponentColors',...
                'ComponentColormaps','ComponentCLims'});
        end

        function ax = demoImage5D()
        %DEMOIMAGE5D Display the built-in multidimensional Image5D example.
            I = matlabx.image.Image5D.demo();
            ax = matlabx.app.quickshow(I,"Title","Example 5D Image");
        end


        function [ax,fig] = demoSegmentation(opts)
        %DEMOSEGMENTATION Inspect segmented rice with a mask and polygon regions.
        %
        %   ax = matlabx.ui.axes.ImageAxes.demoSegmentation() displays rice.png.
        %   Use Mask/Overlays to flicker the results, RectangleSelect for batch
        %   selection, and the Polygon context menu to delete regions.
        %   Deleting a polygon leaves the display mask unchanged.
        %   Requires Image Processing Toolbox.
            arguments
                opts.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
            end

            I = imread('rice.png');
            % Remove slowly varying illumination before thresholding the grains.
            background = imopen(I, strel('disk',15,0));
            mask = imbinarize(I - background);
            mask = bwareaopen(mask, 50, 8);
            mask = imfill(mask, 'holes');
            % Pixel-edge tracing avoids backtracking along thin pixel centers.
            boundaries = bwboundaries(mask, 8, 'noholes', 'TraceStyle', 'pixeledge');

            [ax,fig] = matlabx.app.quickshow(I, ...
                "Title", "Rice Segmentation", ...
                "Tools", {'Zoom','Mask','Overlays','Polygon','RectangleSelect'}, ...
                "Visible", "off");
            ax.Mask = mask;
            ax.MaskEnabled = "on";
            ax.Tools.RectangleSelect.TargetTypes = "Polygon";

            for i = 1:numel(boundaries)
                % bwboundaries returns [row column]; overlays use [x y].
                vertices = boundaries{i}(:,[2 1]);
                ax.Tools.Polygon.addPolygon("rice-" + i, vertices, ...
                    "Label", "Grain " + i, ...
                    "EdgeColor", [0 1 0], ...
                    "FaceColor", [0 1 0]);
            end

            fig.Visible = opts.Visible;
        end

        function ax = demoOverlays()
        %DEMOOVERLAYS Display an example viewer with native overlay tools.
            I = matlabx.image.Image5D.demo();
            ax = matlabx.app.quickshow(I,...
                "Title","Overlay Demo", ...
                "Tools",{'Zoom','Line','Point','Rectangle','Box','RectangleSelect'}, ...
                "ComponentColorMode","colors", ...
                "Location","center");
        end




    end

    %% Application overlay mounting
    % Passive application content has its own lifetime registry. It does not
    % participate in the interactive overlay manager's selection or tools.
    % Application overlay mounts and early-teardown listeners.
    properties (Access=private)
        % Graphics parent for passive application-mounted content.
        ApplicationOverlayLayer = []
        % Mount relationships currently owned by this host.
        ApplicationOverlayMounts = {}
        % Listener that detaches mounts before axes teardown.
        ApplicationOverlayLifetimeListener = []
        % Listener that uninstalls tools before toolbar teardown.
        ToolLifetimeListener = []
    end

    methods
        function mount = mountOverlay(obj,content)
        %MOUNTOVERLAY Attach application-owned passive content, or transfer it.
            arguments
                obj
                content (1,1) matlabx.ui.axes.ImageAxesOverlayContent
            end
            if ~isvalid(content)
                error('matlabx:ui:InvalidOverlayContent','Content has been deleted.');
            end
            previous = content.Mount;
            if ~isempty(previous) && isvalid(previous)
                if any(cellfun(@(m) m == previous,obj.ApplicationOverlayMounts))
                    mount = previous;
                    return;
                end
                previous.remove();
            end
            mount = matlabx.ui.axes.ImageAxesOverlayMount( ...
                obj,content,obj.ApplicationOverlayLayer);
            obj.ApplicationOverlayMounts{end+1} = mount;
            content.Mount = mount;
            try
                mount.attachContent();
            catch exception
                % Detach partial graphics while preserving the attach error.
                try
                    mount.remove();
                catch
                    % The mount's cleanup still deletes its graphics group.
                end
                rethrow(exception);
            end
        end

        function unmountOverlay(obj,content)
        %UNMOUNTOVERLAY Remove only this host's relationship with content.
            mounts = obj.ApplicationOverlayMounts;
            for k = 1:numel(mounts)
                if mounts{k}.Content == content
                    mounts{k}.remove();
                    return;
                end
            end
        end
    end

    methods (Access=?matlabx.ui.axes.ImageAxesOverlayMount)
        function releaseOverlayMount(obj,mount)
        %RELEASEOVERLAYMOUNT Remove a detached application overlay mount from host bookkeeping.
            obj.ApplicationOverlayMounts = obj.ApplicationOverlayMounts( ...
                ~cellfun(@(m) m == mount,obj.ApplicationOverlayMounts));
        end
    end

    methods (Access=private)
        function detachApplicationOverlays(obj)
        %DETACHAPPLICATIONOVERLAYS Detach every mounted application overlay before teardown.
            % Snapshot because each removal unregisters itself. Continue even
            % if application cleanup fails, so other content can survive.
            mounts = obj.ApplicationOverlayMounts;
            for k = 1:numel(mounts)
                if isvalid(mounts{k})
                    try
                        mounts{k}.remove();
                    catch exception
                        warning('matlabx:ui:OverlayDetachFailed','%s',exception.message);
                    end
                end
            end
        end
    end

    %% Teardown
    methods

        function delete(obj)
        %DELETE Release tools, overlays, listeners, windows, and hub registration.

            if ~isempty(obj.ToolManager) && isvalid(obj.ToolManager)
                obj.ToolManager.uninstallAll();
            end
            obj.detachApplicationOverlays();

            % remove listeners first
            if ~isempty(obj.ResizeListener)
                delete(obj.ResizeListener(isvalid(obj.ResizeListener)));
            end
            obj.ResizeListener = event.listener.empty;
            obj.clearInitialToolbarFocusListener();
            if ~isempty(obj.L), delete(obj.L(isvalid(obj.L))); end
            % replace listener property with empty array of event.listener
            obj.L = event.listener.empty;

            % displayLimitsWindow
            if ~isempty(obj.displayLimitsWindow)
                delete(obj.displayLimitsWindow(isvalid(obj.displayLimitsWindow)));
            end

            % metadataWindow
            if ~isempty(obj.metadataWindow), delete(obj.metadataWindow(isvalid(obj.metadataWindow))); end
            % imagePropertiesWindow
            if ~isempty(obj.imagePropertiesWindow)
                delete(obj.imagePropertiesWindow(isvalid(obj.imagePropertiesWindow)));
            end

            % ViewportBox
            delete(obj.ViewportBoxFull(isvalid(obj.ViewportBoxFull)));
            delete(obj.ViewportBox(isvalid(obj.ViewportBox)));

            % overlays
            if ~isempty(obj.OverlayManager) && isvalid(obj.OverlayManager)
                obj.OverlayManager.clear();
            end

            % Unregister from hub (safe if figure already gone)
            try
                if ~isempty(obj.Hub) && isvalid(obj.Hub) && ~isnan(obj.RouterId)
                    obj.Hub.unregister(obj.RouterId);
                end
            catch
            end

            % unload (delete) all tools before deleting ImageAxes
            obj.unloadAllTools();

        end

    end

end
