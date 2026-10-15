% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef PolarHistogramStyle
%POLARHISTOGRAMSTYLE Renderer-facing polar-histogram appearance.

    properties
        Title (1,1) string = ""
        BinCount (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 24
        Colormap (:,3) double {mustBeFinite,mustBeInRange(Colormap,0,1)} = hsv(256)
        WedgeFaceAlpha (1,1) double {mustBeFinite,mustBeInRange(WedgeFaceAlpha,0,1)} = .75
        WedgeFaceColorMode (1,1) string {mustBeMember(WedgeFaceColorMode,["flat","interp"])} = "flat"
        WedgeEdgeColorMode (1,1) string {mustBeMember(WedgeEdgeColorMode,["flat","interp"])} = "flat"
        WedgeEdgeColor (1,3) double {mustBeFinite,mustBeInRange(WedgeEdgeColor,0,1)} = [0 0 0]
        WedgeLineWidth (1,1) double {mustBeFinite,mustBeNonnegative} = 1
        GridlinesColor (1,3) double {mustBeFinite,mustBeInRange(GridlinesColor,0,1)} = [.9 .9 .9]
        LabelsColor (1,3) double {mustBeFinite,mustBeInRange(LabelsColor,0,1)} = [0 0 0]
        GridlinesLineWidth (1,1) double {mustBeFinite,mustBeNonnegative} = .5
        CircleBackgroundColor (1,3) double {mustBeFinite,mustBeInRange(CircleBackgroundColor,0,1)} = [1 1 1]
        CircleColor (1,3) double {mustBeFinite,mustBeInRange(CircleColor,0,1)} = [0 0 0]
        CircleLineWidth (1,1) double {mustBeFinite,mustBeNonnegative} = 2
        BackgroundColor (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor,0,1)} = [1 1 1]
    end

    methods
        function obj = PolarHistogramStyle(opts)
        %POLARHISTOGRAMSTYLE Apply renderer-facing values supplied by caller.
            arguments
                opts.?oops.plot.PolarHistogramStyle
            end

            names = string(fieldnames(opts));
            for k = 1:numel(names), obj.(names(k)) = opts.(names(k)); end
        end
    end
end
