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

classdef UICalibration < handle
%UICALIBRATION  Small per-machine UI calibration cache for uifigure UIs
%
% Typical use:
%   UIcal = matlabx.ui.calibration.UICalibration();
%   UIcal.calibrate();  % call once on startup (after UI created is fine)
%
% Query:
%   dH = UIcal.uipanelTopChromeHeightPx(14); % innerW - innerH for a square, titled uipanel
%   px = UIcal.pt2px(12);
%   pt = UIcal.px2pt(16);
%
% Notes:
%   In active development, plan to add more calibrations

    properties (SetAccess=private)
        % Core display scaling
        PixelsPerInch       (1,1) double = NaN
        PixelsPerPoint      (1,1) double = NaN  % PPI/72

        % Panel title/border overhead model:
        %   overheadPx ~ A * (FontSizePt * PixelsPerPoint) + B
        uipanelOverheadA      (1,1) double = NaN
        uipanelOverheadB      (1,1) double = NaN

        % Metadata / debug
        Timestamp           datetime = datetime.empty
        Notes               (1,:) char = ''

        % status flags
        uipanelCalibrated (1,1) logical = false
    end


    % uifigure calibration values
    properties (SetAccess=private)
        % Maximized uifigure geometry (px)
        uifigureMaximizedOuterPositionLeftPx   (1,1) double = NaN
        uifigureMaximizedOuterPositionBottomPx (1,1) double = NaN
        uifigureMaximizedOuterPositionWidthPx  (1,1) double = NaN
        uifigureMaximizedOuterPositionHeightPx (1,1) double = NaN
    
        uifigureMaximizedPositionLeftPx        (1,1) double = NaN
        uifigureMaximizedPositionBottomPx      (1,1) double = NaN
        uifigureMaximizedPositionWidthPx       (1,1) double = NaN
        uifigureMaximizedPositionHeightPx      (1,1) double = NaN
    
        uifigureMaximizedInnerPositionLeftPx   (1,1) double = NaN
        uifigureMaximizedInnerPositionBottomPx (1,1) double = NaN
        uifigureMaximizedInnerPositionWidthPx  (1,1) double = NaN
        uifigureMaximizedInnerPositionHeightPx (1,1) double = NaN
    
        % Derived geometry
        uifigureMaximizedTopChromeHeightPx      (1,1) double = NaN
    
        % Status
        uifigureCalibrated (1,1) logical = false
    end

    %% Constructor
    methods
        function obj = UICalibration()
            obj.Timestamp = datetime('now');
            obj.PixelsPerInch = get(groot, 'ScreenPixelsPerInch');
            obj.PixelsPerPoint = obj.PixelsPerInch / 72;
        end
    end

    %% Main calibration driver
    methods

        function calibrate(obj,opts)
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
                opts.uipanel  (1,1) logical = true
                opts.uifigure (1,1) logical = true
            end

            % Create a uifigure to hide calibrations happening in background windows
            f = uifigure(...
                'Units','normalized', ...
                'OuterPosition',[0 0 1 1], ...
                'Visible','on', ...
                'WindowStyle','alwaysontop');
            drawnow
            pause(1)
            % progress bar
            h = uiprogressdlg(f,"Cancelable","off",...
                "Indeterminate","on",...
                "Title","Running UI Calibration",...
                "Message","Running UI calibration. Please wait...");

            % --- uipanel ---
            if opts.uipanel
                try
                    obj.calibrate_uipanel();
                catch ME
                    matlabx.Log.ERROR(ME,"Source","UICalibration");
                    rethrow(ME)
                end
            end

            % --- uifigure ---
            if opts.uifigure
                try
                    obj.calibrate_uifigure();
                catch ME
                    matlabx.Log.ERROR(ME,"Source","UICalibration");
                end
            end

            close(h);
            delete(f);

        end

    end

    %% General helpers
    methods

        function px = pt2px(obj, pt)
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
                pt (:,1) double
            end
            px = pt * obj.PixelsPerPoint;
        end

        function pt = px2pt(obj, px)
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
                px (:,1) double
            end
            pt = px / obj.PixelsPerPoint;
        end

    end

    %% Individual calibrations
    methods
        function calibrate_uipanel(obj, opts)
            %CALIBRATE_UIPANEL Calibrate uipanel to estimate title bar height
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
                opts.FontName (1,:) char = ''     % '' = default UI font
                opts.FontSizes (1,:) double = [8 10 12 14 16 18]  % px
            end
            % log
            matlabx.Log.INFO("Calibrating uipanel...","Source","UICalibration");

            % Create a uifigure to measure platform-specific chrome
            f = uifigure('Position',[100 100 200 200],...
                'Visible','on',...
                'AutoResizeChildren','off');
            movegui(f,"center");

            % drawnow
            % pause(1)


            % cleanup upon function completion
            c = onCleanup(@() delete(f));

            % Create a test panel, measure overhead for several FontSizes
            n = numel(opts.FontSizes);
            x = zeros(n,1); % predictor: text height in px (approx)
            y = zeros(n,1); % response: overhead px (innerW - innerH)
            for i = 1:n
                fs = opts.FontSizes(i);

                p = uipanel(f, ...
                    'Title', 'Calibration', ...
                    'FontSize', fs, ...
                    'FontUnits', 'pixels', ...
                    'OuterPosition', [20 20 100 100], ...
                    'BorderWidth', 0);
                if ~isempty(opts.FontName)
                    p.FontName = opts.FontName;
                end

                drawnow; % ensure InnerPosition is valid
                pause(2) % pause to draw

                % get offset caused by title bar
                y(i) = p.InnerPosition(3) - p.InnerPosition(4);
                x(i) = fs;

                fsPts = obj.px2pt(fs); % px -> pt

                % debugMsg = sprintf("FontSizePts: %d | FontSizePx: %d | uipanelOverheadPx: %d",fs,x(i),y(i));
                debugMsg = sprintf("FontSizePts: %d | FontSizePx: %d | uipanelOverheadPx: %d",fsPts,x(i),y(i));
                matlabx.Log.INFO(debugMsg,"Source","UICalibration")

                delete(p);
            end

            % Fit y ~ A*x + B. Use polyfit when n>=2.
            if n >= 2
                cfit = polyfit(x, y, 1);
                obj.uipanelOverheadA = cfit(1);
                obj.uipanelOverheadB = cfit(2);
            else
                % Fallback: assume overhead = x + constant padding
                obj.uipanelOverheadA = 1;
                obj.uipanelOverheadB = max(0, y(1) - x(1));
            end

            % update log and status
            obj.uipanelCalibrated = true;
            matlabx.Log.INFO("uipanel calibration completed successfully.","Source","UICalibration");
        end

        function calibrate_uifigure(obj)
            %CALIBRATE_UIFIGURE Measure platform-specific uifigure chrome and usable area.
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
            end
        
            matlabx.Log.INFO("Calibrating uifigure...", "Source", "UICalibration");
        
            f = uifigure( ...
                'Visible', 'on', ...
                'WindowState','maximized',...
                'Units','pixels');

            % Let layout settle
            drawnow;
            pause(1);
        
            % Measure maximized state in pixel units
            obj.uifigureMaximizedOuterPositionLeftPx   = f.OuterPosition(1);
            obj.uifigureMaximizedOuterPositionBottomPx = f.OuterPosition(2);
            obj.uifigureMaximizedOuterPositionWidthPx  = f.OuterPosition(3);
            obj.uifigureMaximizedOuterPositionHeightPx = f.OuterPosition(4);
        
            obj.uifigureMaximizedPositionLeftPx        = f.Position(1);
            obj.uifigureMaximizedPositionBottomPx      = f.Position(2);
            obj.uifigureMaximizedPositionWidthPx       = f.Position(3);
            obj.uifigureMaximizedPositionHeightPx      = f.Position(4);
        
            obj.uifigureMaximizedInnerPositionLeftPx   = f.InnerPosition(1);
            obj.uifigureMaximizedInnerPositionBottomPx = f.InnerPosition(2);
            obj.uifigureMaximizedInnerPositionWidthPx  = f.InnerPosition(3);
            obj.uifigureMaximizedInnerPositionHeightPx = f.InnerPosition(4);
        
            obj.uifigureMaximizedTopChromeHeightPx = ...
                obj.uifigureMaximizedOuterPositionHeightPx - ...
                obj.uifigureMaximizedInnerPositionHeightPx;

            delete(f);
        
            obj.uifigureCalibrated = true;
        
            matlabx.Log.INFO("uifigure calibration completed successfully.", "Source", "UICalibration");
        end




    end

    %% Getters for calibrated uipanel values
    methods

        function topChromePx = uipanelTopChromeHeightPx(obj, fontSize, opts)
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
                fontSize (1,1) double
                opts.FontUnits (1,:) char {mustBeMember(opts.FontUnits,{'pixels','points'})} = 'pixels'
            end
        
            if ~obj.uipanelCalibrated
                error('UICalibration:NotCalibrated', ...
                    'uipanel calibration has not been run.');
            end

            switch opts.FontUnits
                case 'points'
                    fontSizePx = obj.pt2px(fontSize);
                case 'pixels'
                    fontSizePx = fontSize;
            end
        
            %fontSizePx = obj.pt2px(fontSize);
            topChromePx = obj.uipanelOverheadA * fontSizePx + obj.uipanelOverheadB;
            topChromePx = round(topChromePx);
            topChromePx = max(0, topChromePx);
        end

    end

    %% Getters for calibrated uifigure values
    methods

        function pos = uifigureMaximizedOuterPositionPx(obj)
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
            end
            if ~obj.uifigureCalibrated
                error('UICalibration:NotCalibrated', 'uifigure calibration has not been run.');
            end
            pos = [ ...
                obj.uifigureMaximizedOuterPositionLeftPx ...
                obj.uifigureMaximizedOuterPositionBottomPx ...
                obj.uifigureMaximizedOuterPositionWidthPx ...
                obj.uifigureMaximizedOuterPositionHeightPx];
        end
        
        function pos = uifigureMaximizedPositionPx(obj)
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
            end
            if ~obj.uifigureCalibrated
                error('UICalibration:NotCalibrated', 'uifigure calibration has not been run.');
            end
            pos = [ ...
                obj.uifigureMaximizedPositionLeftPx ...
                obj.uifigureMaximizedPositionBottomPx ...
                obj.uifigureMaximizedPositionWidthPx ...
                obj.uifigureMaximizedPositionHeightPx];
        end
        
        function pos = uifigureMaximizedInnerPositionPx(obj)
            arguments
                obj (1,1) matlabx.ui.calibration.UICalibration
            end
            if ~obj.uifigureCalibrated
                error('UICalibration:NotCalibrated', 'uifigure calibration has not been run.');
            end
            pos = [ ...
                obj.uifigureMaximizedInnerPositionLeftPx ...
                obj.uifigureMaximizedInnerPositionBottomPx ...
                obj.uifigureMaximizedInnerPositionWidthPx ...
                obj.uifigureMaximizedInnerPositionHeightPx];
        end

    end




    %% Serialization helpers
    methods

        function S = toStruct(obj)
            S = struct();

            % schema / metadata
            S.SchemaVersion = 1;
            S.Timestamp = char(obj.Timestamp);

            S.Environment = struct( ...
                'Computer', computer, ...
                'MATLABVersion', version, ...
                'PixelsPerInch', obj.PixelsPerInch, ...
                'ScreenSize', get(groot, 'ScreenSize'), ...
                'MonitorPositions', get(groot, 'MonitorPositions'));

            % core scaling
            S.PixelsPerInch = obj.PixelsPerInch;
            S.PixelsPerPoint = obj.PixelsPerPoint;

            % % uipanel
            % S.uipanelOverheadA = obj.uipanelOverheadA;
            % S.uipanelOverheadB = obj.uipanelOverheadB;

            % status / notes
            S.uipanelCalibrated = obj.uipanelCalibrated;
            S.uifigureCalibrated = obj.uifigureCalibrated;
            S.Notes = obj.Notes;

            % uifigure geometry
            fields = matlabx.ui.calibration.UICalibration.serializedFieldNames_();
            for i = 1:numel(fields)
                f = fields{i};
                S.(f) = obj.(f);
            end
        end

    end

    methods (Static)
        function obj = fromStruct(S)
            if ~isstruct(S)
                error('UICalibration:InvalidStruct', ...
                    'Input must be a struct.');
            end
    
            obj = matlabx.ui.calibration.UICalibration();
    
            if isfield(S,'Timestamp') && ~isempty(S.Timestamp)
                try
                    obj.Timestamp = datetime(S.Timestamp);
                catch
                    % leave constructor default if parse fails
                end
            end
    
            obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, 'PixelsPerInch');
            obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, 'PixelsPerPoint');
            % obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, 'uipanelOverheadA');
            % obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, 'uipanelOverheadB');
            obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, 'uipanelCalibrated');
            obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, 'uifigureCalibrated');
            obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, 'Notes');
    
            fields = matlabx.ui.calibration.UICalibration.serializedFieldNames_();
            for i = 1:numel(fields)
                obj = matlabx.ui.calibration.UICalibration.assignIfField_(obj, S, fields{i});
            end
    
            % fallback for older cache files that may not store PixelsPerPoint
            if ~isfield(S,'PixelsPerPoint') && ~isnan(obj.PixelsPerInch)
                obj.PixelsPerPoint = obj.PixelsPerInch / 72;
            end
        end
    end

    %% Validity check
    methods (Static)
        function tf = isStructValid(S)
            tf = false;
    
            if ~isstruct(S), return; end
    
            required = {...
                'PixelsPerInch',...
                'PixelsPerPoint',...
                'uipanelCalibrated',...
                'uifigureCalibrated'};
            % tf = all(isfield(S, required));

            if ~all(isfield(S, required)), return; end
    
            if ~isfield(S, 'Environment'), return; end
    
            env = S.Environment;
    
            if ~isfield(env, 'Computer') || ~strcmp(env.Computer, computer), return; end
    
            if ~isfield(env, 'MATLABVersion') || ~strcmp(env.MATLABVersion, version), return; end
    
            currentPPI = get(groot, 'ScreenPixelsPerInch');
            if ~isfield(env, 'PixelsPerInch') || env.PixelsPerInch ~= currentPPI
                return
            end

            if isfield(env, 'ScreenSize') ...
                    && ~sameNumericArray_(env.ScreenSize, get(groot, 'ScreenSize'))
                return
            end

            if isfield(env, 'MonitorPositions') ...
                    && ~sameNumericArray_(env.MonitorPositions, get(groot, 'MonitorPositions'))
                return
            end

            if S.uifigureCalibrated ...
                    && ~hasSaneUifigureGeometry_(S)
                return
            end

            tf = true;
        end
    end

    methods (Static, Access=private)
        function obj = assignIfField_(obj, S, name)
            if isfield(S, name)
                obj.(name) = S.(name);
            end
        end
    
        function fields = serializedFieldNames_()
            % fields = { ...
            %     'uipanelOverheadA'
            %     'uipanelOverheadB'
            %     'uifigureMaximizedOuterPositionLeftPx'
            %     'uifigureMaximizedOuterPositionBottomPx'
            %     'uifigureMaximizedOuterPositionWidthPx'
            %     'uifigureMaximizedOuterPositionHeightPx'
            %     'uifigureMaximizedPositionLeftPx'
            %     'uifigureMaximizedPositionBottomPx'
            %     'uifigureMaximizedPositionWidthPx'
            %     'uifigureMaximizedPositionHeightPx'
            %     'uifigureMaximizedInnerPositionLeftPx'
            %     'uifigureMaximizedInnerPositionBottomPx'
            %     'uifigureMaximizedInnerPositionWidthPx'
            %     'uifigureMaximizedInnerPositionHeightPx'
            %     'uifigureMaximizedTopChromeHeightPx'
            %     'uifigureFullscreenOuterPositionLeftPx'
            %     'uifigureFullscreenOuterPositionBottomPx'
            %     'uifigureFullscreenOuterPositionWidthPx'
            %     'uifigureFullscreenOuterPositionHeightPx'
            %     'uifigureFullscreenPositionLeftPx'
            %     'uifigureFullscreenPositionBottomPx'
            %     'uifigureFullscreenPositionWidthPx'
            %     'uifigureFullscreenPositionHeightPx'
            %     'uifigureFullscreenInnerPositionLeftPx'
            %     'uifigureFullscreenInnerPositionBottomPx'
            %     'uifigureFullscreenInnerPositionWidthPx'
            %     'uifigureFullscreenInnerPositionHeightPx'
            %     'uifigureFullscreenTopChromeHeightPx'
            %     };

            fields = { ...
                'uipanelOverheadA'
                'uipanelOverheadB'
                'uifigureMaximizedOuterPositionLeftPx'
                'uifigureMaximizedOuterPositionBottomPx'
                'uifigureMaximizedOuterPositionWidthPx'
                'uifigureMaximizedOuterPositionHeightPx'
                'uifigureMaximizedPositionLeftPx'
                'uifigureMaximizedPositionBottomPx'
                'uifigureMaximizedPositionWidthPx'
                'uifigureMaximizedPositionHeightPx'
                'uifigureMaximizedInnerPositionLeftPx'
                'uifigureMaximizedInnerPositionBottomPx'
                'uifigureMaximizedInnerPositionWidthPx'
                'uifigureMaximizedInnerPositionHeightPx'
                'uifigureMaximizedTopChromeHeightPx'
                };

        end
    end


