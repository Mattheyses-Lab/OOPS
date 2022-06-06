function [] = UpdateImages(source)
    %% Get relevant variables needed to update image data
    
    % get main data structure
    PODSData = guidata(source);
    
    % get gui handles
    Handles = PODSData.Handles;
    
    % get current group index
    cGroupIndex = PODSData.CurrentGroupIndex;
    % get current channel index

    % get current replicate index within group
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    
    % if multiple replicates selected, only update the gui to show the first one
    if length(cImageIndex) > 1
        cImageIndex = cImageIndex(1);
    end
    
    % get current replicate data structure, based on current group, image, and channel
    cImage = PODSData.Group(cGroupIndex).Replicate(cImageIndex);
    % get FFC data for current group, separate data per channel
    FFCData = PODSData.Group(cGroupIndex).FFCData;

    % empty image to serve as a placeholder
    EmptyImage = sparse(zeros(cImage.Height,cImage.Width));
    
    CurrentTab = PODSData.Settings.CurrentTab;

%% Update CData of gui image objects to reflect user-specified group/image change 

    switch CurrentTab
        
        case 'Files'
            try
                for i = 1:4
                    Handles.FFCImgH(i).CData = FFCData.cal_norm(:,:,i);
                    Handles.FFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
                drawnow
            catch
                UpdateLog3(source,'WARNING: No FFC Images found for this group, try loading them now','append');
                for i = 1:4
                    Handles.FFCImgH(i).CData = EmptyImage;
                    Handles.FFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end                
                drawnow
            end

            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
                drawnow
                clear images
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end                
                drawnow
            end
            
        case 'FFC'
            % flat-field corrected images
            try
                images = cImage.pol_ffc_normalizedbystack;
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = images(:,:,i);
                    Handles.PolFFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end        
            catch
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = EmptyImage;
                    Handles.PolFFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end                      
            end
            clear images

            % raw data images, normalized to stack max
            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
                drawnow                 
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};                    
                end
            end
            clear images
            
        case 'Generate Mask'
            % individual masking steps
            try
                % average FF-corrected intensity
                Handles.MStepsImgH(1).CData = cImage.I;
                
                % opened image (BG)
                Handles.MStepsImgH(2).CData = cImage.BGImg;

                % BG-subtracted image (tophat filtered)
                Handles.MStepsImgH(3).CData = cImage.BGSubtractedImg;
                Handles.MStepsAxH(3).CLim = [min(min(cImage.BGSubtractedImg)) max(max(cImage.BGSubtractedImg))];

                % Median filtered image
                Handles.MStepsImgH(4).CData = cImage.MedianFilteredImg;
                Handles.MStepsAxH(4).CLim = [min(min(cImage.MedianFilteredImg)) max(max(cImage.MedianFilteredImg))];
            catch
                Handles.MStepsImgH(1).CData = EmptyImage;
                Handles.MStepsImgH(2).CData = EmptyImage;
                Handles.MStepsImgH(3).CData = EmptyImage;
                Handles.MStepsImgH(4).CData = EmptyImage;        
            end
            
            for i = 1:4
                Handles.MStepsAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
            end
            
            % mask
            try
                Handles.MaskImgH.CData = cImage.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            % update intensity histogram
            try
                [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.MedianFilteredImg);
                Handles.ThreshBar.XData = cImage.IntensityBinCenters;
                Handles.ThreshBar.YData = cImage.IntensityHistPlot;
            catch
                disp('Warning: Failed to display intensity histogram');
            end
            
            try
                Handles.CurrentThresholdLine.Value = cImage.level;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Warning: Error moving thresh line...')
                Handles.CurrentThresholdLine.Value = 0.5;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            end            

        case 'View/Adjust Mask'
            
            UpdateSliders();
            
            % Mask
            try
                Handles.MaskImgH.CData = cImage.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            % update appearance of object bounding boxes for object selection and labeling
            try
                delete(Handles.ObjectRectangles)
            catch
                disp('Warning: Failed to delete object boxes');
            end
            
            % if ShowSelection toolbar state button is pressed
            if PODSData.Handles.ShowSelectionAverageIntensity.Value == 1
                for ObjIdx = 1:cImage.nObjects;
                    % plot expanded bounding boxes of each object...
                    % on intensity image
                    Handles.ObjectRectangles(ObjIdx,1) = rectangle(Handles.AverageIntensityAxH,...
                        'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'PickableParts','All',...
                        'Tag',[num2str(ObjIdx)],...
                        'ButtonDownFcn',@SelectSingleObjects);
                    % and on mask image
                    Handles.ObjectRectangles(ObjIdx,2) = rectangle(Handles.MaskAxH,...
                        'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'PickableParts','All',...
                        'Tag',[num2str(ObjIdx)],...
                        'ButtonDownFcn',@SelectSingleObjects);
                end
            end
            
            UpdateAverageIntensity();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            

            drawnow

            try
                [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.MedianFilteredImg);
                Handles.ThreshBar.XData = cImage.IntensityBinCenters;
                Handles.ThreshBar.YData = cImage.IntensityHistPlot;
            catch
                disp('Warning: Failed to update threshold slider with currently selected image data');
            end

            try
                Handles.CurrentThresholdLine.Value = cImage.level;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Warning: Error while moving thresh line...')
                Handles.CurrentThresholdLine.Value = 0.5;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            end            

        case 'Order Factor'
            
            UpdateSliders();
            
            % Order Factor
            try
                Handles.OrderFactorImgH.CData = cImage.OF_image;
            catch
                Handles.OrderFactorImgH.CData = EmptyImage;
            end
            
            % change colormap to currently selected Order factor colormap
            Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;
            
            % if ApplyMask toolbar state button set to true...
            if Handles.ApplyMaskOrderFactor.Value == 1
                % ...then apply current mask by setting image AlphaData
                Handles.OrderFactorImgH.AlphaData = cImage.bw;
            end

