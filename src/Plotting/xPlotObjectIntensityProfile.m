function xPlotObjectIntensityProfile(source,~)
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

OOPSData = guidata(source);
Object = OOPSData.CurrentObject;

if isempty(Object)
    uialert(OOPSData.Handles.fH,'No object found','Error')
    return
end

%% gather settings

AnnotationsColor = OOPSData.Settings.ObjectIntensityProfileAnnotationsColor;
FitLineColor = OOPSData.Settings.ObjectIntensityProfileFitLineColor;
PixelLinesColor = OOPSData.Settings.ObjectIntensityProfilePixelLinesColor;
AzimuthLinesColor = OOPSData.Settings.ObjectIntensityProfileAzimuthLinesColor;
BackgroundColor = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;
ForegroundColor = OOPSData.Settings.ObjectIntensityProfileForegroundColor;

%% set up the figure to hold the intensity fit plot

figH = uifigure(...
    "HandleVisibility","on",...
    "Color",BackgroundColor,...
    "Visible","off");

figH.Position = [50 50 600 200];

axH = uiaxes(figH,...
    'Units','normalized',...
    'OuterPosition',[0 0 1 1],...
    'Color',BackgroundColor,...
    'XColor',ForegroundColor,...
    'YColor',ForegroundColor,...
    'XTick',0:pi/4:pi,...
    'XTickLabel',{'0°','45°','90°','135°','180°'},...
    'BoxStyle',"full",...
    'Box','on');

%% fit each set of pixel intensities to cos^2

    % the object mask
    Mask = Object.paddedSubImage;
    % padded object subarray idx
    PaddedSubarrayIdx = padSubarrayIdx(Object.SubarrayIdx,5);
    % initialize pixel-normalized intensity stack for curve fitting
    PaddedObjPixelNormIntensity = zeros([size(Mask),4]);
    % get pixel-normalized intensity stack for curve fitting
    PaddedObjPixelNormIntensity(:) = Object.Parent.ffcFPMPixelNorm(PaddedSubarrayIdx{:},:);
    % x and y values to fit to the sinusoid
    xReal = [0,pi/4,pi/2,3*(pi/4)];
    % y values to fit to the sinusoid
    yReal = PaddedObjPixelNormIntensity;
    % locations in the stack that we are considering
    [RowIndices,ColIndices] = find(Mask==1);
    % number of pixels in the image stack (nRows*nCols)
    nPixels = length(RowIndices);
    % vector of x values to pass into the function obtained by fitting
    xFit = linspace(0,pi,181);
    % prealocate cell array of sinusoidal fits for each pixel
    CurveFit = cell(nPixels,1);

    parfor i = 1:nPixels
        %% each vector in the third dimension is a set of y values for one round of fitting (one pixel)
        yFit = zeros(1,4);
        yFit(1:4) = yReal(RowIndices(i),ColIndices(i),:);
        %% Estimate initial values
        % maximum y value
        yMax = max(yFit);
        % minimum y value
        yMin = min(yFit);
        % peak-to-peak amplitude
        yRange = yMax-yMin;
        %% Fit experimental values to a generic squared cosine: Y = A * ((1+cos(2(X-B))/2) + C
        % anonymous fit function
        fit = @(b,x)  b(1) .* ((1 + cos(2.*(x-b(2))))./2) + b(3);
        % least-squares cost function to minimize
        fcn = @(b) sum((fit(b,xReal) - yFit).^2);
        % minimize least-squares
        s = fminsearch(fcn, [yRange; 1;  yMin]);
        %% Generate full curves using the parameters obtained above
        % y values to plot - found with the fitting function
        CurveFit{i} = fit(s,xFit);
    end

%% concatenate fit curves and phase lines for all pixels (new method without loop)

    % convert CurveFit cell array to nPixels x 181 matrix
    CurveFitMat = cell2mat(CurveFit);
    % get the average of all fits
    CurveFitAvg = mean(CurveFitMat,1);
    % create a cell array of NaNs, same size as CurveFit
    nanCell = arrayfun(@(x) x,nan(nPixels,1),'UniformOutput',false);
    % cell array with nPixels copies of xFit vectors
    xFitCell = repmat({xFit},nPixels,1);
    % combined x and y data for all fit lines (excluding average fit)
    xFitCombined = cell2mat(Interleave2DArrays(xFitCell,nanCell,'row')');
    yFitCombined = cell2mat(Interleave2DArrays(CurveFit,nanCell,'row')');
    % get max values and idx to the max values for each fit
    [maxVal,maxIdx] = max(CurveFitMat,[],2);
    % combined x and y data for all vertical phase lines
    xMaxCombined = cell2mat(Interleave2DArrays(arrayfun(@(x) [x x],xFit(maxIdx)','UniformOutput',false),nanCell,'row')');
    yMaxCombined = cell2mat(Interleave2DArrays(arrayfun(@(x) [0 x],maxVal,'UniformOutput',false),nanCell,'row')');
    % get max and minimum values for all curve fits
    MaxY = max(CurveFitMat,[],"all");
    MinY = min(CurveFitMat,[],"all");
    % plot each fit curve along with vertical lines to show phase
    line(axH,xMaxCombined,yMaxCombined,'Color',AzimuthLinesColor,'LineStyle','-','LineWidth',1,'HitTest','Off');
    line(axH,xFitCombined,yFitCombined,'Color',PixelLinesColor,'LineWidth',1,'HitTest','Off','LineStyle','-');
    
%% plot average fit line and amplitude/phase annotiations, set axes properties

    % plot the average fit line
    line(axH,xFit,CurveFitAvg,'LineWidth',4,'Color',FitLineColor);

    set(axH,'XLim',[0 pi]);
    set(axH,'YLim',[0 1]);
    
    movegui(figH,'center')
    figH.Visible = "on";

end