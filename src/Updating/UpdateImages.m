function [] = UpdateImages(source,varargin)
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
    
    % get main data structure
    OOPSData = guidata(source);
    
    % get the current image
    cImage = OOPSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % then we will update the display according to the first image in the list
        cImage = cImage(1);
    end

    % empty image to serve as a placeholder
    EmptyImage = sparse(zeros(cImage.Height,cImage.Width));
    
    % check if we really need to update to prevent unnecessary overhead
    % ex: if varargin{1} = {'Files','Mask'}, only update if the current tab is 'Files' or 'Mask'
    if ~isempty(varargin)
        % if no choices match currently selected display type, don't update
        if ~any(ismember(varargin{1},OOPSData.Settings.CurrentTab))
            return
        end
    end

    switch OOPSData.Settings.CurrentTab

        case 'Files'
            cGroup = OOPSData.CurrentGroup;
            try
                for i = 1:4
                    OOPSData.Handles.FFCImgH(i).CData = cGroup.FFC_cal_norm(:,:,i);
                end
            catch
                for i = 1:4
                    OOPSData.Handles.FFCImgH(i).CData = EmptyImage;
                end
            end

            try
                images = cImage.rawFPMStack_normalizedbystack;
                for i = 1:4
                    OOPSData.Handles.RawIntensityImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    OOPSData.Handles.RawIntensityImgH(i).CData = EmptyImage;
                end                
            end
        case 'FFC'
            % flat-field corrected images
            try
                images = cImage.ffcFPMStack_normalizedbystack;
                for i = 1:4
                    OOPSData.Handles.PolFFCImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    OOPSData.Handles.PolFFCImgH(i).CData = EmptyImage;
                end                      
            end

            % raw images, normalized to stack max
            try
                images = cImage.rawFPMStack_normalizedbystack;
                for i = 1:4
                    OOPSData.Handles.RawIntensityImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    OOPSData.Handles.RawIntensityImgH(i).CData = EmptyImage;
                end
            end         

        case 'Mask'
            % display mask image
            try
                OOPSData.Handles.MaskImgH.CData = cImage.bw;
                if ~OOPSData.Settings.Zoom.Active
                    OOPSData.Handles.MaskAxH.XLim = [0.5 cImage.Width+0.5];
                    OOPSData.Handles.MaskAxH.YLim = [0.5 cImage.Height+0.5];
                end
            catch
                OOPSData.Handles.MaskImgH.CData = EmptyImage;
            end
            
            UpdateAverageIntensityImage(source);      

            UpdateObjectBoxes(source);

        case 'Order'

            % update the Order image and axes
            UpdateOrderImage(source);

            % update the average intensity image and axes
            UpdateAverageIntensityImage(source);

            % update the object selection boxes
            UpdateObjectBoxes(source);

        case 'Azimuth'

            % update the average intensity image axes
            UpdateAverageIntensityImage(source);

            % update the Azimuth image CData, colorbar, and AlphaData
            UpdateAzimuthImage(source);
            
            % update azimuth stick overlay on the average intensity axes
            UpdateAzimuthStickOverlay(source);

        case 'Plots'

            try
                delete(OOPSData.Handles.ScatterPlotAxH.Children)
            catch
                % do nothing
            end
            
            % update the scatter plot
            OOPSData.Handles.hScatterPlot = PlotGroupScatterPlot(source,...
                OOPSData.Handles.ScatterPlotAxH);

            % update the swarm chart
            UpdateSwarmChart(source);

        case 'Polar Plots'

            if isempty(cImage)
                polarData = [];
                groupPolarData = [];
            else
                % get the polar data for this image
                polarData = deg2rad([cImage.Object(:).(OOPSData.Settings.PolarHistogramVariable)]);
                polarData(isnan(polarData)) = [];
                polarData(polarData<0) = polarData(polarData<0)+pi;
                % get the polar data for this group
                groupPolarData = deg2rad(OOPSData.CurrentGroup.GetAllObjectData(OOPSData.Settings.PolarHistogramVariable));
                groupPolarData(isnan(groupPolarData)) = [];
                groupPolarData(groupPolarData<0) = groupPolarData(groupPolarData<0)+pi;                
            end

            % set polar data and title for image polar histogram
            OOPSData.Handles.ImagePolarHistogram.polarData = [polarData,polarData+pi];
            OOPSData.Handles.ImagePolarHistogram.Title = ['Image - Object ',OOPSData.Settings.expandVariableName(OOPSData.Settings.PolarHistogramVariable)];

            % set polar data and title for group polar histogram
            OOPSData.Handles.GroupPolarHistogram.polarData = [groupPolarData,groupPolarData+pi];
            OOPSData.Handles.GroupPolarHistogram.Title = ['Group - Object ',OOPSData.Settings.expandVariableName(OOPSData.Settings.PolarHistogramVariable)];

        case 'Objects'

            try
                % get handle to the current object
                cObject = cImage.CurrentObject;
                % get object mask image, restricted -> does not include nearby objects
                % within padded object bounding box
                paddedSubImage = cObject.paddedSubImage;
                % pad the object subarrayidx with 5 pixels per side
                paddedSubarrayIdx = padSubarrayIdx(cObject.SubarrayIdx,5);
            catch
                disp('Warning: Error retrieving object data')
            end
            
            if any(isvalid(OOPSData.Handles.ObjectIntensityPlotAxH.Children))
                delete(OOPSData.Handles.ObjectIntensityPlotAxH.Children);
            end      

            try
                % initialize pixel-normalized intensity stack for curve fitting
                PaddedObjPixelNormIntensity = zeros([size(paddedSubImage),4]);
                % get pixel-normalized intensity stack for curve fitting
                PaddedObjPixelNormIntensity(:) = cObject.Parent.ffcFPMPixelNorm(paddedSubarrayIdx{:},:);
                % calculate and plot object intensity curve fits
                OOPSData.Handles.ObjectIntensityPlotAxH = PlotObjectIntensityProfile([0,pi/4,pi/2,3*(pi/4)],...
                    PaddedObjPixelNormIntensity,...
                    paddedSubImage,...
                    OOPSData.Handles.ObjectIntensityPlotAxH,...
                    OOPSData.Settings.ObjectIntensityProfileFitLineColor,...
                    OOPSData.Settings.ObjectIntensityProfilePixelLinesColor,...
                    OOPSData.Settings.ObjectIntensityProfileAnnotationsColor,...
                    OOPSData.Settings.ObjectIntensityProfileAzimuthLinesColor);
            catch
                disp('Warning: Error displaying object sinusoidal intensity fit curves');
            end

            % display the (padded) intensity image of the object
            try
                OOPSData.Handles.ObjectPolFFCImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
            catch
                disp('Warning: Error displaying object intensity image');
                OOPSData.Handles.ObjectPolFFCImgH.CData = EmptyImage;
            end

            % display object binary image
            try
                % testing below - use RGB instead of logical for easier exporting
                OOPSData.Handles.ObjectMaskImgH.CData = cObject.MaskImageRGB;
                OOPSData.Handles.ObjectMaskAxH.XLim = OOPSData.Handles.ObjectPolFFCAxH.XLim;
                OOPSData.Handles.ObjectMaskAxH.YLim = OOPSData.Handles.ObjectPolFFCAxH.YLim;
            catch
                disp('Warning: Error displaying object binary image');
                OOPSData.Handles.ObjectMaskImgH.CData = EmptyImage;
            end
            
            % display object Order image
            UpdateObjectOrderImage(source);

            % display the (padded) intensity image of the object
            try
                OOPSData.Handles.ObjectAzimuthOverlayImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
            catch
                disp('Warning: Error displaying object intensity image');
                OOPSData.Handles.ObjectAzimuthOverlayImgH.CData = EmptyImage;
            end

            if any(isvalid(OOPSData.Handles.ObjectAzimuthLines))
                delete(OOPSData.Handles.ObjectAzimuthLines);
            end

            try
                delete(OOPSData.Handles.ObjectAzimuthLines);
            catch
                disp('Warning: Could not delete Object Azimuth lines');
            end

            try
                delete(OOPSData.Handles.ObjectMidlinePlot);
            catch
                disp('Warning: Could not delete object midline plot');
            end

            try
                delete(OOPSData.Handles.ObjectBoundaryPlot);
            catch
                disp('Warning: Could not delete object boundary plot');
            end

            try

                LineMask = cObject.paddedSubImage;
                LineScaleDown = OOPSData.Settings.ObjectAzimuthScaleDownFactor;
    
                if LineScaleDown > 1
                    ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
                    LineMask = LineMask & logical(ScaleDownMask);
                end

                [y,x] = find(LineMask==1);
                
                % azimuth line directions
                theta = cObject.PaddedAzimuthSubImage(LineMask);
                % azimuth line lengths
                rho = cObject.PaddedOrderSubImage(LineMask);
                % settings controlling line appearance
                ColorMode = OOPSData.Settings.ObjectAzimuthColorMode;
                LineWidth = OOPSData.Settings.ObjectAzimuthLineWidth;
                LineAlpha = OOPSData.Settings.ObjectAzimuthLineAlpha;
                LineScale = OOPSData.Settings.ObjectAzimuthLineScale;


                if strcmp(ColorMode,'RelativeDirection')
                    theta2 = cObject.MidlineRelativeAzimuthImage(LineMask);
                else
                    theta2 = [];
                end
    
                switch ColorMode
                    case 'Magnitude'
                        Colormap = OOPSData.Settings.OrderColormap;
                    case {'Direction','RelativeDirection'}
                        Colormap = repmat(OOPSData.Settings.AzimuthColormap,2,1);
                    case 'Mono'
                        Colormap = [1 1 1];
                end

                % plot pixel azimuth sticks for the object
                OOPSData.Handles.ObjectAzimuthLines = QuiverPatch2(OOPSData.Handles.ObjectAzimuthOverlayAxH,...
                    x,...
                    y,...
                    theta,...
                    rho,...
                    ColorMode,...
                    Colormap,...
                    LineWidth,...
                    LineAlpha,...
                    LineScale,...
                    theta2);

                objectPaddedSize = size(cObject.paddedSubImage);

                OOPSData.Handles.ObjectAzimuthOverlayAxH.YLim = [0.5 objectPaddedSize(1)+0.5];
                OOPSData.Handles.ObjectAzimuthOverlayAxH.XLim = [0.5 objectPaddedSize(2)+0.5];
                
            catch ME
                % because setting the axes limits will change lim mode to 'manual', we need to set the limits
                % if the sticks don't display properly in the try block above. Otherwise, the limits of 
                % the axes might not match the size of CData of the image object it holds
                OOPSData.Handles.ObjectAzimuthOverlayAxH.XLim = OOPSData.Handles.ObjectPolFFCAxH.XLim;
                OOPSData.Handles.ObjectAzimuthOverlayAxH.YLim = OOPSData.Handles.ObjectPolFFCAxH.YLim;
                % send a warning to the command window
                warning(['Error displaying object azimuth sticks: ', ME.message]);
            end


            try
                % retrieve the object midline coordinates
                Midline = cObject.Midline;
                % if not empty...
                if ~isempty(Midline) && ~any(isnan(Midline(:)))
                    % plot midline coordinates as a primitive line
                    OOPSData.Handles.ObjectMidlinePlot = line(OOPSData.Handles.ObjectMaskAxH,...
                        'XData',Midline(:,1),...
                        'YData',Midline(:,2),...
                        'Marker','none',...
                        'LineStyle','-',...
                        'LineWidth',2,...
                        'Color',[0 0 0]);
                end

                objectPaddedSize = size(cObject.paddedSubImage);

                OOPSData.Handles.ObjectMaskAxH.YLim = [0.5 objectPaddedSize(1)+0.5];
                OOPSData.Handles.ObjectMaskAxH.XLim = [0.5 objectPaddedSize(2)+0.5];

            catch ME
                UpdateLog3(source,['Warning: Error displaying object midline: ', ME.message],'append');
                % reset the axes limits to match the object image size
                OOPSData.Handles.ObjectMaskAxH.XLim = OOPSData.Handles.ObjectPolFFCAxH.XLim;
                OOPSData.Handles.ObjectMaskAxH.YLim = OOPSData.Handles.ObjectPolFFCAxH.YLim;
            end


            % try and plot the object boundary
            try
                % get the object boundary coordinates w.r.t. the padded intensity image
                paddedBoundary = cObject.paddedSubImageBoundary;

                OOPSData.Handles.ObjectBoundaryPlot = line(OOPSData.Handles.ObjectPolFFCAxH,...
                    paddedBoundary(:,2),...
                    paddedBoundary(:,1),...
                    'Color',cObject.Label.Color,...
                    'LineWidth',3);
            catch ME
                UpdateLog3(source,['Warning: Error displaying object boundary: ', ME.message],'append');
            end


            try
                % initialize stack-normalized intensity stack for display
                PaddedObjNormIntensity = zeros([size(paddedSubImage),4]);
                % get stack-normalized intensity stack for display
                PaddedObjNormIntensity(:) = cObject.Parent.ffcFPMStack(paddedSubarrayIdx{:},:);
                % normalize to stack maximum
                % PaddedObjNormIntensity = PaddedObjNormIntensity./max(max(max(PaddedObjNormIntensity)));
                % rescale the object intensity stack to the range [0 1]
                PaddedObjNormIntensity = Scale0To1(PaddedObjNormIntensity);
                % show stack-normalized object intensity stack
                OOPSData.Handles.ObjectNormIntStackImgH.CData = [PaddedObjNormIntensity(:,:,1),...
                    PaddedObjNormIntensity(:,:,2),...
                    PaddedObjNormIntensity(:,:,3),...
                    PaddedObjNormIntensity(:,:,4)];
            catch
                disp('Warning: Error displaying stack-normalized object intensity')
                OOPSData.Handles.ObjectNormIntStackImgH.CData = repmat(EmptyImage,1,4);
            end

        otherwise
            %% CustomFPMStatistic view

            % update the display of the custom statistic image
            UpdateCustomStatImage(source);

            % update the display of the average intensity image
            UpdateAverageIntensityImage(source);
             
    end

end