end

function tf = sameNumericArray_(A, B)
if numel(A) ~= numel(B)
    tf = false;
    return
end

if isvector(A) && isvector(B)
    tf = all(abs(double(A(:)) - double(B(:))) <= 1);
    return
end

tf = isequal(size(A), size(B)) && all(abs(double(A(:)) - double(B(:))) <= 1);
end

function tf = hasSaneUifigureGeometry_(S)
tf = false;

required = { ...
    'uifigureMaximizedOuterPositionLeftPx'
    'uifigureMaximizedOuterPositionBottomPx'
    'uifigureMaximizedOuterPositionWidthPx'
    'uifigureMaximizedOuterPositionHeightPx'
    'uifigureMaximizedPositionWidthPx'
    'uifigureMaximizedPositionHeightPx'
    'uifigureMaximizedInnerPositionWidthPx'
    'uifigureMaximizedInnerPositionHeightPx'};

if ~all(isfield(S, required)), return; end

outerPos = [ ...
    S.uifigureMaximizedOuterPositionLeftPx ...
    S.uifigureMaximizedOuterPositionBottomPx ...
    S.uifigureMaximizedOuterPositionWidthPx ...
    S.uifigureMaximizedOuterPositionHeightPx];

posSize = [ ...
    S.uifigureMaximizedPositionWidthPx ...
    S.uifigureMaximizedPositionHeightPx];

