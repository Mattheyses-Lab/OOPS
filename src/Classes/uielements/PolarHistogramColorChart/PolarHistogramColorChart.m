classdef PolarHistogramColorChart < matlab.ui.componentcontainer.ComponentContainer
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

properties
    polarData = NaN
    nBins (1,1) double = 24
    wedgeColors (:,3) double = hsv(256)
    wedgeColorsRepeats (1,1) uint8 = 1
    wedgeLineColor (1,3) double = [0 0 0]
    wedgeFaceAlpha (1,1) double = 0.75
    wedgeLineWidth (1,1) double = 1
    wedgeEdgeColor (1,:) char {mustBeMember(wedgeEdgeColor,{'flat','interp'})} = 'flat'
    wedgeFaceColor (1,:) char {mustBeMember(wedgeFaceColor,{'flat','interp'})} = 'flat'
    rLimMode (1,:) char {mustBeMember(rLimMode,{'manual','Manual','auto','Auto'})} = 'auto'
    circleBackgroundColor (1,3) double = [1 1 1]
    circleColor (1,3) = [0 0 0]
    circleLineWidth (1,1) double = 2
    rGridlinesColor (1,3) double = [.9 .9 .9]
    rGridlinesLineWidth (1,1) double = 0.5
    thetaGridlinesColor (1,3) double = [.9 .9 .9]
    thetaLabelsColor (1,3) double = [0 0 0]
    thetaGridlinesLineWidth (1,1) double = 0.5
    Title (1,:) char = 'Untitled polar histogram'
end

properties(Dependent = true)
    rLim (1,1) double
    rSpacing (1,1) double
end

% properties hidden from the user, used for set/get methods for rLim
properties(Access = private)
    user_rLim
    obj_maxCounts = 1
end
    
properties(Access = private,Transient,NonCopyable)
    Grid (1,1) matlab.ui.container.GridLayout
    HistogramAxes (1,1) matlab.ui.control.UIAxes
    PolarAxesBG (1,1) matlab.graphics.primitive.Patch
    PolarAxesGridLines (1,1) matlab.graphics.primitive.Patch
    BinWedges (1,1) matlab.graphics.primitive.Patch
    ThetaGridLines (1,1) matlab.graphics.primitive.Line
    ThetaGridLinesLabels (:,1) matlab.graphics.primitive.Text
end

