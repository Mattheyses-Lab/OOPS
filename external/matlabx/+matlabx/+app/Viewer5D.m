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

classdef Viewer5D < handle
% matlabx.app.Viewer5D - Image Visualizer App

    properties (Access=private,Transient,NonCopyable)
        % --- window and main grid ---
        Fig matlab.ui.Figure
        Grid matlab.ui.container.GridLayout
        % --- viewer ---
        Viewer matlabx.ui.axes.ImageAxes
        % --- menubar UI handles ---
        MenubarUI struct
    end

    % Priavte UI helpers
    properties (Access=private)
        % status flag for SizeChangedFcn 
        isResizingFigure (1,1) logical = false
        % One-shot timer used to fit tight/square windows after live resize settles.
        ResizeSettleTimer
        % UI Calibration
        UICal matlabx.ui.calibration.UICalibration
        % hotkey management
        CommandRouter matlabx.ui.interaction.CommandRouter
    end

    % internal UI values
    properties (Access=private)
        uipanelTopChromePx_ = 19
        previousFigurePosition_ = []
        ResizeSettleDelay_ (1,1) double = 0.1
        WindowSizeStep_ (1,1) double = 1.10
    end

    %% Public properties

    % Image, UI, visualization options
    properties
        Image matlabx.image.Image5D
        Title (1,1) string = "Viewer"
        BackgroundColor (1,3) = [0 0 0]
    end

    properties (SetObservable,AbortSet)
        FontSize (1,1) double = 12
    end

    %% Public properties with private backing
    properties (Dependent,SetObservable,AbortSet)
        WindowStyle (1,:) char {mustBeMember(WindowStyle,{'normal','alwaysontop'})}
        WindowState (1,:) char {mustBeMember(WindowState,{'normal','maximized','minimized','fullscreen'})}
        WindowShape (1,:) char {mustBeMember(WindowShape,{'normal','tight','square'})}
    end

    properties (Access=private)
        WindowStyle_ (1,:) char {mustBeMember(WindowStyle_,{'normal','alwaysontop'})} = 'normal'
        WindowState_ (1,:) char {mustBeMember(WindowState_,{'normal','maximized','minimized','fullscreen'})} = 'normal'
        WindowShape_ (1,:) char {mustBeMember(WindowShape_,{'normal','tight','square'})} = 'normal'
    end



    %% Read-only properties
    properties (SetAccess=private)
        Tag (1,:) char = "Viewer5D";
    end

    %% listeners
    properties (Access=private)
        L event.listener
    end


    %% Constructor/Destructor/update
    methods

        function obj = Viewer5D(I,opts)
            arguments
                I matlabx.image.Image5D = matlabx.image.Image5D.empty()
                opts.Title (1,1) string = "Viewer"
                opts.FontSize (1,1) double = 12
                opts.BackgroundColor (1,3) double = [0 0 0]
                opts.WindowStyle (1,:) char {mustBeMember(opts.WindowStyle,{'normal','alwaysontop'})} = 'normal'
                opts.WindowState (1,:) char {mustBeMember(opts.WindowState,{'normal','maximized','minimized','fullscreen'})} = 'normal'
                opts.WindowShape (1,:) char {mustBeMember(opts.WindowShape,{'normal','tight','square'})} = 'square'
            end

            if isempty(I)
                I = matlabx.image.Image5D.fromComponents({imread("rice.png")});
            end

            % assign image data
            obj.Image = I;

            % assign property values
            obj.Title               = opts.Title;
            obj.FontSize            = opts.FontSize;
            obj.BackgroundColor     = opts.BackgroundColor;

            % assign private backings
            obj.WindowStyle_         = opts.WindowStyle;
            obj.WindowState_         = opts.WindowState;
            obj.WindowShape_         = opts.WindowShape;

            % --- Log ---
            % get or init the Log
            matlabx.Log.get();
            matlabx.Log.DEBUG("Starting Viewer5D...");

            % --- UICalibration ---
            matlabx.Log.DEBUG("Calibrating UI...");
            try obj.setupUICalibration(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % --- Build GUI ---
            matlabx.Log.DEBUG("Building GUI...");
            try obj.buildGUI(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % --- Initial UI sync ---
            matlabx.Log.DEBUG("Refreshing UI...");
            try obj.refreshUI(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % --- Show figure ---
            matlabx.Log.DEBUG("Opening...");
            obj.Fig.Visible = 'on';

            % attach listeners (only listening to FontSize for now)
            obj.L = addlistener(obj, 'FontSize', 'PostSet', @(~,~) obj.onFontSizeChanged());

            % initial UI sync
            obj.refreshWindowSize();

        end

        function delete(obj)
            % remove listeners first
            if ~isempty(obj.L), delete(obj.L(isvalid(obj.L))); end
            obj.L = event.listener.empty;
            % stop timer callbacks that may still hold a reference to this object
            obj.deleteResizeSettleTimer();
            % delete UI components
            if ~isempty(obj.Viewer) && isvalid(obj.Viewer), delete(obj.Viewer); end
            if ~isempty(obj.Grid)   && isvalid(obj.Grid), delete(obj.Grid); end
            if ~isempty(obj.Fig)    && isvalid(obj.Fig),  delete(obj.Fig);  end
        end

    end

    %% temporary debug helpers
    methods

        function ax = getAxes(obj)
            ax = obj.Viewer.getAxes();
        end

        function ax = getImageAxes(obj)
            ax = obj.Viewer;
        end

    end

    %% setup helpers
    methods (Access=protected)

        function setupUICalibration(obj)
            obj.UICal = matlabx.UICal.get();
        end

        function buildGUI(obj)
            % --- Figure ---
            matlabx.Log.DEBUG("Setting up main figure window...");
            try obj.setupFigure(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % --- CommandRouter ---
            matlabx.Log.DEBUG("Setting up CommandRouter...");
            try obj.setupCommandRouter(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % --- Menubar ---
            matlabx.Log.DEBUG("Setting up Menubar...");
            try obj.setupMenubar(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % --- Grids ---
            matlabx.Log.DEBUG("Setting up Grid...");
            try obj.setupGrids(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % --- Viewer ---
            matlabx.Log.DEBUG("Setting up Viewer...");
            try obj.setupViewer(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

            % center the GUI after defining all graphics components
            movegui(obj.Fig,"center");
        end

        function setupFigure(obj)
            % create uifigure object
            obj.Fig = uifigure(...
                "WindowStyle",          obj.WindowStyle_,...
                "Position",             [0 0 500 500],...
                "Visible",              "off",...
                "AutoResizeChildren",   "off",...
                "Name",                 obj.Title,...
                "SizeChangedFcn",       @(~,~) obj.onFigureSizeChanged());
            obj.previousFigurePosition_ = [0 0 500 500];
            obj.setupResizeSettleTimer();
        end

        function setupCommandRouter(obj)
            obj.CommandRouter = matlabx.ui.interaction.CommandRouter('Parent',obj.Fig);
            obj.refreshHotkeys();
        end

        function setupResizeSettleTimer(obj)
            obj.ResizeSettleTimer = timer(...
                "ExecutionMode", "singleShot",...
                "StartDelay",    obj.ResizeSettleDelay_,...
                "BusyMode",      "drop",...
                "Name",          "Viewer5DResizeSettleTimer",...
                "TimerFcn",      @(~,~) obj.onResizeSettled());
        end

        function setupMenubar(obj)
            % Set up MenubarUI struct
            obj.MenubarUI = struct(...
                "File",struct(),...
                "Window",struct());

            % --- File ---
            obj.MenubarUI.File       = uimenu(obj.Fig,'Text','File');
            obj.MenubarUI.File_Load  = uimenu(obj.MenubarUI.File,'Text','Load...', 'MenuSelectedFcn',@(~,~) obj.onLoad(),'Accelerator','O');
            obj.MenubarUI.File_Close = uimenu(obj.MenubarUI.File,'Text','Close','MenuSelectedFcn',@(~,~) obj.onClose(),'Accelerator','X');

            % --- Window ---
            obj.MenubarUI.Window = uimenu(obj.Fig,'Text','Window');

            % WindowStyle
            S = struct("alwaysontop",[],"normal",[]);
            S.normal = uimenu(obj.MenubarUI.Window,'Text','normal','Tag','normal',...
                'MenuSelectedFcn',@(o,~) obj.onWindowStyleMenuSelected(o),'Checked','off');
            S.alwaysontop = uimenu(obj.MenubarUI.Window,'Text','always on top','Tag','alwaysontop',...
                'MenuSelectedFcn',@(o,~) obj.onWindowStyleMenuSelected(o),'Checked','off');
            obj.MenubarUI.Window_Style = S;

            % --- separator ---
            % WindowState
            S = struct("normal",[],"maximized",[],"minimized",[],"fullscreen",[]);
            S.normal = uimenu(obj.MenubarUI.Window,'Text','normal','Tag','normal',...
                'MenuSelectedFcn',@(o,~) obj.onWindowStateMenuSelected(o),'Checked','off','Separator','on');
            S.maximized = uimenu(obj.MenubarUI.Window,'Text','maximized','Tag','maximized',...
                'MenuSelectedFcn',@(o,~) obj.onWindowStateMenuSelected(o),'Checked','off');
            S.minimized = uimenu(obj.MenubarUI.Window,'Text','minimized','Tag','minimized',...
                'MenuSelectedFcn',@(o,~) obj.onWindowStateMenuSelected(o),'Checked','off');
            S.fullscreen = uimenu(obj.MenubarUI.Window,'Text','fullscreen','Tag','fullscreen',...
                'MenuSelectedFcn',@(o,~) obj.onWindowStateMenuSelected(o),'Checked','off');
            obj.MenubarUI.Window_State = S;

            % --- separator ---
            % WindowShape
            S = struct("normal",[],"tight",[],"square",[]);
            S.normal = uimenu(obj.MenubarUI.Window,'Text','normal','Tag','normal',...
                'MenuSelectedFcn',@(o,~) obj.onWindowShapeMenuSelected(o),'Checked','off','Separator','on');
            S.tight = uimenu(obj.MenubarUI.Window,'Text','tight','Tag','tight',...
                'MenuSelectedFcn',@(o,~) obj.onWindowShapeMenuSelected(o),'Checked','off');
            S.square = uimenu(obj.MenubarUI.Window,'Text','square','Tag','square',...
                'MenuSelectedFcn',@(o,~) obj.onWindowShapeMenuSelected(o),'Checked','off');
            obj.MenubarUI.Window_Shape = S;    

        end 

        function setupGrids(obj)
            % Main Grid
            obj.Grid = uigridlayout(obj.Fig,[1,1],...
                "ColumnWidth",{'1x'},...
                "RowHeight",{'1x'},...
                "Padding",[0 0 0 0],...
                "backgroundColor",obj.BackgroundColor);
        end

        function setupViewer(obj)
            % ImageAxes object for the viewer
            obj.Viewer = matlabx.ui.axes.ImageAxes(obj.Grid,...
                "Tools",     {'Zoom', 'Colorbar', 'ChooseColormap', 'DisplayLimits', 'Box', 'DrawRectangle'},...
                "ImageData",    obj.Image,...
                "Name",         "Viewer",...
                "FontSize",     obj.FontSize);
        end

    end

    %% Global UI sync helpers
    methods (Access=private)

        function refreshUI(obj)
            % empty Image -> clear out UI
            if isempty(obj.Image)
                obj.clearUI();
                return
            end
            obj.refreshCalibration();
            obj.refreshMenubar();
            obj.Viewer.ImageData = obj.Image;
            obj.refreshWindowName();
            obj.refreshWindowSize();
        end

        function clearUI(obj)
            % menubar
            obj.refreshMenubar();
            % window name
            obj.Fig.Name = obj.Title;
            % ImageViewer
            obj.Viewer.ImageData = [];
        end

        function refreshWindowName(obj)
            obj.Fig.Name = obj.Title;
        end

        function refreshWindowSize(obj)
        %REFRESHWINDOWSIZE Apply the selected figure shape policy.

            if isempty(obj.Fig) || ~isvalid(obj.Fig)
                return
            end

            % Programmatic Fig.Position changes fire SizeChangedFcn again. The guard
            % keeps those follow-up events from recursively reshaping the window.
            if obj.isResizingFigure
                return
            end

            obj.isResizingFigure = true;
            cleanupResizeFlag = onCleanup(@() obj.clearResizeGuard());

            % Figure states managed by the window manager should not be reshaped.
            if ~strcmp(obj.Fig.WindowState, 'normal')
                obj.previousFigurePosition_ = obj.Fig.Position;
                return
            end

            switch obj.WindowShape
                case 'tight'
                    if ~isempty(obj.Image)
                        obj.fitWindowToContentAspect(obj.Image.SizeY / obj.Image.SizeX);
                    end
                case 'square'
                    obj.fitWindowToContentAspect(1);
                case 'normal'
                    obj.previousFigurePosition_ = obj.Fig.Position;
            end
        end

        function clearResizeGuard(obj)
            if isvalid(obj)
                obj.isResizingFigure = false;
            end
        end

        function armDeferredWindowFit(obj)
        %ARMDEFERREDWINDOWFIT Fit the figure shortly after live resize stops.
        %
        %   SizeChangedFcn fires continuously during a mouse drag. Restarting a
        %   one-shot timer on each event gives the native window manager control
        %   during the drag, then applies Viewer5D's tight/square shape policy once
        %   the resize stream quiets down.

            if isempty(obj.ResizeSettleTimer) || ~isvalid(obj.ResizeSettleTimer)
                obj.setupResizeSettleTimer();
            end

            stop(obj.ResizeSettleTimer);
            start(obj.ResizeSettleTimer);
        end

        function deleteResizeSettleTimer(obj)
            if isempty(obj.ResizeSettleTimer)
                return
            end

            T = obj.ResizeSettleTimer;
            obj.ResizeSettleTimer = [];

            if isvalid(T)
                stop(T);
                delete(T);
            end
        end

        function refreshWindowState(obj)
            obj.Fig.WindowState = obj.WindowState_;
        end

        function refreshWindowStyle(obj)
            obj.Fig.WindowStyle = obj.WindowStyle_;
        end




        function refreshMenubar(obj)

            if isempty(obj.Image)
                % disable all menubar options
                names = fieldnames(obj.MenubarUI);
                for i = 1:numel(names)
                    obj.MenubarUI.(names{i}).Enable = "off";
                    obj.MenubarUI.(names{i}).Checked = "off";
                end
                % re-enable only File, and File->Load...
                set([obj.MenubarUI.File,obj.MenubarUI.File_Load],'Enable','on');
            else
                % enable all menubar options
                names = fieldnames(obj.MenubarUI);
                for i = 1:numel(names)
                    obj.MenubarUI.(names{i}).Enable = "on";
                end
            end

            % update WindowStyle menu options
            obj.MenubarUI.Window_Style.normal.Checked = strcmp(obj.WindowStyle,"normal");
            obj.MenubarUI.Window_Style.alwaysontop.Checked = strcmp(obj.WindowStyle,"alwaysontop");

            % update WindowState menu options
            obj.MenubarUI.Window_State.normal.Checked = strcmp(obj.WindowState,"normal");
            obj.MenubarUI.Window_State.maximized.Checked = strcmp(obj.WindowState,"maximized");
            obj.MenubarUI.Window_State.minimized.Checked = strcmp(obj.WindowState,"minimized");
            obj.MenubarUI.Window_State.fullscreen.Checked = strcmp(obj.WindowState,"fullscreen");

            % update WindowShape menu options
            obj.MenubarUI.Window_Shape.normal.Checked = strcmp(obj.WindowShape,"normal");
            obj.MenubarUI.Window_Shape.tight.Checked = strcmp(obj.WindowShape,"tight");
            obj.MenubarUI.Window_Shape.square.Checked = strcmp(obj.WindowShape,"square");
        end

        function refreshHotkeys(obj)
            if isempty(obj.CommandRouter) || ~isvalid(obj.CommandRouter)
                return
            end

            % MATLAB can report punctuation keys differently depending on the
            % keyboard, platform, and whether the numpad is used. Register the
            % common normalized variants so + and - feel like simple viewer
            % shortcuts instead of a keyboard-layout guessing game.
            increaseKeys = ["+", "add", "equal"];
            decreaseKeys = ["-", "hyphen", "minus", "subtract"];

            for key = increaseKeys
                obj.CommandRouter.addHotkey(key, @(~,~) obj.increaseWindowSize());
            end

            for key = decreaseKeys
                obj.CommandRouter.addHotkey(key, @(~,~) obj.decreaseWindowSize());
            end
        end

        function refreshCalibration(obj)
            obj.uipanelTopChromePx_ = obj.UICal.uipanelTopChromeHeightPx(obj.FontSize,"FontUnits","pixels");
        end


    end

    %% Dependent Set/Get
    methods

        % --- WindowState ---
        function set.WindowState(obj,val)
            obj.WindowState_ = val;
            obj.refreshWindowState();
            obj.refreshMenubar();
        end

        function val = get.WindowState(obj), val = obj.WindowState_; end

        % --- WindowStyle ---
        function set.WindowStyle(obj,val)
            obj.WindowStyle_ = val;
            obj.refreshWindowStyle();
            obj.refreshMenubar();
        end

        function val = get.WindowStyle(obj), val = obj.WindowStyle_; end

        % --- WindowShape ---
        function set.WindowShape(obj,val)
            obj.WindowShape_ = val;
            obj.refreshWindowSize();
            obj.refreshMenubar();
        end

        function val = get.WindowShape(obj), val = obj.WindowShape_; end

    end

    %% Window UI Helpers
    methods (Access=private)

        function fitWindowToContentAspect(obj, targetRatio)
        %FITWINDOWTOCONTENTASPECT Resize figure so content area has target ratio.
        %
        %   targetRatio is height/width for the ImageAxes image area, excluding the
        %   calibrated top panel chrome. This is called after live resize settles,
        %   so it can correct the figure once without fighting the user's drag.

            if ~isfinite(targetRatio) || targetRatio <= 0
                return
            end

            figPos = obj.Fig.Position;
            figW = figPos(3);
            figH = figPos(4);

            if figW <= 0 || figH <= 0
                return
            end

            driver = obj.getResizeDriver(figPos, targetRatio);
            newPos = obj.getAspectFitFigurePosition(figPos, targetRatio, driver);

            % Avoid tiny resize loops from fractional-pixel math or platform chrome.
            if any(abs(newPos - figPos) > 0.5)
                obj.Fig.Position = newPos;
                obj.previousFigurePosition_ = obj.Fig.Position;
            else
                obj.previousFigurePosition_ = figPos;
            end
        end

        function driver = getResizeDriver(obj, figPos, targetRatio)
        %GETRESIZEDRIVER Decide whether width or height should drive reshaping.
        %
        %   During manual resize, use whichever figure dimension changed more since
        %   the last realized position. During startup or ambiguous changes, choose
        %   the dimension that fits the requested aspect inside the current figure.

            if isempty(obj.previousFigurePosition_) || numel(obj.previousFigurePosition_) < 4
                driver = obj.getAspectFitDriver(figPos, targetRatio);
                return
            end

            delta = figPos(3:4) - obj.previousFigurePosition_(3:4);

            if max(abs(delta)) <= 0.5
                driver = obj.getAspectFitDriver(figPos, targetRatio);
            elseif abs(delta(1)) >= abs(delta(2))
                driver = "width";
            else
                driver = "height";
            end
        end

        function driver = getAspectFitDriver(obj, figPos, targetRatio)
        %GETASPECTFITDRIVER Choose the non-growing fit for programmatic refreshes.
            panelTop = obj.uipanelTopChromePx_;
            contentH = max(1, figPos(4) - panelTop);
            currentRatio = contentH / figPos(3);

            if currentRatio > targetRatio
                driver = "width";
            else
                driver = "height";
            end
        end

        function newPos = getAspectFitFigurePosition(obj, figPos, targetRatio, driver)
        %GETASPECTFITFIGUREPOSITION Project figure size onto target content aspect.
            panelTop = obj.uipanelTopChromePx_;
            figW = max(1, figPos(3));
            figH = max(panelTop + 1, figPos(4));
            contentH = max(1, figH - panelTop);

            switch driver
                case "width"
                    newFigW = figW;
                    newFigH = figW * targetRatio + panelTop;
                case "height"
                    newFigH = figH;
                    newFigW = contentH / targetRatio;
            end

            newPos = figPos;
            newPos(3) = max(1, round(newFigW));
            newPos(4) = max(panelTop + 1, round(newFigH));
        end

        function scaleWindowSize(obj, factor)
        %SCALEWINDOWSIZE Incrementally resize the figure from keyboard shortcuts.

            if isempty(obj.Fig) || ~isvalid(obj.Fig) || ~strcmp(obj.Fig.WindowState, 'normal')
                return
            end

            if ~isfinite(factor) || factor <= 0
                return
            end

            if ~isempty(obj.ResizeSettleTimer) && isvalid(obj.ResizeSettleTimer)
                stop(obj.ResizeSettleTimer);
            end

            figPos = obj.Fig.Position;
            newPos = obj.getScaledFigurePosition(figPos, factor);
            newPos = obj.centerPositionOnPreviousPosition(newPos, figPos);

            if any(abs(newPos - figPos) > 0.5)
                obj.isResizingFigure = true;
                cleanupResizeFlag = onCleanup(@() obj.clearResizeGuard());
                obj.Fig.Position = newPos;
                obj.previousFigurePosition_ = obj.Fig.Position;
            end
        end

        function newPos = getScaledFigurePosition(obj, figPos, factor)
        %GETSCALEDFIGUREPOSITION Return an incrementally larger/smaller figure.

            newPos = figPos;
            newW = max(1, round(figPos(3) * factor));

            switch obj.WindowShape
                case 'tight'
                    if isempty(obj.Image)
                        newH = round(figPos(4) * factor);
                    else
                        targetRatio = obj.Image.SizeY / obj.Image.SizeX;
                        newH = round(newW * targetRatio + obj.uipanelTopChromePx_);
                    end
                case 'square'
                    newH = newW + obj.uipanelTopChromePx_;
                case 'normal'
                    newH = round(figPos(4) * factor);
            end

            newPos(3) = newW;
            newPos(4) = max(obj.uipanelTopChromePx_ + 1, newH);
        end

        function newPos = centerPositionOnPreviousPosition(~, newPos, oldPos)
        %CENTERPOSITIONONPREVIOUSPOSITION Keep the figure center fixed.
        %
        %   Used only for hotkey-initiated resizing. Live mouse resizing is allowed
        %   to follow the operating system's native edge/corner anchoring.

            centerX = oldPos(1) + oldPos(3)/2;
            centerY = oldPos(2) + oldPos(4)/2;

            newPos(1) = round(centerX - newPos(3)/2);
            newPos(2) = round(centerY - newPos(4)/2);
        end

    end

    %% Callbacks - hotkeys
    methods (Access=private)

        function increaseWindowSize(obj)
            obj.scaleWindowSize(obj.WindowSizeStep_);
        end

        function decreaseWindowSize(obj)
            obj.scaleWindowSize(1 / obj.WindowSizeStep_);
        end

    end

    %% Callbacks - Listeners
    methods (Access=private)

        function onFigureSizeChanged(obj)
        %ONFIGURESIZECHANGED Debounce user-driven figure resize events.

            if isempty(obj.Fig) || ~isvalid(obj.Fig)
                return
            end

            % Ignore SizeChangedFcn events caused by our own post-resize snap.
            if obj.isResizingFigure
                return
            end

            % Do not reshape while the window manager owns the figure state.
            if ~strcmp(obj.Fig.WindowState, 'normal')
                obj.previousFigurePosition_ = obj.Fig.Position;
                return
            end

            switch obj.WindowShape
                case 'normal'
                    obj.previousFigurePosition_ = obj.Fig.Position;
                    return
                otherwise
                    obj.armDeferredWindowFit();
            end
        end

        function onResizeSettled(obj)
        %ONRESIZESETTLED Apply tight/square fitting after resize events quiet down.
            if ~isvalid(obj)
                return
            end

            obj.refreshWindowSize();
        end

        function onFontSizeChanged(obj)
            obj.refreshCalibration();
            obj.refreshWindowSize();
        end

    end

    %% Callbacks - Menubar
    methods (Access=private)

        % --- File ---

        function onLoad(obj)
        %ONLOAD Menubar callback for [File]->[Load...]
            % hide figure, show file selection dialog, show figure
            obj.Fig.Visible = 'off';
            restoreVisibility = onCleanup(@() set(obj.Fig, "Visible", "on"));
            % update log
            matlabx.Log.DEBUG("Selecting image file...");

            try
                % get Image5D using file dialog
                I = matlabx.image.Image5D.fromFileDialog(...
                    "LoadOnCreate",true);
                if isempty(I)
                    matlabx.Log.DEBUG("Image file selection canceled.");
                    return
                end
                % set as image
                obj.Image = I;
            catch ME
                matlabx.Log.EXCEPTION(ME);
                obj.guialert("Title","Error","Message",ME.message,"Icon","error");
            end

            obj.refreshUI();
        end

        function onClose(obj)
        %ONCLOSE Menubar callback for [File]->[Close]    
            % no image -> return
            if isempty(obj.Image), return; end
            % --- delete project, detach listeners, refresh UI ---
            obj.Image.unload();
            obj.Image.delete();
            obj.Image = matlabx.app.Viewer5D.getDemoImage();
            obj.refreshUI();
        end


        % --- Window ---

        % WindowStyle
        function onWindowStyleMenuSelected(obj,src), obj.WindowStyle = src.Tag; end
        % WindowState
        function onWindowStateMenuSelected(obj,src), obj.WindowState = src.Tag; end
        % WindowShape
        function onWindowShapeMenuSelected(obj,src), obj.WindowShape = src.Tag; end

    end

    %% Other helpers
    methods (Access=private)

        function guialert(obj,opts)
            arguments
                obj (1,1) matlabx.app.Viewer5D
                opts.Message = ""
                opts.Title = "Untitled"
                opts.Icon (1,:) char {mustBeMember(opts.Icon,{'error','warning','info','message','success',''})} = ''
            end

            % give focus to figure
            figure(obj.Fig);
            % uialert dialog, closing will resume interaction on main window
            uialert(obj.Fig,...
                opts.Message,...
                opts.Title,...
                'Icon',opts.Icon,...
                'CloseFcn',@(o,e) uiresume(obj.Fig));
            % prevent interaction with the main window until we finish
            uiwait(obj.Fig);
        end

    end

    %% Static
    methods (Static)

        function Image = getDemoImage()
            I = imread("rice.png");
            Image = matlabx.image.Image5D.fromComponents({I});
        end

    end

end