% interpolated OF image
%             OFImg = cImage.OF_image;
%             [X,Y] = meshgrid(1:1:length(OFImg));
%             [Xq,Yq] = meshgrid(1:0.25:length(OFImg));
%             OFImg_Interp = interp2(X,Y,OFImg,Xq,Yq,'cubic');
%             
%             try
%                 Handles.OrderFactorImgH.CData = OFImg_Interp;
%                  Handles.OrderFactorAxH.XLim = [1 length(OFImg_Interp)];
%                  Handles.OrderFactorAxH.YLim = [1 length(OFImg_Interp)];
%             catch
%                 Handles.OrderFactorImgH.CData = EmptyImage;
%             end

            UpdateAverageIntensity();

            try
                [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.MedianFilteredImg);
                Handles.ThreshBar.XData = cImage.IntensityBinCenters;
                Handles.ThreshBar.YData = cImage.IntensityHistPlot;
            catch
                disp('Warning: Failed to update threshold slider with currently selected image data');
            end

            try
                Handles.CurrentThresholdLine.Value = cImage.level;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Warning: Error while moving thresh line...')
                Handles.CurrentThresholdLine.Value = 0.5;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            end            

        case 'Azimuth'
            
            UpdateSliders();
            
%             % average intensity image
%             try 
%                 Handles.AverageIntensityImgH.CData = Scale0To1(cImage.I);
%                 Handles.AverageIntensityAxH.CLim = cImage.PrimaryIntensityDisplayLimits;
%             catch
%                 Handles.AverageIntensityImgH.CData = EmptyImage;
%             end

            UpdateAverageIntensity();
            
            try
                Handles.AzimuthImgH.CData = cImage.AzimuthImage;
                Handles.AzimuthAxH.CLim = [-pi,pi]; % very important to set for proper display colors
            catch
                Handles.AzimuthImgH.CData = EmptyImage;
            end
            
            % create 'circular' colormap by vertically concatenating
            %   2 hsv maps and make it current
            tempmap = hsv;
            colormap(Handles.AzimuthAxH,vertcat(tempmap,tempmap));
            
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if Handles.ApplyMaskAzimuthImage.Value == 1
                Handles.AzimuthImgH.AlphaData = cImage.bw;
            end

            try
                delete(Handles.AzimuthLines);
            catch
                disp('Warning: Could not delete Azimuth lines');
            end
            
            % get y and x coordinates from 'On' pixels in the mask image
            [y,x] = find(cImage.bw==1);
            % theta values are azimuth values from the pixels above
            theta = cImage.AzimuthImage(cImage.bw);
            % rho (magnitude) values come from the OF image
            rho = cImage.OF_image(cImage.bw);
            % conver to cartesian coordinates
            [u,v] = pol2cart(theta,rho);

            % transpose each set of endpoint coordinates
            x = x';
            y = y';
            u = u';
            v = v';

            % scaling factor of each 'half-line'
            HalfLineScale = PODSData.Settings.AzimuthLineScale/2;

            % x and y coordinates for each 'half-line'
            xnew3 = [x+HalfLineScale*u;x-HalfLineScale*u];
            ynew3 = [y-HalfLineScale*v;y+HalfLineScale*v];

            % colormap used to color azimuth lines
            cmap = PODSData.Settings.OrderFactorColormap;

            % number of unique colors in the current colormap
            nColors = length(cmap);

            % plot the azimuth lines and store their handles
            Handles.AzimuthLines = line(Handles.AverageIntensityAxH,...
                xnew3(:,1:PODSData.Settings.AzimuthScaleDownFactor:end),...
                ynew3(:,1:PODSData.Settings.AzimuthScaleDownFactor:end),...
                'LineWidth',PODSData.Settings.AzimuthLineWidth);

            % cell array of azimuth line colors (empty for now)
            LineColors = cell(length(Handles.AzimuthLines),1);
            
            % transparency of the azimuth lines
            LineAlpha = PODSData.Settings.AzimuthLineAlpha;

            % determine the color of each line based on the OF
            % in its corresponding pixel
            for i = 1:length(Handles.AzimuthLines)
                ColorIdx = round(nColors*rho(i));
                if ColorIdx==0
                    ColorIdx=1;
                end
                if ColorIdx>256
                    ColorIdx = 256;
                end

                Clr = [cmap(ColorIdx,:),LineAlpha];
                LineColors{i} = Clr;
            end
            
            % set the line colors we just determined
            set(Handles.AzimuthLines,{'Color'},LineColors);
            % disable interactivity because it is horribly slow and causes display issues
            set(Handles.AzimuthLines,'HitTest','Off');
            set(Handles.AzimuthLines,'PickableParts','None');

        case 'Plots'
            
            try
                delete(Handles.ScatterPlotAxH.Children)
            catch
                % do nothing
            end
            
            Handles.hScatterPlot = PlotGroupScatterPlot(source,Handles.ScatterPlotAxH);

            try
                delete(Handles.SwarmPlotAxH.Children)
            catch
                % do nothing
            end
            
            switch PODSData.Settings.SwarmChartGroupingType
                case 'Group'
                    % plot the swarm chart and save the plot handle
                    Handles.hSwarmChart = PlotGroupSwarmChart(source,Handles.SwarmPlotAxH);
                    Handles.SwarmPlotAxH.XAxis.Label.String = "Group";
                case 'Label'
                    % plot the swarm chart and save the plot handle
                    Handles.hSwarmChart = PlotSwarmChartByLabels(source,Handles.SwarmPlotAxH);
                    Handles.SwarmPlotAxH.XAxis.Label.String = "Label";
                case 'Both'
                    Handles.hSwarmChart = PlotSwarmChartByGroupAndLabels(source,Handles.SwarmPlotAxH);
                    Handles.SwarmPlotAxH.XAxis.Label.String = "Group (Label)";
            end
            
            Handles.SwarmPlotAxH.Title.String = ExpandVariableName(PODSData.Settings.SwarmChartYVariable);
            
            Handles.SwarmPlotAxH.YAxis.Label.String = ExpandVariableName(PODSData.Settings.SwarmChartYVariable);
             
        case 'Filtered Order Factor'
            %% Filtered Order Factor
            try
                Handles.FilteredOFImgH.CData = cImage.OFFiltered;
            catch
                Handles.FilteredOFImgH.CData = EmptyImage;
            end
            
        case 'View Objects'

            cObject = cImage.CurrentObject;

            try
                delete(Handles.ObjectIntensityPlotAxH.Children);
            catch
                disp('Warning: Failed to delete object intensity fit plot...');
            end
            
            % Object Viewer
            try
                delete(Handles.hObjectOFContour);
            catch
                disp('Warning: Failed to delete contour plot');
            end            

            % get object mask image, restrictive -> does not include nearby objects
            % within padded object bounding box
            RestrictedPaddedObjMask = cObject.RestrictedPaddedMaskSubImage;
            
            % pad the object subarrayidx with 5 pixels per side
            PaddedSubarrayIdx = padSubarrayIdx(cObject.SubarrayIdx,5);            
            
            % initialize pixel-normalized intensity stack for curve fitting
            PaddedObjPixelNormIntensity = zeros([size(RestrictedPaddedObjMask),4]);
            % get pixel-normalized intensity stack for curve fitting
            PaddedObjPixelNormIntensity(:) = cObject.Parent.norm(PaddedSubarrayIdx{:},:);
            % calculate and plot object intensity curve fits
            Handles.ObjectIntensityPlotAxH = PlotObjectIntensityProfile([0,pi/4,pi/2,3*(pi/4)],...
                PaddedObjPixelNormIntensity,...
                RestrictedPaddedObjMask,...
                Handles.ObjectIntensityPlotAxH);

            % display the (padded) intensity image of the object
            try
                Handles.ObjectPolFFCImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
                colormap(Handles.ObjectPolFFCAxH,PODSData.Settings.IntensityColormaps{1});
            catch
                disp('Warning: Error displaying object intensity image');
                Handles.ObjectPolFFCImgH.CData = EmptyImage;
            end

            % display object binary image
            try
                Handles.ObjectMaskImgH.CData = cObject.RestrictedPaddedMaskSubImage;
            catch
                disp('Warning: Error displaying object binary image');
                Handles.ObjectMaskImgH.CData = EmptyImage;
            end
            
            ObjectOFImg = cObject.PaddedOFSubImage;
            [X,Y] = meshgrid(1:1:length(ObjectOFImg));
            [Xq,Yq] = meshgrid(1:0.25:length(ObjectOFImg));
            ObjectOFImg_Interp = interp2(X,Y,ObjectOFImg,Xq,Yq,'cubic');
            
            try
                %Handles.ObjectOFImgH.CData = cObject.PaddedOFSubImage;
                Handles.ObjectOFImgH.CData = ObjectOFImg_Interp;
                Handles.ObjectOFAxH.Colormap = PODSData.Settings.OrderFactorColormap;
            catch
                disp('Warning: Error displaying object binary image');
                Handles.ObjectOFImgH.CData = EmptyImage;
            end

            % display object OF contour
            try
                [~,Handles.hObjectOFContour] = contourf(Handles.ObjectOFContourAxH,ObjectOFImg_Interp,'ShowText','On');
                colormap(Handles.ObjectOFContourAxH,PODSData.Settings.OrderFactorColormap);
            catch
                disp('Warning: Error displaying 2D Object OF contour');
            end            

            % initialize stack-normalized intensity stack for display
            PaddedObjNormIntensity = zeros([size(RestrictedPaddedObjMask),4]);
            % get stack-normalized intensity stack for display
            PaddedObjNormIntensity(:) = cObject.Parent.pol_ffc(PaddedSubarrayIdx{:},:);
            % normalize to stack maximum
            PaddedObjNormIntensity = PaddedObjNormIntensity./max(max(max(PaddedObjNormIntensity)));
            % show stack-normalized object intensity stack
            Handles.ObjectNormIntStackImgH.CData = [PaddedObjNormIntensity(:,:,1),...
                PaddedObjNormIntensity(:,:,2),...
                PaddedObjNormIntensity(:,:,3),...
                PaddedObjNormIntensity(:,:,4)];
            colormap(Handles.ObjectNormIntStackAxH,PODSData.Settings.IntensityColormaps{1});

            drawnow limitrate
             
    end

    function UpdateSliders()
        Handles.PrimaryIntensitySlider.Value = cImage.PrimaryIntensityDisplayLimits;
        Handles.ReferenceIntensitySlider.Value = cImage.ReferenceIntensityDisplayLimits;
    end

    function UpdateAverageIntensity()
        % make avg intensity/reference composite RGB, if applicable
        if cImage.ReferenceImageLoaded
            % truecolor composite overlay
            if PODSData.Handles.ShowReferenceImageAverageIntensity.Value == 1
                Map1 = PODSData.Settings.IntensityColormaps{1};
                Map2 = PODSData.Settings.ReferenceColormap;
                try
                    PODSData.Handles.AverageIntensityImgH.CData = ...
                        CompositeRGB(cImage.I,Map1,cImage.PrimaryIntensityDisplayLimits,...
                        Scale0To1(cImage.ReferenceImage),Map2,cImage.ReferenceIntensityDisplayLimits);
                    Handles.AverageIntensityAxH.CLim = [0 255];
                catch
                    disp('Warning: Failed to make composite RGB')
                end
            else % just show avg intensity
                try
                    Handles.AverageIntensityImgH.CData = Scale0To1(cImage.I);
                    Handles.AverageIntensityAxH.CLim = cImage.PrimaryIntensityDisplayLimits;
                catch
                    Handles.AverageIntensityImgH.CData = EmptyImage;
                end
                % change colormap to currently selected intensity colormap
                Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{1};
            end
        else % just show avg intensity
            try
                Handles.AverageIntensityImgH.CData = Scale0To1(cImage.I);
                Handles.AverageIntensityAxH.CLim = cImage.PrimaryIntensityDisplayLimits;
            catch
                Handles.AverageIntensityImgH.CData = EmptyImage;
            end
            % change colormap to currently selected intensity colormap
            Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{1};
        end
    end

    % update local PODSData structure with updated Handles
    PODSData.Handles = Handles;

end