% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef PolarHistogramRenderer < matlabx.ui.axes.PlotContent
%POLARHISTOGRAMRENDERER Render one transferable Cartesian polar histogram.

    properties (SetAccess=private)
        Data (1,1) oops.plot.PolarHistogramData = oops.plot.PolarHistogramData()
        Style (1,1) oops.plot.PolarHistogramStyle = oops.plot.PolarHistogramStyle()
    end

    properties (Access=private)
        Plot (:,1) oops.plot.PolarHistogram = oops.plot.PolarHistogram.empty(0,1)
    end

    methods
        function update(obj,data,style)
        %UPDATE Store normalized data and style, then perform one refresh.
            obj.Data = data;
            obj.Style = style;
            obj.refresh();
        end

        function refresh(obj)
        %REFRESH Apply stored data and style to the current host axes.
            if isempty(obj.Host), return; end

            if isempty(obj.Plot) || ~isvalid(obj.Plot)
                obj.Plot = oops.plot.PolarHistogram(obj.Host.Axes);
            else
                obj.Plot.setParent(obj.Host.Axes);
            end

            obj.Host.BackgroundColor = obj.Style.BackgroundColor;
            obj.Host.ForegroundColor = obj.Style.LabelsColor;
            obj.Plot.render(obj.Data,obj.Style);
        end

        function delete(obj)
        %DELETE Release renderer-owned graphics.
            obj.detach();
            delete(obj.Plot);
        end
    end

    methods (Access=protected)
        function attachGraphics(obj,axes)
        %ATTACHGRAPHICS Move the existing primitive collection to its new host.
            if ~isempty(obj.Plot) && isvalid(obj.Plot), obj.Plot.setParent(axes); end
        end

        function hideGraphics(obj)
        %HIDEGRAPHICS Hide the primitive collection while detached.
            if ~isempty(obj.Plot) && isvalid(obj.Plot), obj.Plot.setVisible(false); end
        end
    end
end
