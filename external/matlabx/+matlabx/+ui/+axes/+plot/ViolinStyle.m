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

classdef ViolinStyle
%VIOLINSTYLE Renderer-facing appearance for grouped violin/swarm content.
% The style is an inert value. It has no application persistence, callbacks,
% or knowledge of the model used to produce the plotted numeric data.

    properties
        Title (1,1) string = ""
        XLabel (1,1) string = "Group"
        YLabel (1,1) string = ""
        BackgroundColor (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor,0,1)} = [1 1 1]
        ForegroundColor (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor,0,1)} = [0 0 0]
        Colormap (:,3) double {mustBeFinite,mustBeInRange(Colormap,0,1)} = parula(256)
        CLim (1,2) double {mustBeFinite,mustBeIncreasingLimits} = [0 1]
        MarkerSize (1,1) double {mustBeFinite,mustBePositive} = 50
        MarkerFaceAlpha (1,1) double {mustBeFinite,mustBeInRange(MarkerFaceAlpha,0,1)} = 1
        MarkerEdgeColorMode (1,1) string {mustBeMember(MarkerEdgeColorMode,["Custom","auto"])} = "Custom"
        MarkerEdgeColor (1,3) double {mustBeFinite,mustBeInRange(MarkerEdgeColor,0,1)} = [0 0 0]
        XJitterWidth (1,1) double {mustBeFinite,mustBePositive,mustBeLessThanOrEqual(XJitterWidth,1)} = 0.6
        PointsVisible (1,1) logical = true
        ViolinOutlinesVisible (1,1) logical = true
        ViolinFaceColorMode (1,1) string {mustBeMember(ViolinFaceColorMode,["Custom","auto"])} = "auto"
        ViolinFaceColor (1,3) double {mustBeFinite,mustBeInRange(ViolinFaceColor,0,1)} = [1 1 1]
        ViolinEdgeColorMode (1,1) string {mustBeMember(ViolinEdgeColorMode,["Custom","auto"])} = "auto"
        ViolinEdgeColor (1,3) double {mustBeFinite,mustBeInRange(ViolinEdgeColor,0,1)} = [0 0 0]
        ErrorBarsVisible (1,1) logical = true
        ErrorBarsColorMode (1,1) string {mustBeMember(ErrorBarsColorMode,["Custom","auto"])} = "Custom"
        ErrorBarsColor (1,3) double {mustBeFinite,mustBeInRange(ErrorBarsColor,0,1)} = [0 0 0]
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
