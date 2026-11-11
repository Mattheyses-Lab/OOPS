classdef ScatterStyle
%SCATTERSTYLE Renderer-facing appearance for a grouped scatter plot.
% This value class contains graphics presentation only. Application settings
% remain responsible for persistence, UI binding, and change notification.
%
%   style = matlabx.ui.axes.plot.ScatterStyle( ...
%       Title="Measurements", LegendVisible=true, ...
%       MarkerSize=36, HullVisible=true, YLim=[0 10], ...
%       DataTipFormat="%.3g");
%
% XLim and YLim are optional. Empty values select MATLAB automatic limits;
% assigning a two-element limit makes the corresponding dependent XLimMode
% or YLimMode report "manual". Setting a mode to "auto" clears its limit.
%
% See also matlabx.ui.axes.plot.ScatterData,
% matlabx.ui.axes.plot.ScatterRenderer

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

    % Axes, marker, legend, and hull presentation used by ScatterRenderer.
    properties
        % Axes title text.
        Title (1,1) string = ""
        % X-axis label text.
        XLabel (1,1) string = ""
        % Y-axis label text.
        YLabel (1,1) string = ""
        % Optional manual X limits; empty uses MATLAB automatic limits.
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
        % sprintf-style format applied to numeric data-tip values.
        DataTipFormat (1,1) string = "%.2f"
        % Whether to display a series legend.
        LegendVisible (1,1) logical = false
        % Scatter marker area in points squared.
        MarkerSize (1,1) double {mustBeFinite,mustBePositive} = 50
        % Marker edge line width.
        MarkerLineWidth (1,1) double {mustBeFinite,mustBePositive} = 0.5
        % Whether groups share one marker or cycle through marker shapes.
        MarkerMode (1,1) string {mustBeMember(MarkerMode,["single","multi","auto"])} = "single"
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
        % Whether to draw a hull around each scatter group.
        HullVisible (1,1) logical = false
        % Algorithm used to construct group hulls.
        HullType (1,1) string {mustBeMember(HullType,["concave","convex"])} = "concave"
        % Hull edge line width.
        HullLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
        % Hull face opacity.
        HullFaceAlpha (1,1) double {mustBeFinite,mustBeBetween(HullFaceAlpha,0,1)} = 0.5
        % Hull edge opacity.
        HullEdgeAlpha (1,1) double {mustBeFinite,mustBeBetween(HullEdgeAlpha,0,1)} = 1
        % Whether hull faces use HullFaceColor or the axes color order.
        HullFaceColorMode (1,1) string {mustBeMember(HullFaceColorMode,["Custom","auto"])} = "auto"
        % Custom hull face color.
        HullFaceColor (1,3) double {mustBeFinite,mustBeBetween(HullFaceColor,0,1)} = [1 1 1]
        % Whether hull edges use HullEdgeColor or the axes color order.
        HullEdgeColorMode (1,1) string {mustBeMember(HullEdgeColorMode,["Custom","auto"])} = "auto"
        % Custom hull edge color.
        HullEdgeColor (1,3) double {mustBeFinite,mustBeBetween(HullEdgeColor,0,1)} = [0 0 0]
    end

    properties (Dependent)
        % Automatic when XLim is empty, otherwise manual.
        XLimMode (1,1) string
        % Automatic when YLim is empty, otherwise manual.
        YLimMode (1,1) string
    end

    methods

        function obj = ScatterStyle(opts)
        %SCATTERSTYLE Construct a style from optional renderer-facing values.

            arguments
                opts.?matlabx.ui.axes.plot.ScatterStyle
            end

            % Assign modes last so an explicit Mode="auto" clears a limit
            % supplied in the same constructor call.
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
            '%s cannot use manual mode until limits have been assigned.',propertyName);
    end
end

function mustBeIncreasingLimits(value)
%MUSTBEINCREASINGLIMITS Require a finite lower limit below the upper limit.

    if value(1) >= value(2)
        error('matlabx:ui:axes:plot:InvalidLimits', ...
            'CLim must contain an increasing lower and upper limit.');
    end
end