methods(Access = protected)
    function setup(obj)
        % grid layout manager to hold the components
        obj.Grid = uigridlayout(obj,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{'1x'},...
            "BackgroundColor",[1 1 1]);
        % uiaxes to hold our wedge patch objects
        obj.HistogramAxes = uiaxes(obj.Grid,...
            "XLim",[-obj.rLim obj.rLim],...
            "YLim",[-obj.rLim obj.rLim],...
            "XTick",[],...
            "YTick",[],...
            "XColor",[0 0 0],...
            "YColor",[0 0 0],...
            "Box","on");
        obj.HistogramAxes.Layout.Row = 1;
        obj.HistogramAxes.Layout.Column = 1;
        % set up a title for the axes
        obj.HistogramAxes.Title.String = obj.Title;
        obj.HistogramAxes.Title.Units = 'Normalized';
        obj.HistogramAxes.Title.HorizontalAlignment = 'Center';
        obj.HistogramAxes.Title.VerticalAlignment = 'Top';
        obj.HistogramAxes.Title.Color = [0 0 0];
        obj.HistogramAxes.Title.Position = [0.5,1.0,0];
        obj.HistogramAxes.Title.HitTest = 'Off';
        obj.HistogramAxes.Title.PickableParts = 'none';
        % patch object to form the BG of the polar axes
        obj.PolarAxesBG = patch(obj.HistogramAxes,'XData',NaN,'YData',NaN);
        obj.PolarAxesBG.HitTest = 'off';
        obj.PolarAxesBG.PickableParts = 'none';
        obj.PolarAxesBG.FaceColor = obj.BackgroundColor;
        % patch object to form the gridlines of the polar axes
        obj.PolarAxesGridLines = patch(obj.HistogramAxes,'XData',NaN,'YData',NaN);
        obj.PolarAxesGridLines.HitTest = 'off';
        obj.PolarAxesGridLines.PickableParts = 'none';
        obj.PolarAxesGridLines.FaceColor = 'none';
        % primitive line to form the major theta gridlines
        obj.ThetaGridLines = line(obj.HistogramAxes,'XData',NaN,'YData',NaN);
        % primitive text objects for theta gridline labels
        obj.ThetaGridLinesLabels = matlab.graphics.primitive.Text.empty();
        % patch object for the bin wedges (single patch for all the wedges)
        obj.BinWedges = patch(obj.HistogramAxes,'XData',NaN,'YData',NaN);
        % use normalized units for the component, stretched to fill the container
        obj.Units = 'Normalized';
        obj.Position = [0 0 1 1];
        % hide the cartesian axes holding our wedges
        obj.HistogramAxes.Visible = "off";
        % make sure axes X and YLims are equal so our histogram isn't distorted
        axis equal
    end

    function update(obj)
        % set the axis title
        obj.HistogramAxes.Title.String = obj.Title;
        obj.HistogramAxes.Title.Color = obj.thetaLabelsColor;
        obj.HistogramAxes.Title.Visible = 'on';
        % get the angle data to plot in the histogram
        angles = obj.polarData;

        if isempty(angles)
            obj.BinWedges.XData = [];
            obj.BinWedges.YData = [];
            return
        end

        % construct the bin edges 
        binEdges = linspace(0, 2*pi, obj.nBins+1);
        % Calculate the counts in each bin
        hist_counts = histcounts(angles, binEdges);
        hist_counts(end+1) = hist_counts(1);
        % store the maximum number of counts (for calculating automating axes size)
        obj.obj_maxCounts = max(hist_counts);
        % set the limits of the cartesian axes based on the rLim and plotBuffer
        rMax = obj.rLim;
        % plotBuffer = 0.15;
        % obj.HistogramAxes.XLim = [-rMax-rMax*plotBuffer rMax+rMax*plotBuffer];
        plotBuffer = rMax*0.15;
        obj.HistogramAxes.XLim = [-rMax-plotBuffer rMax+plotBuffer];

        obj.HistogramAxes.YLim = obj.HistogramAxes.XLim;
        % Define the center of the circle
        center = [0, 0];
        %% set the background color of the uigridlayout
        obj.Grid.BackgroundColor = obj.BackgroundColor;
        %% draw the circle that simulates the polar axes
        % the background of the polar axes
        circleResolution = 400;
        circleThetas = linspace(0,2*pi,circleResolution);
        obj.PolarAxesBG.XData = rMax*cos(circleThetas);
        obj.PolarAxesBG.YData = rMax*sin(circleThetas);
        obj.PolarAxesBG.FaceColor = 'flat';
        obj.PolarAxesBG.FaceVertexCData = obj.circleBackgroundColor;
        obj.PolarAxesBG.LineWidth = obj.circleLineWidth;
        obj.PolarAxesBG.EdgeColor = obj.circleColor;
        %% draw circles for the polar axes gridlines
        gridlineSpacing = obj.rSpacing;
        gridlineRadiis = gridlineSpacing:gridlineSpacing:(rMax-gridlineSpacing);
        numGridlines = numel(gridlineRadiis);
        % preallocate XData and YData for the gridline circle patch object
        gridlineXData = zeros(circleResolution,numGridlines);
        gridlineYData = zeros(circleResolution,numGridlines);
        % calculate XData and YData for each gridline circle
        for gridlineIdx = 1:numGridlines
            gridlineXData(:,gridlineIdx) = gridlineRadiis(gridlineIdx)*cos(circleThetas);
            gridlineYData(:,gridlineIdx) = gridlineRadiis(gridlineIdx)*sin(circleThetas);
        end
        % add the data to the gridline circle patch object
        obj.PolarAxesGridLines.XData = gridlineXData;
        obj.PolarAxesGridLines.YData = gridlineYData;
        % set some other patch properties
        obj.PolarAxesGridLines.FaceColor = "none";
        obj.PolarAxesGridLines.EdgeColor = obj.rGridlinesColor;
        obj.PolarAxesGridLines.LineWidth = obj.rGridlinesLineWidth;
        obj.PolarAxesGridLines.LineStyle = "-";

        %% draw lines for the major theta gridlines
        % calculate the angles at which we will draw the theta gridlines
        thetaSpacing = pi/6;
        thetaGridlineAngles = (0:thetaSpacing:2*pi-thetaSpacing).';
        % now calculate XData and YData for the theta gridlines
        XData = Interleave2DArrays(rMax.*cos(thetaGridlineAngles),-rMax.*cos(thetaGridlineAngles),'row');
        YData = Interleave2DArrays(rMax.*sin(thetaGridlineAngles),-rMax.*sin(thetaGridlineAngles),'row');
        % the number of theta lines we will be plotting
        nLines = numel(XData)/2;
        % preallocate new vectors where every two points (each pair corresponding to one line) will be split by a NaN
        spacedXData = zeros(numel(XData)+nLines,1);
        spacedYData = zeros(numel(XData)+nLines,1);
        % add NaN between each set of two rows in XData and YData, add a label for each line
        for lineIdx = 1:nLines
            newPointsIdx = [1,2,3]+3*(lineIdx-1);
            oldPointsIdx = [1,2]+2*(lineIdx-1);
            spacedXData(newPointsIdx,:) = [XData(oldPointsIdx,:); NaN];
            spacedYData(newPointsIdx,:) = [YData(oldPointsIdx,:); NaN];
        end
        % set the points, we need to use the set/get notation to avoid an error due to unequal array sizes
        set(obj.ThetaGridLines,'XData',spacedXData,'YData',spacedYData,'Color',obj.thetaGridlinesColor,'LineWidth',obj.thetaGridlinesLineWidth);

        %% draw labels for each of the theta gridlines
        % determine how many theta gridline labels to draw
        nThetaLabels = numel(thetaGridlineAngles);
        % delete old and then preallocate new text objects for our theta gridline labels
        delete(obj.ThetaGridLinesLabels);
        obj.ThetaGridLinesLabels = repmat(matlab.graphics.primitive.Text,nThetaLabels,1);
        % get the distance of each label from the center of the plot
        thetaLabelDist = rMax+plotBuffer*0.1;
        % draw a label for each unique theta (i.e. do not draw a label at 360°)
        for thetaIdx = 1:nThetaLabels
            stringLabel = [num2str(rad2deg(thetaGridlineAngles(thetaIdx))),'°'];
            xCoord = round(thetaLabelDist*cos(thetaGridlineAngles(thetaIdx)),4);
            yCoord = round(thetaLabelDist*sin(thetaGridlineAngles(thetaIdx)),4);

            if xCoord > 0 && yCoord > 0 % if in q1
                horizAlignment = 'left';
                vertAlignment = 'bottom';
            elseif xCoord < 0 && yCoord > 0 % if in q2
                horizAlignment = 'right';
                vertAlignment = 'bottom';
            elseif xCoord < 0 && yCoord < 0 % if in q3
                horizAlignment = 'right';
                vertAlignment = 'top';
            elseif xCoord > 0 && yCoord < 0 % if in q4
                horizAlignment = 'left';
                vertAlignment = 'top';
            elseif xCoord > 0 && yCoord == 0 % if on positive x-axis
                horizAlignment = 'left';
                vertAlignment = 'middle';
            elseif xCoord == 0 && yCoord > 0 % if on positive y-axis
                horizAlignment = 'center';
                vertAlignment = 'bottom';
            elseif xCoord < 0 && yCoord == 0 % if on negative x-axis
                horizAlignment = 'right';
                vertAlignment = 'middle';
            elseif xCoord == 0 && yCoord < 0 % if on negative y-axis
                horizAlignment = 'center';
                vertAlignment = 'top';
            end
            
            obj.ThetaGridLinesLabels(thetaIdx) = text(obj.HistogramAxes,...
                xCoord,...
                yCoord,...
                stringLabel,...
                "HorizontalAlignment",horizAlignment,...
                "VerticalAlignment",vertAlignment,...
                "Color",obj.thetaLabelsColor,...
                "FontWeight","normal");
        end
        %% now color the individual faces/edges
        % preallocate FaceVertexCData, XData, and YData for the bin wedge patch object
        wedgeFaceVertexCData = zeros(obj.nBins*3,3);
        wedgeXData = zeros(3,obj.nBins);
        wedgeYData = zeros(3,obj.nBins);
        % set the bin colors based on user-specified wedgeColors and wedgeColorsRepeats
        binColors = repmat(obj.wedgeColors,obj.wedgeColorsRepeats,1);
        % the number of colors in the input colormap
        nColors = size(binColors,1);
        % now calculate FaceVertexCData, XData, and YData for the wedges corresponding to each bin
        for binIdx = 1:obj.nBins
            % the radius of each wedge is set by the counts in the corresponding bin
            radius = hist_counts(binIdx);
            % Calculate the 3 vertices of the current wedge
            thetaEdge1 = binEdges(binIdx);
            thetaEdge2 = binEdges(binIdx+1);
            thetaMean = (thetaEdge1+thetaEdge2)/2;
            x1 = center(1) + radius*cos(thetaEdge1); y1 = center(2) + radius*sin(thetaEdge1);
            x2 = center(1) + radius*cos(thetaEdge2); y2 = center(2) + radius*sin(thetaEdge2);
            x3 = center(1); y3 = center(2);
            % set the FaceVertexCData according to wedgeColors and wedgeFaceColor (face color mode for the patch object)
            switch obj.wedgeFaceColor
                case 'flat' % each face is a single solid color
                    % get the color of this wedge
                    wedgeColorIdx = floor(((thetaMean/(2*pi))*nColors)+1);
                    wedgeColor = binColors(wedgeColorIdx,:);
                    wedgeVertexIdx = ([1;2;3])+3*(binIdx-1);
                    wedgeFaceVertexCData(wedgeVertexIdx,:) = repmat(wedgeColor,3,1);
                case 'interp' % face colors are interpolated between vertices
                    % the idx in wedgeFaceVertexCData to the 3 colors linked to the 3 vertices in this wedge
                    wedgeVertexIdx = ([1;2;3])+3*(binIdx-1);
                    % get the color of the central vertex in the middle of the bin range
                    centerColorIdx = floor(((thetaMean/(2*pi))*nColors)+1);
                    centerColorIdx = min(max(centerColorIdx,1),nColors);
                    centerColor = binColors(centerColorIdx,:);
                    % the color of the vertex at the lower limit of this bin range
                    wedgeColorIdx1 = floor(((thetaEdge1/(2*pi))*nColors)+1);
                    wedgeColorIdx1(wedgeColorIdx1<1) = nColors;
                    wedgeColorIdx1 = min(max(wedgeColorIdx1,1),nColors);
                    wedgeColor1 = binColors(wedgeColorIdx1,:);
                    % the color of the vertex at the upper limit of this bin range
                    wedgeColorIdx2 = floor(((thetaEdge2/(2*pi))*nColors)+1);
                    wedgeColorIdx2(wedgeColorIdx2>nColors) = 1;
                    wedgeColorIdx2 = min(max(wedgeColorIdx2,1),nColors);
                    wedgeColor2 = binColors(wedgeColorIdx2,:);
                    % add the 3 colors to our FaceVertexCData
                    wedgeFaceVertexCData(wedgeVertexIdx,:) = [wedgeColor1;wedgeColor2;centerColor];
            end
            % add the X and Y data for this wedge face
            wedgeXData(:,binIdx) = [x1;x2;x3];
            wedgeYData(:,binIdx) = [y1;y2;y3];
        end
        % set all the data we just calculated, along with user-defined settings for the wedge patches
        obj.BinWedges.XData = wedgeXData;
        obj.BinWedges.YData = wedgeYData;
        obj.BinWedges.FaceVertexCData = wedgeFaceVertexCData;
        obj.BinWedges.FaceColor = obj.wedgeFaceColor;
        obj.BinWedges.FaceAlpha = obj.wedgeFaceAlpha;
        obj.BinWedges.LineWidth = obj.wedgeLineWidth;        
        % set edge colors according to edge color mode
        switch obj.wedgeEdgeColor
            case 'flat' % single color for all the wedge edges
                obj.BinWedges.EdgeColor = obj.wedgeLineColor;
            case 'interp' % edge colors are interpolated between vertices to match the faces
                obj.BinWedges.EdgeColor = "interp";
        end
    end
