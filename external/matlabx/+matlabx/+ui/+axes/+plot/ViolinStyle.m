classdef ViolinStyle
%VIOLINSTYLE Renderer-facing appearance for grouped violin/swarm content.
% The style is an inert value. It has no application persistence, callbacks,
% or knowledge of the model used to produce the plotted numeric data.
%
%   style = matlabx.ui.axes.plot.ViolinStyle( ...
%       Title="Distributions", YLabel="Value", ...
%       PointsVisible=true, ViolinOutlinesVisible=true, ...
%       CentralStatistic="median", ErrorStatistic="iqr", ...
%       DataTipFormat="%.3g");
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
        % PlotAxes and axes background color.
        BackgroundColor (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor,0,1)} = [1 1 1]
        % Ruler, label, title, and automatic edge color.
        ForegroundColor (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor,0,1)} = [0 0 0]
        % Colormap applied to scalar CData.
        Colormap (:,3) double {mustBeFinite,mustBeInRange(Colormap,0,1)} = parula(256)
        % Color limits applied to scalar CData.
        CLim (1,2) double {mustBeFinite,mustBeIncreasingLimits} = [0 1]
        % sprintf-style format applied to numeric point and summary values.
        DataTipFormat (1,1) string = "%.2f"
        % Scatter marker area in points squared.
        MarkerSize (1,1) double {mustBeFinite,mustBePositive} = 50
        % Marker edge line width.
        MarkerLineWidth (1,1) double {mustBeFinite,mustBePositive} = 0.5
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
        ViolinFaceColor (1,3) double {mustBeFinite,mustBeInRange(ViolinFaceColor,0,1)} = [1 1 1]
        % Whether violin edges use ViolinEdgeColor or the axes color order.
        ViolinEdgeColorMode (1,1) string {mustBeMember(ViolinEdgeColorMode,["Custom","auto"])} = "auto"
        % Custom violin edge color.
        ViolinEdgeColor (1,3) double {mustBeFinite,mustBeInRange(ViolinEdgeColor,0,1)} = [0 0 0]
        % Violin edge opacity.
        ViolinEdgeAlpha (1,1) double {mustBeFinite,mustBeInRange(ViolinEdgeAlpha,0,1)} = 1
        % Whether the central statistic and interval graphics are visible.
        ErrorBarsVisible (1,1) logical = true
        % Statistic shown by the central marker and middle bar.
        CentralStatistic (1,1) string {mustBeMember(CentralStatistic,["mean","median"])} = "mean"
        % Spread or interval represented by the outer error bars.
        ErrorStatistic (1,1) string {mustBeMember(ErrorStatistic,["std","sem","iqr"])} = "std"
        % Whether summary graphics use ErrorBarsColor or the axes color order.
        ErrorBarsColorMode (1,1) string {mustBeMember(ErrorBarsColorMode,["Custom","auto"])} = "Custom"
        % Custom central statistic and interval color.
        ErrorBarsColor (1,3) double {mustBeFinite,mustBeInRange(ErrorBarsColor,0,1)} = [0 0 0]
        % Central statistic and interval line width.
        ErrorBarsLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
        % Width of the independently interactive central-statistic line.
        CentralStatLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
    end

    methods

        function obj = ViolinStyle(opts)
        %VIOLINSTYLE Construct a style from optional renderer-facing values.

            arguments
                opts.?matlabx.ui.axes.plot.ViolinStyle
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