innerSize = [ ...
    S.uifigureMaximizedInnerPositionWidthPx ...
    S.uifigureMaximizedInnerPositionHeightPx];

vals = [outerPos posSize innerSize];
if any(~isfinite(vals)) || any(vals(3:end) <= 0), return; end

monitors = get(groot, 'MonitorPositions');
if isempty(monitors) || size(monitors, 2) ~= 4, return; end

tolerancePx = 32;
monitorWidth = monitors(:,3);
monitorHeight = monitors(:,4);

if outerPos(3) > max(monitorWidth) + tolerancePx, return; end
if outerPos(4) > max(monitorHeight) + tolerancePx, return; end

outerLeft = outerPos(1);
outerBottom = outerPos(2);
outerRight = outerLeft + outerPos(3);
outerTop = outerBottom + outerPos(4);

monitorLeft = monitors(:,1);
monitorBottom = monitors(:,2);
monitorRight = monitorLeft + monitorWidth;
monitorTop = monitorBottom + monitorHeight;

fitsMonitor = ...
    outerLeft >= monitorLeft - tolerancePx & ...
    outerBottom >= monitorBottom - tolerancePx & ...
    outerRight <= monitorRight + tolerancePx & ...
    outerTop <= monitorTop + tolerancePx;

if ~any(fitsMonitor), return; end

if posSize(1) > outerPos(3) + tolerancePx, return; end
if posSize(2) > outerPos(4) + tolerancePx, return; end
if innerSize(1) > outerPos(3) + tolerancePx, return; end
if innerSize(2) > outerPos(4) + tolerancePx, return; end

tf = true;
end