end

methods

    function rLim = get.rLim(obj)
        switch obj.rLimMode
            case {'auto','Auto'}
                % determine the maximum number of bin counts
                maxCounts = obj.obj_maxCounts;
                % get the next highest power of 10
                tempLim = 10^(ceil(log10(maxCounts)));
                % get the power of 10 one degree lower than tempLim
                tempSpacing = tempLim/10;
                % create linearly spaced vector from 0 to tempLim+tempSpacing
                allSpacing = 0:tempSpacing:tempLim+tempSpacing;
                % remove all values less than or equal to maxCounts
                allSpacing(allSpacing<=maxCounts) = [];
                % then the next remaining number is our radius limit
                rLim = min(allSpacing);
                % i.e. if maxCounts is 6532, rLim will be 7000
            case {'manual','Manual'}
                rLim = obj.user_rLim;
        end
    end

    function set.rLim(obj,rLim)
        obj.user_rLim = rLim;
        obj.rLimMode = 'manual';
    end

    function rSpacing = get.rSpacing(obj)
        maxCounts = obj.obj_maxCounts;
        rSpacing = (10^(ceil(log10(maxCounts))-1));
        trueLim = obj.rLim;
        
        if numel(0:rSpacing:trueLim) > 7
            while numel(0:rSpacing:trueLim) > 7
                rSpacing = rSpacing*2;
            end
        elseif numel(0:rSpacing:trueLim) < 7
            while numel(0:rSpacing:trueLim) < 7
                rSpacing = rSpacing/2;
            end
        end

    end

end

end