classdef ViolinStyle
%VIOLINSTYLE Renderer-facing appearance for grouped violin/swarm content.
% The style is an inert value. It has no application persistence, callbacks,
% or knowledge of the model used to produce the plotted numeric data.
%
%   style = matlabx.ui.axes.plot.ViolinStyle( ...
%       Title="Distributions", YLabel="Value", ...
%       PointsVisible=true, ViolinOutlinesVisible=true, ...
%       CentralStatistic="median", ErrorStatistic="iqr", ...
%       YLim=[0 10], DataTipFormat="%.3g");
%
% XLim and YLim are optional. Empty values select renderer-defined automatic
% limits; assigning a two-element limit makes the corresponding dependent
% XLimMode or YLimMode report "manual". Setting a mode to "auto" clears its
% stored limit and restores the renderer default.
%
% See also matlabx.ui.axes.plot.ViolinData,
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

    % Axes, points, violin, and summary presentation used by ViolinRenderer.
    properties
        % Axes title text.
        Title (1,1) string = ""
        % X-axis label text.
        XLabel (1,1) string = "Group"
        % Y-axis label text.
        YLabel (1,1) string = ""
        % Optional manual X limits; empty uses the renderer's group margins.
        XLim (1,:) double {mustBeOptionalIncreasingLimits} = double.empty(1,0)
        % Optional manual Y limits; empty uses MATLAB automatic limits.
        YLim (1,:) double {mustBeOptionalIncreasingLimits} = double.empty(1,0)
        % PlotAxes and axes background color.
        BackgroundColor (1,3) double {mustBeFinite,mustBeBetween(BackgroundColor,0,1)} = [1 1 1]
        % Ruler, label, title, and automatic edge color.
        ForegroundColor (1,3) double {mustBeFinite,mustBeBetween(ForegroundColor,0,1)} = [0 0 0]
        % Colormap applied to scalar CData.
        Colormap (:,3) double {mustBeFinite,mustBeBetween(Colormap,0,1)} = parula(256)
        % Color limits applied to scalar CData.
        CLim (1,2) double {mustBeFinite,mustBeIncreasingLimits} = [0 1]
        % sprintf-style format applied to numeric point and summary values.
        DataTipFormat (1,1) string = "%.2f"
        % Scatter marker area in points squared.
        MarkerSize (1,1) double {mustBeFinite,mustBePositive} = 50
        % Marker edge line width.
        MarkerLineWidth (1,1) double {mustBeFinite,mustBePositive} = 0.5
        % Marker face opacity.
        MarkerFaceAlpha (1,1) double {mustBeFinite,mustBeBetween(MarkerFaceAlpha,0,1)} = 1
        % Whether marker faces use CData, MarkerFaceColor, or the axes color order.
        MarkerFaceColorMode (1,1) string {mustBeMember(MarkerFaceColorMode,["CData","Custom","auto"])} = "CData"
        % Custom marker face color.
        MarkerFaceColor (1,3) double {mustBeFinite,mustBeBetween(MarkerFaceColor,0,1)} = [0 0.4470 0.7410]
        % Marker edge opacity.
        MarkerEdgeAlpha (1,1) double {mustBeFinite,mustBeBetween(MarkerEdgeAlpha,0,1)} = 1
        % Whether marker edges use CData, MarkerEdgeColor, or the axes color order.
        MarkerEdgeColorMode (1,1) string {mustBeMember(MarkerEdgeColorMode,["CData","Custom","auto"])} = "Custom"
        % Custom marker edge color.
        MarkerEdgeColor (1,3) double {mustBeFinite,mustBeBetween(MarkerEdgeColor,0,1)} = [0 0 0]
        % Horizontal density-jitter width relative to group spacing.
        XJitterWidth (1,1) double {mustBeFinite,mustBePositive,mustBeLessThanOrEqual(XJitterWidth,1)} = 0.6
        % Whether individual observations are visible.
        PointsVisible (1,1) logical = true
        % Whether violin density outlines are visible.
        ViolinOutlinesVisible (1,1) logical = true
        % Violin edge line width.
        ViolinLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
        % Whether violin faces use ViolinFaceColor or the axes color order.
        ViolinFaceColorMode (1,1) string {mustBeMember(ViolinFaceColorMode,["Custom","auto"])} = "auto"
        % Custom violin face color.
        ViolinFaceColor (1,3) double {mustBeFinite,mustBeBetween(ViolinFaceColor,0,1)} = [1 1 1]
        % Whether violin edges use ViolinEdgeColor or the axes color order.
        ViolinEdgeColorMode (1,1) string {mustBeMember(ViolinEdgeColorMode,["Custom","auto"])} = "auto"
        % Custom violin edge color.
        ViolinEdgeColor (1,3) double {mustBeFinite,mustBeBetween(ViolinEdgeColor,0,1)} = [0 0 0]
        % Violin edge opacity.
        ViolinEdgeAlpha (1,1) double {mustBeFinite,mustBeBetween(ViolinEdgeAlpha,0,1)} = 1
        % Whether the central statistic and interval graphics are visible.
        ErrorBarsVisible (1,1) logical = true
        % Statistic shown by the central marker and middle bar.
        CentralStatistic (1,1) string {mustBeMember(CentralStatistic,["mean","median"])} = "mean"
        % Spread or interval represented by the outer error bars.
        ErrorStatistic (1,1) string {mustBeMember(ErrorStatistic,["std","sem","iqr"])} = "std"
        % Whether summary graphics use ErrorBarsColor or the axes color order.
        ErrorBarsColorMode (1,1) string {mustBeMember(ErrorBarsColorMode,["Custom","auto"])} = "Custom"
        % Custom central statistic and interval color.
        ErrorBarsColor (1,3) double {mustBeFinite,mustBeBetween(ErrorBarsColor,0,1)} = [0 0 0]
        % Central statistic and interval line width.
        ErrorBarsLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
        % Width of the independently interactive central-statistic line.
        CentralStatLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
    end

    properties (Dependent)
        % Automatic when XLim is empty, otherwise manual.
        XLimMode (1,1) string
        % Automatic when YLim is empty, otherwise manual.
        YLimMode (1,1) string
    end

    methods

        function obj = ViolinStyle(opts)
        %VIOLINSTYLE Construct a style from optional renderer-facing values.

            arguments
                opts.?matlabx.ui.axes.plot.ViolinStyle
            end

            % Assign only values explicitly supplied by the caller. Modes are
            % applied last so an explicit Mode="auto" consistently clears a
            % simultaneously supplied limit, independent of argument order.
            names = string(fieldnames(opts));
            modes = names(ismember(names,["XLimMode","YLimMode"]));
            names = names(~ismember(names,modes));
            for k = 1:numel(names)
                obj.(names(k)) = opts.(names(k));
            end
            for k = 1:numel(modes)
                obj.(modes(k)) = opts.(modes(k));
            end
        end

        function mode = get.XLimMode(obj)
        %GET.XLIMMODE Return auto for empty limits and manual otherwise.
            mode = limitMode(obj.XLim);
        end

        function obj = set.XLimMode(obj,mode)
        %SET.XLIMMODE Clear limits for auto or validate existing manual limits.
            obj.XLim = applyLimitMode(obj.XLim,mode,"XLim");
        end

        function mode = get.YLimMode(obj)
        %GET.YLIMMODE Return auto for empty limits and manual otherwise.
            mode = limitMode(obj.YLim);
        end

        function obj = set.YLimMode(obj,mode)
        %SET.YLIMMODE Clear limits for auto or validate existing manual limits.
            obj.YLim = applyLimitMode(obj.YLim,mode,"YLim");
        end

    end

