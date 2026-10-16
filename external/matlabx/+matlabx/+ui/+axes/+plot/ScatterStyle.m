classdef ScatterStyle
%SCATTERSTYLE Renderer-facing appearance for a grouped scatter plot.
% This value class contains graphics presentation only. Application settings
% remain responsible for persistence, UI binding, and change notification.
%
%   style = matlabx.ui.axes.plot.ScatterStyle( ...
%       Title="Measurements", LegendVisible=true, ...
%       MarkerSize=36, HullVisible=true, DataTipFormat="%.3g");
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
        % PlotAxes and axes background color.
        BackgroundColor (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor,0,1)} = [1 1 1]
        % Ruler, label, title, and automatic edge color.
        ForegroundColor (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor,0,1)} = [0 0 0]
        % Colormap applied to scalar CData.
        Colormap (:,3) double {mustBeFinite,mustBeInRange(Colormap,0,1)} = parula(256)
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
        MarkerFaceAlpha (1,1) double {mustBeFinite,mustBeInRange(MarkerFaceAlpha,0,1)} = 1
        % Whether marker faces use CData, MarkerFaceColor, or the axes color order.
        MarkerFaceColorMode (1,1) string {mustBeMember(MarkerFaceColorMode,["CData","Custom","auto"])} = "CData"
        % Custom marker face color.
        MarkerFaceColor (1,3) double {mustBeFinite,mustBeInRange(MarkerFaceColor,0,1)} = [0 0.4470 0.7410]
        % Marker edge opacity.
        MarkerEdgeAlpha (1,1) double {mustBeFinite,mustBeInRange(MarkerEdgeAlpha,0,1)} = 1
        % Whether marker edges use CData, MarkerEdgeColor, or the axes color order.
        MarkerEdgeColorMode (1,1) string {mustBeMember(MarkerEdgeColorMode,["CData","Custom","auto"])} = "Custom"
        % Custom marker edge color.
        MarkerEdgeColor (1,3) double {mustBeFinite,mustBeInRange(MarkerEdgeColor,0,1)} = [0 0 0]
        % Whether to draw a hull around each scatter group.
        HullVisible (1,1) logical = false
        % Algorithm used to construct group hulls.
        HullType (1,1) string {mustBeMember(HullType,["concave","convex"])} = "concave"
        % Hull edge line width.
        HullLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
        % Hull face opacity.
        HullFaceAlpha (1,1) double {mustBeFinite,mustBeInRange(HullFaceAlpha,0,1)} = 0.5
        % Hull edge opacity.
        HullEdgeAlpha (1,1) double {mustBeFinite,mustBeInRange(HullEdgeAlpha,0,1)} = 1
        % Whether hull faces use HullFaceColor or the axes color order.
        HullFaceColorMode (1,1) string {mustBeMember(HullFaceColorMode,["Custom","auto"])} = "auto"
        % Custom hull face color.
        HullFaceColor (1,3) double {mustBeFinite,mustBeInRange(HullFaceColor,0,1)} = [1 1 1]
        % Whether hull edges use HullEdgeColor or the axes color order.
        HullEdgeColorMode (1,1) string {mustBeMember(HullEdgeColorMode,["Custom","auto"])} = "auto"
        % Custom hull edge color.
        HullEdgeColor (1,3) double {mustBeFinite,mustBeInRange(HullEdgeColor,0,1)} = [0 0 0]
    end

    methods

        function obj = ScatterStyle(opts)
        %SCATTERSTYLE Construct a style from optional renderer-facing values.

            arguments
                opts.?matlabx.ui.axes.plot.ScatterStyle
            end

            % Assign only values explicitly supplied by the caller.
            names = string(fieldnames(opts));

            for k = 1:numel(names)
                obj.(names(k)) = opts.(names(k));
            end
        end

    end

end

function mustBeIncreasingLimits(value)
%MUSTBEINCREASINGLIMITS Require a finite lower limit below the upper limit.

    if value(1) >= value(2)
        error('matlabx:ui:axes:plot:InvalidLimits', ...
            'CLim must contain an increasing lower and upper limit.');
    end
end
