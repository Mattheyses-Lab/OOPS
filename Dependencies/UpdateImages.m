function [] = UpdateImages(source)
    %% Get relevant variables needed to update image data
    
    % get main data structure
    PODSData = guidata(source);
    
    % get gui handles
    Handles = PODSData.Handles;
    
    % get current group index
    cGroupIndex = PODSData.CurrentGroupIndex;
    % get current channel index
    %cChannelIdx = PODSData.CurrentChannelIndex;
    % get current replicate index within group
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    
    % if multiple replicates selected, only update the gui to show the first one
    if length(cImageIndex) > 1
        cImageIndex = cImageIndex(1);
    end
    
    % get current replicate data structure, based on current group, image, and channel
    Replicate = PODSData.Group(cGroupIndex).Replicate(cImageIndex);
    % get FFC data for current group, separate data per channel
    FFCData = PODSData.Group(cGroupIndex).FFCData;

    % empty image to serve as a placeholder
    EmptyImage = sparse(zeros(Replicate.Height,Replicate.Width));
    
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
                images = Replicate.pol_rawdata_normalizedbystack;
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
                images = Replicate.pol_ffc_normalizedbystack;
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
                images = Replicate.pol_rawdata_normalizedbystack;
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
                Handles.MStepsImgH(1).CData = Replicate.I;
                
                % opened image (BG)
                Handles.MStepsImgH(2).CData = Replicate.BGImg;

                % BG-subtracted image (tophat filtered)
                Handles.MStepsImgH(3).CData = Replicate.BGSubtractedImg;
                Handles.MStepsAxH(3).CLim = [min(min(Replicate.BGSubtractedImg)) max(max(Replicate.BGSubtractedImg))];

                % Median filtered image
                Handles.MStepsImgH(4).CData = Replicate.MedianFilteredImg;
                Handles.MStepsAxH(4).CLim = [min(min(Replicate.MedianFilteredImg)) max(max(Replicate.MedianFilteredImg))];
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
                Handles.MaskImgH.CData = Replicate.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            try
                Handles.ThreshBar.XData = Replicate.IntensityBinCenters;
                Handles.ThreshBar.YData = Replicate.IntensityHistPlot;
            catch
                disp('Warning: Failed to update threshold slider with currently selected image data');
            end
            
            try
                Handles.CurrentThresholdLine.Value = Replicate.level;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Warning: Error moving thresh line...')
                Handles.CurrentThresholdLine.Value = 0.5;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            end            

        case 'View/Adjust Mask'
            
            % Mask
            try
                Handles.MaskImgH.CData = Replicate.bw;
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

                for ObjIdx = 1:Replicate.nObjects;
                    % plot expanded bounding boxes of each object...
                    % on intensity image
                    Handles.ObjectRectangles(ObjIdx,1) = rectangle(Handles.AverageIntensityAxH,...
                        'Position',ExpandBoundingBox(Replicate.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',Replicate.Object(ObjIdx).Label.Color,...
                        'LineWidth',Replicate.Object(ObjIdx).SelectionBoxLineWidth,...
                        'PickableParts','All',...
                        'Tag',[num2str(ObjIdx)],...
                        'ButtonDownFcn',@SelectSingleObjects);
                    % and on mask image
                    Handles.ObjectRectangles(ObjIdx,2) = rectangle(Handles.MaskAxH,...
                        'Position',ExpandBoundingBox(Replicate.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',Replicate.Object(ObjIdx).Label.Color,...
                        'LineWidth',Replicate.Object(ObjIdx).SelectionBoxLineWidth,...
                        'PickableParts','All',...
                        'Tag',[num2str(ObjIdx)],...
                        'ButtonDownFcn',@SelectSingleObjects);
                end
            end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            %%!!NEEDS WORK!!%% Alpha blending overlay
%             if Replicate.ReferenceImageLoaded
%                 PODSData.Handles.ReferenceImgH.CData = Scale0To1(Replicate.ReferenceImage);
%                 if PODSData.Handles.ShowReferenceImageAverageIntensity.Value == 1
%                     try
%                         PODSData.Handles.AverageIntensityImgH.AlphaData = ones(size(EmptyImage))*0.5;
%                         PODSData.Handles.ReferenceAxH.Colormap = PODSData.Settings.ReferenceColormap;
%                         linkaxes([Handles.AverageIntensityAxH,Handles.ReferenceAxH],'xy');
%                     catch
%                         warning('Failed to set reference image CData')
%                     end
%                 end                
%             end
            
            if Replicate.ReferenceImageLoaded
                % truecolor composite overlay
                if PODSData.Handles.ShowReferenceImageAverageIntensity.Value == 1
                    ReferenceImage = Scale0To1(Replicate.ReferenceImage);
                    Map1 = PODSData.Settings.IntensityColormaps{1};
                    Map2 = PODSData.Settings.ReferenceColormap;
                    try
                        PODSData.Handles.AverageIntensityImgH.CData = ...
                            CompositeRGB(Scale0To1(Replicate.I),Map1,ReferenceImage,Map2);
                        Handles.AverageIntensityAxH.CLim = [0 255];
                    catch
                        disp('Warning: Failed to make composite RGB')
                    end
                else % just show avg intensity
                    try
                        Handles.AverageIntensityImgH.CData = Scale0To1(Replicate.I);
                        Handles.AverageIntensityAxH.CLim = [0 1];
                    catch
                        Handles.AverageIntensityImgH.CData = EmptyImage;
                    end
                    % change colormap to currently selected intensity colormap
                    Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{1};
                end
            else % just show avg intensity
                try
                    Handles.AverageIntensityImgH.CData = Scale0To1(Replicate.I);
                    Handles.AverageIntensityAxH.CLim = [0 1];
                catch
                    Handles.AverageIntensityImgH.CData = EmptyImage;
                end
                % change colormap to currently selected intensity colormap
                Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{1};
            end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            

            drawnow
            
            try
                Handles.ThreshBar.XData = Replicate.IntensityBinCenters;
                Handles.ThreshBar.YData = Replicate.IntensityHistPlot;
            catch
                disp('Warning: Failed to update threshold slider with currently selected image data');
            end

            try
                Handles.CurrentThresholdLine.Value = Replicate.level;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Warning: Error while moving thresh line...')
                Handles.CurrentThresholdLine.Value = 0.5;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            end            

        case 'Order Factor'
            
            % Order Factor
            try
                Handles.OrderFactorImgH.CData = Replicate.OF_image;
            catch
                Handles.OrderFactorImgH.CData = EmptyImage;
            end
            % change colormap to currently selected Order factor colormap
            Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;
            
             % if ApplyMask toolbar state button set to true... 
             if Handles.ApplyMaskOrderFactor.Value == 1
                 % ...then apply current mask by setting image AlphaData
                 Handles.OrderFactorImgH.AlphaData = Replicate.bw;
             end

            % average intensity image
            try
                Handles.AverageIntensityImgH.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImgH.CData = EmptyImage;
            end
            % change colormap to currently selected intensity colormap
            Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{1};

        case 'Azimuth'
            % average intensity image
            try 
                Handles.AverageIntensityImgH.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImgH.CData = EmptyImage;
            end
            
            % change colormap to currently selected intensity colormap
            colormap(Handles.AverageIntensityAxH,PODSData.Settings.IntensityColormaps{1});
            
            try
                Handles.AzimuthImgH.CData = Replicate.AzimuthImage;
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
                Handles.AzimuthImgH.AlphaData = Replicate.bw;
            end

            try
                delete(Handles.AzimuthLines);
            catch
                disp('Warning: Could not delete Azimuth lines');
            end
            
            % get y and x coordinates from 'On' pixels in the mask image
            [y,x] = find(Replicate.bw==1);
            % theta values are azimuth values from the pixels above
            theta = Replicate.AzimuthImage(Replicate.bw);
            % rho (magnitude) values come from the OF image
            rho = Replicate.OF_image(Replicate.bw);
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
                %delete(Handles.hSwarmChart)
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
                Handles.FilteredOFImgH.CData = Replicate.OFFiltered;
            catch
                Handles.FilteredOFImgH.CData = EmptyImage;
            end
            
        case 'View Objects'

            % Object Viewer
            try;delete(Handles.hObjectOFContour);catch;disp('Warning: Failed to delete contour plot');end
            
            cObject = Replicate.CurrentObject;

            % display the (padded) intensity image of the object
            try
                Handles.ObjectPolFFCImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
                %Handles.ObjectPolFFCAxH.CLim = [0 1];
            catch
                disp('Warning: Error displaying object intensity image');
                Handles.ObjectPolFFCImgH.CData = EmptyImage;
            end
            
            colormap(Handles.ObjectPolFFCAxH,PODSData.Settings.IntensityColormaps{1});

            % display object binary image
            try
                Handles.ObjectMaskImgH.CData = cObject.RestrictedPaddedMaskSubImage;
                %Handles.ObjectMaskImgH.CData = cObject.PaddedMaskSubImage;
            catch
                disp('Warning: Error displaying object binary image');
                Handles.ObjectMaskImgH.CData = EmptyImage;
            end
            
            %Handles.ObjectOFImgH.CData = cObject.PaddedOFSubImage;
            Handles.ObjectOFImgH.CData = cObject.PaddedOFSubImage;
            Handles.ObjectOFAxH.Colormap = PODSData.Settings.OrderFactorColormap;
            
            % get object mask image, restrictive -> does not include nearby objects
            % within padded object bounding box
            RestrictedPaddedObjMask = cObject.RestrictedPaddedMaskSubImage;
            % pad the object subarrayidc with 5 pixels per side
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
            
            % show pixel-normalized object intensity stack
            % show all 4 images in same image object by horizontal concatenation
            Handles.ObjectPixelNormIntStackImgH.CData = [PaddedObjPixelNormIntensity(:,:,1),...
                PaddedObjPixelNormIntensity(:,:,2),...
                PaddedObjPixelNormIntensity(:,:,3),...
                PaddedObjPixelNormIntensity(:,:,4)];
            colormap(Handles.ObjectPixelNormIntStackAxH,PODSData.Settings.IntensityColormaps{1});
            
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

%% display object OF contour
            try
                [~,Handles.hObjectOFContour] = contourf(Handles.ObjectOFContourAxH,cObject.OFSubImage,'ShowText','On');
                colormap(Handles.ObjectOFContourAxH,PODSData.Settings.OrderFactorColormap);
            catch
                disp('Warning: Error displaying 2D Object Order Factor contours');
            end
            
            drawnow
            
        end

    % update local PODSData structure with updated Handles
    PODSData.Handles = Handles;
    % update guidata with updated PODSData structure
    guidata(source,PODSData);
    

end