end

function mustBeOptionalIncreasingLimits(value)
%MUSTBEOPTIONALINCREASINGLIMITS Require empty or two increasing finite limits.
    if isempty(value)
        return
    end
    if ~isvector(value) || numel(value) ~= 2 || any(~isfinite(value)) || ...
            value(1) >= value(2)
        error('matlabx:ui:axes:plot:InvalidLimits', ...
            'Axes limits must be empty or contain two increasing finite values.');
    end
end

function mode = limitMode(value)
%LIMITMODE Derive the public mode from optional stored limits.
    if isempty(value)
        mode = "auto";
    else
        mode = "manual";
    end
end

function value = applyLimitMode(value,mode,propertyName)
%APPLYLIMITMODE Apply a mode without permitting contradictory style state.
    mode = string(mode);
    mustBeMember(mode,["auto","manual"]);
    if mode == "auto"
        value = double.empty(1,0);
    elseif isempty(value)
        error('matlabx:ui:axes:plot:MissingManualLimits', ...
            'Set %s before setting %sMode to "manual".', ...
            propertyName,propertyName);
    end
end

function mustBeIncreasingLimits(value)
%MUSTBEINCREASINGLIMITS Require a finite lower limit below the upper limit.

    if value(1) >= value(2)
        error('matlabx:ui:axes:plot:InvalidLimits', ...
            'CLim must contain an increasing lower and upper limit.');
    end
end
