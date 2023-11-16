function UpdateIntensityLineScan(source)
%
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

    % main data structure
    OOPSData = guidata(source);
    % current image(s) selection
    cImage = OOPSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % update the display according to the first image in the list
        cImage = cImage(1);
    else
        return
    end

    % get the image
    I = cImage.ffcFPMAverage;

    % position of the central axis of the line scan ROI
    ScanLinePosition = OOPSData.Handles.LineScanROI.Position;
    % width of the rectangular scan area (in pixels)
    scanwidth = 9;

    % distance (in pixels) on either side of the user-defined line
    nlinesperside = scanwidth/2;

    % coordinates of the line scan ROI, at the center of the rectangular scan area
    x1 = ScanLinePosition(1,1);y1 = ScanLinePosition(1,2);
    x2 = ScanLinePosition(2,1);y2 = ScanLinePosition(2,2);

    % coordinates of a line at the "left" edge of the scan
    [xleft1,xleft2,yleft1,yleft2] = ParallelTranslation(x1,x2,y1,y2,-nlinesperside);

    % cell array of all the lines in the scan
    ParallelLines = MultiParallelTranslation(xleft1,xleft2,yleft1,yleft2,scanwidth);

    % coordinates of a line at the "right" edge of the scan
    rightLine = ParallelLines{end};
    xright1 = rightLine(1,1);yright1 = rightLine(1,2);
    xright2 = rightLine(2,1);yright2 = rightLine(2,2);

%% create or update the rectangular patch representing the scan area

    % X and YData for line scan rectangle
    rectangleXData = [xleft1,xleft2,xright2,xright1];
    rectangleYData = [yleft1,yleft2,yright2,yright1];
    % line scan rectangle already exists
    if isvalid(OOPSData.Handles.LineScanRectangle) && isa(OOPSData.Handles.LineScanRectangle,'matlab.graphics.primitive.Patch')
        set(OOPSData.Handles.LineScanRectangle,...
            'XData',rectangleXData,...
            'YData',rectangleYData);
    else
        % plot a semi-transparent rectangle showing the scan area
        OOPSData.Handles.LineScanRectangle = patch(OOPSData.Handles.AverageIntensityAxH,...
            'XData',rectangleXData,...
            'YData',rectangleYData,...
            'FaceColor','yellow',...
            'EdgeColor','none',...
            'FaceAlpha',0.5,...
            'HitTest','off',...
            'PickableParts','none');
    end

%% compute the 2D line scan

    % number of line scan lines in the rectangular scan area
    nLines = numel(ParallelLines);
    % pixel size of the image in microns
    umPerPixel = cImage.rawFPMPixelSize;
    % length of the line in pixels
    pxDist = sqrt((y2-y1)^2+(x2-x1)^2);
    % length of the line in microns
    umDist = pxDist*umPerPixel;
    % 100 points per micron
    nPoints = round((umDist*100));
    % XData of the line scan plot
    umXData = linspace(0,umDist,nPoints);
    % preallocate cell array of YData for the line scan plot
    LineScanYData = cell(nLines,1);
    LineScanYData{1} = zeros(1,nPoints);

    % compute line scan for each line in a parallel loop
    parfor i = 1:nLines
        LineScanYData{i} = improfile(I,ParallelLines{i}(:,1),ParallelLines{i}(:,2),nPoints,'bilinear')';
    end

    IntegratedLineScan = sum(cell2mat(LineScanYData(1:nLines)),1);

%% plot the linescan

    plot(OOPSData.Handles.LineScanAxes,umXData,Scale0To1(IntegratedLineScan),'Color',[0 1 0],'LineWidth',2);

    drawnow nocallbacks

end