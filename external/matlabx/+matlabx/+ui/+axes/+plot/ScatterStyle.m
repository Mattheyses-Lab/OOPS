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

classdef ScatterStyle
%SCATTERSTYLE Renderer-facing appearance for a grouped scatter plot.
% This value class contains graphics presentation only. Application settings
% remain responsible for persistence, UI binding, and change notification.

    properties
        Title (1,1) string = ""
        XLabel (1,1) string = ""
        YLabel (1,1) string = ""
        BackgroundColor (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor,0,1)} = [1 1 1]
        ForegroundColor (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor,0,1)} = [0 0 0]
        Colormap (:,3) double {mustBeFinite,mustBeInRange(Colormap,0,1)} = parula(256)
        CLim (1,2) double {mustBeFinite,mustBeIncreasingLimits} = [0 1]
        LegendVisible (1,1) logical = false
        MarkerSize (1,1) double {mustBeFinite,mustBePositive} = 50
        MarkerMode (1,1) string {mustBeMember(MarkerMode,["single","multi","auto"])} = "single"
        MarkerFaceAlpha (1,1) double {mustBeFinite,mustBeInRange(MarkerFaceAlpha,0,1)} = 1
        MarkerEdgeAlpha (1,1) double {mustBeFinite,mustBeInRange(MarkerEdgeAlpha,0,1)} = 1
        MarkerEdgeColorMode (1,1) string {mustBeMember(MarkerEdgeColorMode,["Custom","auto"])} = "Custom"
        MarkerEdgeColor (1,3) double {mustBeFinite,mustBeInRange(MarkerEdgeColor,0,1)} = [0 0 0]
        HullVisible (1,1) logical = false
        HullType (1,1) string {mustBeMember(HullType,["concave","convex"])} = "concave"
        HullLineWidth (1,1) double {mustBeFinite,mustBePositive} = 1
        HullFaceAlpha (1,1) double {mustBeFinite,mustBeInRange(HullFaceAlpha,0,1)} = 0.5
        HullEdgeAlpha (1,1) double {mustBeFinite,mustBeInRange(HullEdgeAlpha,0,1)} = 1
        HullFaceColorMode (1,1) string {mustBeMember(HullFaceColorMode,["Custom","auto"])} = "auto"
        HullFaceColor (1,3) double {mustBeFinite,mustBeInRange(HullFaceColor,0,1)} = [1 1 1]
        HullEdgeColorMode (1,1) string {mustBeMember(HullEdgeColorMode,["Custom","auto"])} = "auto"
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
