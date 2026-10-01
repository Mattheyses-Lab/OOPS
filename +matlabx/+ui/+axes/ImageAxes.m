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

classdef ImageAxes < matlab.ui.componentcontainer.ComponentContainer
%IMAGEAXES Image5D-backed UI image display and interaction component.
%
%   matlabx.ui.axes.ImageAxes displays a selected 2-D plane or RGB
%   composite from a matlabx.image.Image5D object. It also hosts
%   AxesTool subclasses and receives figure-level mouse/key events
%   through matlabx.ui.interaction.FigureEventHub.
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


    %% Tools

    properties (Dependent)
        % Assign names to install tools; read back installed tool objects.
        Tools
        % Overlay manager for image-space annotations and visual aids.
        Overlays
    end

    properties (Access={?matlabx.ui.axes.ImageAxesToolManager})
        % manager for tool lifecycle, routing lookup, and installed tool objects
        ToolManager matlabx.ui.axes.ImageAxesToolManager
        % registry of host/tool hotkeys
        HotkeyRegistry matlabx.ui.axes.ImageAxesHotkeyRegistry
    end

    properties (Access={?matlabx.ui.axes.AxesTool, ?matlabx.ui.axes.ImageAxesToolManager})
        % the currently enabled tool with IsExclusive=true (if it exists)
        ActiveExclusiveTool
        % struct() of ToolbarButtons, fieldnames match tool Name
        ToolbarButtons struct = struct()
    end

    %% Public configuration
    properties (AbortSet)
        Name (1,1) string = ""
    end

    properties (Dependent, AbortSet)
        % ImageAxes built-in context menu items to show.
        ContextMenuItems
        ViewportBoxVisible (1,1) matlab.lang.OnOffSwitchState
    end

    % Graphics passthroughs
    properties (Dependent)
        ImageVisible
        AxesVisible
        ColorbarVisible
        Colormap (256,3) double
        MaxRenderedResolution
    end

    %% Image model, render state, and display state

    % Canonical image data and compatibility input.
    properties (Dependent, AbortSet)
        ImageData           (1,1) matlabx.image.Image5D
        CData               {mustBeA(CData,{'double','single','uint8','uint16','logical','cell'})}
    end

    % Observable view/display controls.
    properties (Dependent, AbortSet, SetObservable)
        C (1,1) double
        Z (1,1) double
        T (1,1) double
        ShowComposite       (1,1) matlab.lang.OnOffSwitchState
        CLim                (1,2) double
        CLimMode            (1,:) char {mustBeMember(CLimMode,{'auto','manual'})}
        ComponentCLims      (1,:) cell
        ComponentColors     (1,:) cell
        ComponentColormaps  (1,:) cell
        ComponentColorMode  (1,:) char {mustBeMember(ComponentColorMode,{'colors','luts'})}
    end

    % Read-only render/display information.
    properties (Dependent, SetAccess=private)
        RenderSource
        RenderSourceKind       (1,:) char {mustBeMember(RenderSourceKind,{'scalar','rgb'})}
        RenderSourceSize       (1,:) double
        RenderSourceClass      (1,:) char {mustBeMember(RenderSourceClass,{'double','single','uint8','uint16','logical',''})}
        DisplayCData
        CanMergeComponents  (1,1) logical

        % Compatibility aliases for RenderSource* metadata.
        CDataKind       (1,:) char {mustBeMember(CDataKind,{'scalar','rgb'})}
        CDataSize       (1,:) double
        CDataClass      (1,:) char {mustBeMember(CDataClass,{'double','single','uint8','uint16','logical',''})}
        
        NumComponents         (1,1) double
        MultiComponent        (1,1) matlab.lang.OnOffSwitchState
        MultiComponentKind    (1,:) {mustBeMember(MultiComponentKind,{'scalar','rgb','mixed','none'})}
    end

    properties (Access=private)
        % Current view coordinates and display modes.
        ViewState_ (1,1) matlabx.ui.axes.ImageAxesViewState = matlabx.ui.axes.ImageAxesViewState()

        % Canonical Image5D data model.
        ImageData_ (1,1) matlabx.image.Image5D = matlabx.image.Image5D.fromComponents(zeros(256,256,3))

        % Selected source plane or computed composite, before display scaling.
        RenderSource_ (:,:,:) = matlabx.ui.axes.ImageAxes.placeholderImage

        % Per-component contrast/color/LUT display state.
        ComponentDisplay_ (1,:) matlabx.ui.axes.ImageAxesComponentDisplayState = matlabx.ui.axes.ImageAxesComponentDisplayState.empty()
    end

    %% UI/Graphics

    % private
    properties (Access=private, Transient, NonCopyable)
        % UI components
        Grid matlab.ui.container.GridLayout
        Panel matlab.ui.container.Panel
        staticAxes matlab.ui.control.UIAxes
        hImage matlab.graphics.primitive.Image
        BottomLabel (1,1) matlab.graphics.primitive.Text
        Colorbar matlab.graphics.illustration.ColorBar
        sizingGrid matlab.ui.container.GridLayout
        ViewportBoxFull (1,1) matlab.graphics.primitive.Patch
        ViewportBox (1,1) matlab.graphics.primitive.Patch


        % listeners
        L event.listener

    end

    properties (Access={?matlabx.ui.axes.ImageAxesToolManager}, Transient, NonCopyable)
        % manager for the host-owned context menu
        ContextMenuManager matlabx.ui.axes.ImageAxesContextMenuManager
        % manager for host-owned overlays
        OverlayManager matlabx.ui.axes.ImageAxesOverlayManager
    end

    % tool-accessible
    properties (Access={?matlabx.ui.axes.AxesTool, ?matlabx.ui.axes.ImageAxesToolManager})
        mainAxes matlab.ui.control.UIAxes
    end

    properties (Access=private)
        % uipanelOverheadPx_ (1,1) double = NaN
        UICal matlabx.ui.calibration.UICalibration
    end

    properties (Dependent, AbortSet)
        FontSize (1,1) double
    end

    properties (Access=private, AbortSet)
        FontSize_ (1,1) double = 12
        uipanelOverheadPx_ (1,1) double = 19
        ContextMenuItems_ (1,:) string = ["Image","Display","ResetView","Status"]
        ViewportBoxVisible_ (1,1) matlab.lang.OnOffSwitchState = "off"
    end


    properties (Access=private)
        % flags to help coalesce/manage updates
        pendingSizeUpdate (1,1) logical = false
        LastResizeLayoutKey_ (1,5) double = NaN(1,5)
        inStartup (1,1) logical = true
    end

    %% Popup/temporary UI management

    % popup windows
    properties (Access=private, Transient, NonCopyable)
        displayLimitsWindow (:,1) matlabx.ui.axes.ImageAxesDisplayLimitsWindow
        metadataWindow matlabx.app.TextWindow
        imagePropertiesWindow matlabx.app.TextWindow
        statusWindow matlabx.app.TextWindow
        toolHelpWindow matlabx.app.TextWindow
    end

    properties (Access=private)
        metadataWindowOpen (1,1) logical = false
        imagePropertiesWindowOpen (1,1) logical = false
        statusWindowOpen (1,1) logical = false
        toolHelpWindowOpen (1,1) logical = false
    end

    %% Derived properties (accessible to tools)
    properties (Access=?matlabx.ui.axes.AxesTool, Dependent)
        ParentFig
        ImageSize
        ImageWidth
        ImageHeight
        defaultXLim
        defaultYLim
        cursorPosition
        cursorPositionStatic
        activePixel
    end

    %% Tool helper variables
    properties (Access=?matlabx.ui.axes.AxesTool)
        % control XLim and YLim of axes holding the image (if empty, lims will be set to default)
        XLim = []
        YLim = []
    end

    %% Hub registration
    properties (Access=private)
        Hub matlabx.ui.interaction.FigureEventHub
        RouterId double = NaN
    end

    %% Events
    events (NotifyAccess=protected)
        RenderSourceChanged
        DisplayStateChanged
        ImageDataChanged
    end

    %% ComponentContainer lifecycle (setup/update)
    methods (Access=protected)

        function setup(obj)

            % perform/retrieve calibration first
            obj.UICal = matlabx.UICal.get();

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
            obj.mainAxes.Toolbar = axtoolbar(obj.mainAxes,{});
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
            obj.staticAxes.Toolbar = axtoolbar(obj.staticAxes,{});
            obj.staticAxes.Interactions = [];
            disableDefaultInteractivity(obj.staticAxes);
            obj.staticAxes.PlotBoxAspectRatio = [1 1 1];
            obj.staticAxes.DataAspectRatio = [1 1 1];

            % setup and store colorbar
            obj.Colorbar = colorbar(obj.mainAxes,"east","Visible","off","PickableParts","none","HitTest","off");

            % initialize overlay/tool lifecycle/hotkey managers
            obj.OverlayManager = matlabx.ui.axes.ImageAxesOverlayManager(obj);
            obj.ToolManager = matlabx.ui.axes.ImageAxesToolManager(obj);
            obj.HotkeyRegistry = matlabx.ui.axes.ImageAxesHotkeyRegistry();

            % Hub registration (one hub per figure; this instance registers itself)
            obj.Hub = matlabx.ui.interaction.FigureEventHub.ensure(obj.ParentFig);
            obj.RouterId = obj.Hub.register(obj,'Priority',10,'CaptureDuringDrag',true);

            % Image
            obj.hImage = image(obj.mainAxes,[],...
                'CDataMapping','scaled',...
                'HitTest','off',...
                'PickableParts','none');

            % Update CLim, PlotBoxAspectRatio, and DataAspectRatio *after* creating image object
            obj.mainAxes.CLim               = [0 1];
            obj.mainAxes.PlotBoxAspectRatio = [1 1 1];
            obj.mainAxes.DataAspectRatio    = [1 1 1];

            % set SizeChangedFcn so we can force visual update upon resizing (AutoResizeChildren of parent must be Off)
            obj.SizeChangedFcn = @(~,~) obj.updateOnResize();

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
            if obj.inStartup
                obj.FontSize_ = obj.FontSize;
                obj.uipanelOverheadPx_ = obj.UICal.uipanelTopChromeHeightPx(obj.FontSize_);
                obj.inStartup = false;
            end

            % set the Tag property of the axes used for event routing
            obj.mainAxes.Tag = obj.Name;
            obj.staticAxes.Tag = obj.Name;

            % set BackgroundColor
            obj.Grid.BackgroundColor = obj.BackgroundColor;
            % obj.Panel.BackgroundColor = obj.BackgroundColor;

            obj.sizingGrid.BackgroundColor = obj.BackgroundColor;

            obj.updateOnResize();

        end

        function setupContextMenu(obj)
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

    properties (Dependent)
        ZoomEnabled
        ZoomLevel
        ZoomFactor

        FollowCursorEnabled
        FollowCursorLims
    end

    % ViewportBox appearance
    properties
        ViewportBoxScale = 0.1
        ViewportBoxEdgeColor = [0 0 0]
        ViewportBoxFaceColor = [1 1 1]
        ViewportBoxFaceAlpha = 0.25
        ViewportBoxLineWidth = 1

        ViewportBoxTop = 0.01
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
            %ZOOMENABLED  True when mainAxes displays a zoomed viewport box.
            %
            %   Setting ZoomEnabled=true shows the miniature viewport boxes and applies
            %   the current ZoomLevel around the cursor when possible. Setting it
            %   false hides viewport boxes and restores full-image limits.

            z = obj.Zoom_.Enabled;
        end

        function set.ZoomEnabled(obj,tf)
            %ZOOMENABLED  Enable or disable zoom navigation.

            if tf
                obj.enableZoom();
            else
                obj.disableZoom();
            end
        end

        function p = get.FollowCursorEnabled(obj)
            %FOLLOWCURSORENABLED  True when the zoomed view follows cursor motion.
            %
            %   FollowCursor only affects motion while ZoomEnabled is true. When
            %   re-enabled, the current cursor/view relationship is anchored so the
            %   view does not jump to the absolute cursor-follow position.

            p = obj.FollowCursor_.Enabled;
        end

        function set.FollowCursorEnabled(obj,tf)
            %FOLLOWCURSORENABLED  Enable or disable cursor-follow navigation.

            if tf
                obj.enableFollowCursor();
            else
                obj.disableFollowCursor();
            end
        end

        function p = get.FollowCursorLims(obj)
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

            obj.Zoom_.Enabled = true;

            oldXLim = obj.mainAxes.XLim;
            oldYLim = obj.mainAxes.YLim;
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
        end

        function disableZoom(obj)
            %DISABLEZOOM  Disable zoom navigation and restore full-image view.

            if ~obj.ZoomEnabled
                return
            end

            % Remember the current view center before restoring full-image limits.
            % Re-enabling zoom should return to the same region, not to wherever
            % the cursor happens to be when a toolbar button is clicked.
            obj.Zoom_.LastCursorXY = obj.currentViewCenter();
            obj.Zoom_.LastFactor = obj.ZoomFactor;

            % Restore full-image limits while preserving the stored zoom anchor.
            obj.resetViewport(PreserveZoomState=true);

            obj.clearFollowCursorAnchor();

            obj.Zoom_.Enabled = false;
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
        end

        function toggleFollowCursorEnabled(obj)
            %TOGGLEFOLLOWCURSORENABLED  Flip state of FollowCursorEnabled.

            obj.FollowCursorEnabled = ~obj.FollowCursor_.Enabled;
        end

    end






    %% Axes linking
    properties (SetAccess=?matlabx.ui.axes.ImageAxesLinkManager)
        hasLinks        (1,1) logical = false
    end

    properties (Access=?matlabx.ui.axes.ImageAxesLinkManager)
        linkedAxes      (1,:) = []
        linkedProps     (1,:) cell = {}
        LinkListener    event.listener
    end

    methods

        function addLink(obj, links, props)
            %ADDLINK Link selected ImageAxes properties across multiple axes.
            %
            % The link is bidirectional: this axes listens for changes and pushes
            % them to every linked axes, and each linked axes does the same for the
            % same property set. Properties should be SetObservable and safe to
            % assign through their public setters.

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







    %% UI helpers
    methods (Access=private)
        %% --- UI refresh helpers ---

        function updateOnResize(obj)
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
            if isvalid(obj)
                obj.pendingSizeUpdate = false;
            end
        end

        function S = computeResizeLayout(obj)
            S = matlabx.ui.axes.ImageAxesResizeLayout.compute( ...
                obj, ...
                obj.ImageData_.SizeY, ...
                obj.ImageData_.SizeX, ...
                obj.uipanelOverheadPx_);
        end

        function S = getSizeDiagnostics(obj)
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
                "InStartup", obj.inStartup);

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
            matlabx.ui.axes.ImageAxesDisplayRenderer.updateImageCData( ...
                obj.hImage, obj.DisplayCData);
        end

        function updateColorbar(obj)
            matlabx.ui.axes.ImageAxesDisplayRenderer.updateColorbar( ...
                obj.Colorbar, ...
                obj.ImageData_, ...
                obj.ComponentDisplay_, ...
                obj.ViewState_.C);
        end

        function updateAxesColormap(obj)
            matlabx.ui.axes.ImageAxesDisplayRenderer.updateAxesColormap( ...
                obj.mainAxes, ...
                obj.ComponentDisplay_, ...
                obj.ViewState_.C);
        end

        function updateFontSizes(obj)
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
            obj.ContextMenuManager.refresh();
        end


        %% --- UI text helpers ---

        function s = getImageInfoString(obj)
            s1 = sprintf(strjoin(repmat({'%i'},1,numel(obj.RenderSourceSize)),'x'),obj.RenderSourceSize);
            s2 = sprintf('%s (%s)',obj.RenderSourceClass,obj.RenderSourceKind);
            s = [s1,' ',s2];
        end

        function s = getComponentInfoString(obj)
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
            if obj.ImageData_.SizeZ > 1
                s = sprintf('Z: %i/%i', obj.ViewState_.Z, obj.ImageData_.SizeZ);
            else
                s = '';
            end
        end

        function s = getTInfoString(obj)
            if obj.ImageData_.SizeT > 1
                s = sprintf('T: %i/%i', obj.ViewState_.T, obj.ImageData_.SizeT);
            else
                s = '';
            end
        end

        function s = getImageSizeString(obj)
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
        function v = get.ImageData(obj), v = obj.ImageData_; end
    
        function set.ImageData(obj, val)
            arguments
                obj
                val (1,1) matlabx.image.Image5D
            end

            oldSummary = obj.getImageDataEventSummary_();
            obj.ImageData_ = val;
            obj.syncViewStateToImageData();
            obj.syncSelfFromFirstLinkedPeer();
            obj.syncRenderSourceToView(ResetView=true);
            obj.notifyImageDataChanged_(oldSummary, obj.getImageDataEventSummary_());
        end
    
        % --- CData: compatibility alias for raw image input/current source ---
        function v = get.CData(obj), v = obj.RenderSource; end
    
        function set.CData(obj, cdata)
            % Convenience wrapper to set ImageData without constructing an Image5D.
            if isempty(cdata)
                cdata = matlabx.ui.axes.ImageAxes.placeholderImage();
            end

            oldSummary = obj.getImageDataEventSummary_();
            obj.ImageData_ = matlabx.image.Image5D.fromComponents(cdata);

            obj.syncViewStateToImageData();
            obj.syncSelfFromFirstLinkedPeer();
            obj.syncRenderSourceToView(ResetView=true);
            obj.notifyImageDataChanged_(oldSummary, obj.getImageDataEventSummary_());
        end

        % --- RenderSource: selected plane or computed composite ---
        function v = get.RenderSource(obj), v = obj.RenderSource_; end

        function v = get.RenderSourceSize(obj)
            if obj.ViewState_.ShowComposite
                v = size(obj.RenderSource_);
            else
                v = obj.ImageData_.getComponentSize(obj.ViewState_.C);
            end
        end
    
        function v = get.RenderSourceKind(obj)
            if obj.ViewState_.ShowComposite
                v = 'rgb';
            else
                v = obj.ImageData_.getComponentKind(obj.ViewState_.C);
            end
        end
    
        function v = get.RenderSourceClass(obj)
            if obj.ViewState_.ShowComposite
                v = class(obj.RenderSource_);
            else
                v = obj.ImageData_.getComponentClass(obj.ViewState_.C);
            end
        end

        % --- CData metadata compatibility aliases ---
        function v = get.CDataSize(obj),  v = obj.RenderSourceSize;  end
        function v = get.CDataKind(obj),  v = obj.RenderSourceKind;  end
        function v = get.CDataClass(obj), v = obj.RenderSourceClass; end

        % --- DisplayCData: graphics-ready image CData ---
        function v = get.DisplayCData(obj)
            v = matlabx.ui.axes.ImageAxesDisplayRenderer.getDisplayCData( ...
                obj.RenderSource_, ...
                obj.ImageData_, ...
                obj.ComponentDisplay_, ...
                obj.ViewState_);
        end

        % --- CLim ---
        function v = get.CLim(obj)
            idx = obj.ViewState_.C;
            clim = obj.ComponentDisplay_(idx).CLim;
    
            if isempty(clim)
                v = [0 1];
            else
                v = clim;
            end
        end
    
        function set.CLim(obj, val)
            obj.setComponentCLim(double(val), obj.ViewState_.C);
        end

        % --- CLimMode ---
        function v = get.CLimMode(obj)
            v = obj.ViewState_.CLimMode;
        end
    
        function set.CLimMode(obj, val)
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
        function v = get.NumComponents(obj), v = obj.ImageData_.NumComponents; end

        % --- MultiComponent ---
        function v = get.MultiComponent(obj), v = obj.ImageData_.MultiComponent; end

        % --- MultiComponentKind ---
        function v = get.MultiComponentKind(obj), v = obj.ImageData_.MultiComponentKind; end

        % --- CanMergeComponents ---
        function tf = get.CanMergeComponents(obj), tf = obj.ImageData_.CanMergeComponents; end


        % --- ShowComposite ---
        function v = get.ShowComposite(obj), v = matlab.lang.OnOffSwitchState(obj.ViewState_.ShowComposite); end
    
        function set.ShowComposite(obj, val)
            newVal = logical(val) && obj.CanMergeComponents;

            if obj.ViewState_.ShowComposite == newVal
                return
            end

            obj.ViewState_.ShowComposite = newVal;
            obj.syncRenderSourceToView();
        end
    
        % --- toggleComposite ---
        function toggleComposite(obj), obj.ShowComposite = ~obj.ViewState_.ShowComposite; end


        %% C/Z/T control

        % --- nextComponent ---
        function nextComponent(obj), obj.C = matlabx.utils.math.wrapStep(obj.C,1,1,obj.NumComponents); end
    
        % --- previousComponent ---
        function previousComponent(obj), obj.C = matlabx.utils.math.wrapStep(obj.C,-1,1,obj.NumComponents); end
    
        % --- C ---
        function v = get.C(obj), v = obj.ViewState_.C; end
    
        function set.C(obj, val)
            newVal = clip(val, 1, obj.NumComponents);

            if obj.ViewState_.C == newVal
                return
            end

            obj.ViewState_.C = newVal;
            obj.syncRenderSourceToView();
        end


        % --- nextZ ---
        function nextZ(obj), obj.Z = matlabx.utils.math.wrapStep(obj.Z,1,1,obj.ImageData_.SizeZ); end
    
        % --- previousZ ---
        function previousZ(obj), obj.Z = matlabx.utils.math.wrapStep(obj.Z,-1,1,obj.ImageData_.SizeZ); end
    
        % --- Z ---
        function v = get.Z(obj), v = obj.ViewState_.Z; end
    
        function set.Z(obj, val)
            newVal = clip(val, 1, obj.ImageData_.SizeZ);

            if obj.ViewState_.Z == newVal
                return
            end

            obj.ViewState_.Z = newVal;
            obj.syncRenderSourceToView();
        end

        % --- nextT ---
        function nextT(obj), obj.T = matlabx.utils.math.wrapStep(obj.T,1,1,obj.ImageData_.SizeT); end
    
        % --- previousT ---
        function previousT(obj), obj.T = matlabx.utils.math.wrapStep(obj.T,-1,1,obj.ImageData_.SizeT); end
    
        % --- T ---
        function v = get.T(obj), v = obj.ViewState_.T; end
    
        function set.T(obj, val)
            newVal = clip(val, 1, obj.ImageData_.SizeT);

            if obj.ViewState_.T == newVal
                return
            end

            obj.ViewState_.T = newVal;
            obj.syncRenderSourceToView();
        end


        %% Component-specific set/get

        % --- Colormap ---
        function v = get.Colormap(obj), v = obj.ComponentDisplay_(obj.ViewState_.C).DisplayMap; end

        function set.Colormap(obj, val)
            idx = obj.ViewState_.C;
            obj.setComponentColormap(double(val), idx);
        end


        % --- ComponentColors ---
        function val = get.ComponentColors(obj)
            val = cell(1, obj.NumComponents);
            for i = 1:obj.NumComponents
                val{i} = char(obj.ComponentDisplay_(i).ColorName);
            end
        end
    
        function set.ComponentColors(obj, val)
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
            val = cell(1, obj.NumComponents);
            for i = 1:obj.NumComponents
                val{i} = obj.ComponentDisplay_(i).Colormap;
            end
        end
    
        function set.ComponentColormaps(obj, val)
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
        function v = get.ComponentColorMode(obj), v = obj.ViewState_.ComponentColorMode; end
    
        function set.ComponentColorMode(obj, val)
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
            val = cell(1, obj.NumComponents);
            for i = 1:obj.NumComponents
                val{i} = obj.ComponentDisplay_(i).CLim;
            end
        end
    
        function set.ComponentCLims(obj, val)
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
            obj.ComponentDisplay_ = matlabx.ui.axes.ImageAxesDisplayRenderer.updateAllDisplayMaps( ...
                obj.ComponentDisplay_, obj.ViewState_.ComponentColorMode);
        end
    
        function map = getDisplayMap(~, displayState, mode)
            map = matlabx.ui.axes.ImageAxesDisplayRenderer.getDisplayMap(displayState, mode);
        end
    
        function I = getCompositeImage(obj)
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
            obj.updateBottomLabelText();
            obj.updatePointer();
        end

        function restoreDefaultLimits(obj)
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
            cursorPosition = obj.mainAxes.CurrentPoint(1,[1,2]);
            % return empty if outside limits
            if ~obj.isInLimits(cursorPosition,obj.mainAxes.XLim,obj.mainAxes.YLim)
                cursorPosition = [];
            end
        end

        function cursorPositionStatic = get.cursorPositionStatic(obj)
            cursorPositionStatic = obj.staticAxes.CurrentPoint(1,[1,2]);
            % return empty if outside limits
            if ~obj.isInLimits(cursorPositionStatic,obj.staticAxes.XLim,obj.staticAxes.YLim)
                cursorPositionStatic = [];
            end
        end

        function px = get.activePixel(obj)
            % cursor position in axes
            XY = obj.cursorPosition;
            % empty -> return
            if isempty(XY), px = []; return, end
            % round to integer px indices, clip to image dimensions
            px = [clip(round(XY(1)),1,obj.ImageWidth), clip(round(XY(2)),1,obj.ImageHeight)];
        end

        % image dimensions
        function s = get.ImageSize(obj),    s = obj.RenderSourceSize;    end
        function h = get.ImageHeight(obj),  h = obj.ImageSize(1); end
        function w = get.ImageWidth(obj),   w = obj.ImageSize(2); end

        % default axes limits (set to prefectly enclose image)
        function x = get.defaultXLim(obj),  x = [0 obj.ImageWidth] + 0.5; end
        function y = get.defaultYLim(obj),  y = [0 obj.ImageHeight] + 0.5; end

        % retrieve fig/axes handles
        function f = get.ParentFig(obj),    f = ancestor(obj,'Figure'); end
        function ax = getAxes(obj),         ax = obj.mainAxes; end
        function ax = getOverlayAxes(obj),  ax = obj.staticAxes; end

        % axes/image passthroughs (Set/Get)

        % ImageVisible
        function v = get.ImageVisible(obj),v = obj.hImage.Visible; end
        function set.ImageVisible(obj,val),obj.hImage.Visible = val; end
        % AxesVisible
        function v = get.AxesVisible(obj), v = obj.mainAxes.Visible; end
        function set.AxesVisible(obj,val), obj.mainAxes.Visible = val; end
        % ColorbarVisible
        function v = get.ColorbarVisible(obj), v = obj.Colorbar.Visible; end
        function set.ColorbarVisible(obj,val), obj.Colorbar.Visible = val; end
        % MaxRenderedResolution
        function v = get.MaxRenderedResolution(obj), v = obj.hImage.MaxRenderedResolution; end
        function set.MaxRenderedResolution(obj,val), obj.hImage.MaxRenderedResolution = val; end
        % ContextMenuItems
        function items = get.ContextMenuItems(obj)
            items = obj.ContextMenuItems_;
        end
        function set.ContextMenuItems(obj, items)
            items = matlabx.ui.axes.ImageAxesContextMenuManager.validateBuiltinItems(items);
            obj.ContextMenuItems_ = items;
            if ~isempty(obj.ContextMenuManager)
                obj.ContextMenuManager.setBuiltinItems(items);
            end
        end
        % ViewportBoxVisible
        function val = get.ViewportBoxVisible(obj)
            val = obj.ViewportBoxVisible_;
        end
        function set.ViewportBoxVisible(obj,val)
            obj.ViewportBoxVisible_ = val;
            obj.updateViewportBoxVisibility();
            obj.refreshContextMenu();
        end

        % FontSize
        function set.FontSize(obj,val)
            obj.FontSize_ = val;
            obj.updateFontSizes();
            obj.updateOnResize();
        end

        function v = get.FontSize(obj)
            v = obj.FontSize_;
        end

    end

    %% Hub-facing event handlers (matches | onDown | onMove | onUp | onScroll | onKeyPress | onKeyRelease | onEnter | onLeave)
    methods

        % determine whether this instance should claim event from FigureEventHub
        function tf = matches(obj, E)
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
            obj.routeEventToTools(E);

            if E.StopPropagation, return; end

            obj.onDown_(E);
        end

        function onMove(obj, E)
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
            obj.routeEventToTools(E);
        end

        function onScroll(obj, E)
            obj.routeEventToTools(E);
        end

        function onKeyPress(obj, E)
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
            obj.routeEventToTools(E);
        end

        function onEnter(obj,E)
            obj.BottomLabel.Visible = "on";
            obj.ToolManager.notifyHostEnter(E);
        end

        function onLeave(obj,E)
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
            obj.updateBottomLabelText();
            obj.updatePointer();
        end

        function onDown_(obj,E)

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
            % true if h is child of this ImageAxes
            ia = ancestor(h,'matlabx.ui.axes.ImageAxes');

            if isempty(ia)
                tf = false;
            else
                tf = ia == obj;
            end
        end

        function tf = isAxesChild(obj,h)
            % true if h is child of UIAxes belonging to this ImageAxes
            ax = ancestor(h,'matlab.ui.control.UIAxes');
            tf = ~isempty(ax) && strcmp(ax.Tag,obj.Name);
        end

        function tf = isToolbarButtonChild(~,h)
            % true if h is child of ToolbarStateButton or ToolbarPushButton (in any axes)
            % btn = ancestor(h,'matlab.ui.controls.ToolbarStateButton');
            % if isempty(btn)
            %     btn = ancestor(h,'matlab.ui.controls.ToolbarPushButton');
            % end

            tf = ~isempty(ancestor(h,'matlab.ui.controls.ToolbarStateButton')) || ...
                ~isempty(ancestor(h,'matlab.ui.controls.ToolbarPushButton'));
        end

        function btn = getToolbarButtonFromTarget(~,target)
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
            if isempty(obj.HotkeyRegistry)
                return
            end

            obj.HotkeyRegistry.dispatch(E);
        end

        function routeToPassiveInterceptors(obj,E)
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
            obj.ToolManager.register(tool);
        end

        % remove tool from installed tool registry - it remains loaded
        function unregisterTool(obj, tool)
            obj.ToolManager.unregister(tool);
        end

        % load all tools in matlabx.ui.axes.tools
        function loadAllTools(obj)
            obj.ToolManager.loadAll();
        end

        % unload all currently loaded tools
        function unloadAllTools(obj)
            obj.ToolManager.unloadAll();
        end

        % load tools specified by toolNames (cell array of char vectors)
        function loadTools(obj,toolNames)
            obj.ToolManager.loadMany(toolNames);
        end

        % load tool specified by name
        function loadTool(obj, name)
            obj.ToolManager.load(name);
        end

        % unload tool specified by name
        function unloadTool(obj, name)
            obj.ToolManager.unload(name);
        end

        % install tools specified by toolNames (cell array of char vectors)
        function installTools(obj,toolNames)
            obj.ToolManager.installMany(toolNames);
        end

        % install tool specified by name
        function installTool(obj,name)
            obj.ToolManager.install(name);
        end

        % uninstall tool specified by name
        function uninstallTool(obj,name)
            obj.ToolManager.uninstall(name);
        end

    end

    %% Hotkey management
    methods

        function registerToolHotkeys(obj, tool)
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
            obj.ToolManager.addToolbarButton(tool);
        end

        % add a toolbar button for the tool (tool calls this on uninstall)
        function removeToolbarButton(obj, tool)
            obj.ToolManager.removeToolbarButton(tool);
        end

    end

    %% Toggle/query tool state
    methods

        % enable installed tool specified by name
        function enableTool(obj, name)
            obj.ToolManager.enable(name);
        end

        % disable installed tool specified by name
        function disableTool(obj, name)
            obj.ToolManager.disable(name);
        end

        % query Enabled state of tool specified by name
        function tf = toolEnabled(obj, name)
            tf = obj.ToolManager.enabled(name);
        end

        % toggle Enabled state of "state" tool specified by name (toolbar button ValueChangedFcn)
        function onToolToggle(obj,toolState,name)
            obj.ToolManager.toggle(toolState, name);
        end

        % run "push" tool specified by name (toolbar button ButtonPushedFcn)
        function onToolPush(obj,name)
            obj.ToolManager.push(name);
        end

        % run installed tool specified by name
        function runTool(obj, name)
            obj.ToolManager.run(name);
        end


        % disable ActiveExclusiveTool if it exists
        function disableActiveExclusive(obj)
            obj.ToolManager.disableActiveExclusive();
        end

    end

    %% Retrieve/sort tools
    methods

        % get installed tool specified by name
        function t = getInstalledTool(obj, name)
            t = obj.ToolManager.getInstalled(name);
        end

        % get loaded tool specified by name
        function t = getLoadedTool(obj, name)
            t = obj.ToolManager.getLoaded(name);
        end

        % get the highest Priority Interceptor for the specified eventType
        function tool = getPriorityInterceptor(obj,eventType)
            tool = obj.ToolManager.getPriorityInterceptor(eventType);
        end

        % get cell array of PassiveInterceptors for the specified eventType, sorted by descending Priority
        function toolsCell = getPriorityPassiveInterceptors(obj,eventType)
            toolsCell = obj.ToolManager.getPriorityPassiveInterceptors(eventType);
        end

        % given a cell array of tools, return the same cell array sorted by descending Priority
        function toolsCell = prioritySortToolsCell(obj,toolsCell)
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
            obj.metadataWindowOpen = false;
        end

        % --- ImagePropertiesWindow ---
        function openImagePropertiesWindow(obj)
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
            obj.imagePropertiesWindowOpen = false;
        end

        % --- StatusWindow ---
        function openStatusWindow(obj)
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
            obj.toolHelpWindowOpen = false;
        end

    end

    %% Context menu callbacks
    methods

        function setComponentColorMode(obj,mode)
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
            % check if text is non-empty
            tf = (ischar(x) || (isstring(x) && isscalar(x))) && strlength(string(x)) > 0;
        end

        function tf = isInLimits(XY,XLim,YLim)
            % check if the point, XY, is within limits, XLim and YLim
            x = XY(1); y = XY(2);
            tf = x >= XLim(1) && x <= XLim(2) && y >= YLim(1) && y <= YLim(2);
        end

        function I = placeholderImage()
            % return a placeholder image for startup
            I = zeros([256,256,3]); % all black truecolor array
        end

    end

    %% Public static helpers
    methods (Static)

        function names = getToolClassNames()
            % get cell array of char vectors of tool class names in matlabx.ui.axes.tools
            names = {matlab.metadata.Namespace.fromName("matlabx.ui.axes.tools").ClassList.Name}';
        end

        function names = getToolNames()
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
            names = {'Zoom','Colorbar','ChooseColormap','DisplayLimits'};
        end

        function props = getLinkableProperties()
            props = { ...
                'C', ...
                'Z', ...
                'T', ...
                'ComponentColorMode', ...
                'ComponentColormaps', ...
                'ComponentColors', ...
                'ShowComposite', ...
                'ComponentCLims'};
        end

        function ax = demo(name)
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
            I = matlabx.image.Image5D.demo();

            [viewer1,~] = matlabx.app.quickshow(I,"Title","Viewer 1","Location","west");

            [viewer2,~] = matlabx.app.quickshow(I,"Title","Viewer 2","Location","east");

            viewer1.addLink(viewer2,{'C','Z','T',...
                'ShowComposite','ComponentColors',...
                'ComponentColormaps','ComponentCLims'});
        end

        function ax = demoImage5D()
            I = matlabx.image.Image5D.demo();
            ax = matlabx.app.quickshow(I,"Title","Example 5D Image");
        end


    end

    %% Teardown
    methods

        function delete(obj)

            % remove listeners first
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
