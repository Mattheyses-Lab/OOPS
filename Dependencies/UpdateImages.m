function [] = UpdateImages(source)
    
    % get main data structure
    PODSData = guidata(source);
    
    % get gui handles
    Handles = PODSData.Handles;
    
%     % get current group index
%     cGroupIndex = PODSData.CurrentGroupIndex;
% 
%     % get current replicate index within group
%     cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
%     
%     % if multiple replicates selected, only update the gui to show the first one
%     if length(cImageIndex) > 1
%         cImageIndex = cImageIndex(1);
%     end
%     
%     % get current replicate data structure, based on current group, image, and channel
%     cImage = PODSData.Group(cGroupIndex).Replicate(cImageIndex);
%     % get FFC data for current group, separate data per channel
%     FFCData = PODSData.Group(cGroupIndex).FFCData;


    FFCData = PODSData.CurrentGroup(1).FFCData;
    cImage = PODSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % then we will update the display according to the first image in the list
        cImage = cImage(1);
    end

    % empty image to serve as a placeholder
    EmptyImage = sparse(zeros(cImage.Height,cImage.Width));
    
    % get the current tab
    CurrentTab = PODSData.Settings.CurrentTab;

%% Update CData of gui image objects to reflect user-specified group/image change 

    switch CurrentTab
        
        case 'Files'
            try
                for i = 1:4
                    Handles.FFCImgH(i).CData = FFCData.cal_norm(:,:,i);
                    %Handles.FFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
            catch
                UpdateLog3(source,'WARNING: No FFC Images found for this group, try loading them now','append');
                for i = 1:4
                    Handles.FFCImgH(i).CData = EmptyImage;
                    %Handles.FFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
            end

            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                    %Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
                clear images
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                    %Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end                
            end
            
        case 'FFC'
            % flat-field corrected images
            try
                images = cImage.pol_ffc_normalizedbystack;
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = images(:,:,i);
                    %Handles.PolFFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
                clear images
            catch
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = EmptyImage;
                    %Handles.PolFFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end                      
            end

            % raw data images, normalized to stack max
            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                    %Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
                end
                clear images
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                    %Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};                    
                end
            end
            
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
                Handles.MStepsImgH(4).CData = cImage.EnhancedImg;
                Handles.MStepsAxH(4).CLim = [min(min(cImage.EnhancedImg)) max(max(cImage.EnhancedImg))];
            catch
                Handles.MStepsImgH(1).CData = EmptyImage;
                Handles.MStepsImgH(2).CData = EmptyImage;
                Handles.MStepsImgH(3).CData = EmptyImage;
                Handles.MStepsImgH(4).CData = EmptyImage;        
            end
            
%             for i = 1:4
%                 Handles.MStepsAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
%             end
            
            % mask
            try
                Handles.MaskImgH.CData = cImage.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            UpdateThreshholdSlider();          

        case 'View/Adjust Mask'
            
            UpdateSliders();
            
            % Mask
            try
                Handles.MaskImgH.CData = cImage.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            try
                %delete(Handles.ObjectBoundaries);
                delete(findobj('Tag','ObjectBoundary'));
            catch
                warning('Unable to delete object boundaries!');
            end
            % update appearance of object bounding boxes for object selection and labeling
            try
                %delete(Handles.ObjectRectangles);
                delete(findobj('Tag','ObjectRectangles'));
            catch
                warning('Unable to delete object rectangles!');
            end
            
            % if ShowSelection toolbar state button is pressed
            if PODSData.Handles.ShowSelectionAverageIntensity.Value == 1

                for ObjIdx = 1:cImage.nObjects
                    Handles.fH.CurrentAxes = Handles.AverageIntensityAxH;
                    hold on
                    Boundary = cImage.Object(ObjIdx).Boundary;
                    Handles.ObjectBoundaries(ObjIdx) = plot(Boundary(:,2),...
                        Boundary(:,1),...
                        'Yellow',...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'Tag','ObjectBoundary',...
                        'HitTest','On',...
                        'ButtonDownFcn',@SelectSingleObjects,...
                        'PickableParts','all',...
                        'UserData',ObjIdx);
                    hold off

                    % plot expanded bounding boxes of each object...
                    % on intensity image
                    Handles.ObjectRectangles(ObjIdx,1) = rectangle(Handles.AverageIntensityAxH,...
                        'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'HitTest','off',...
                        'PickableParts','None',...
                        'Tag','ObjectRectangles',...
                        'ButtonDownFcn',@SelectSingleObjects,...
                        'Visible','Off',...
                        'UserData',ObjIdx);
                    % and on mask image
                    Handles.ObjectRectangles(ObjIdx,2) = rectangle(Handles.MaskAxH,...
                        'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'PickableParts','All',...
                        'Tag','ObjectRectangles',...
                        'ButtonDownFcn',@SelectSingleObjects,...
                        'UserData',ObjIdx);
                end
            end
            
            UpdateAverageIntensity();            
            UpdateThreshholdSlider();

            drawnow

        case 'Order Factor'

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

            try
                %delete(Handles.ObjectBoundaries);
                delete(findobj('Tag','ObjectBoundary'));
            catch
                warning('Unable to delete object boundaries!');
            end
            % update appearance of object bounding boxes for object selection and labeling
            try
                %delete(Handles.ObjectRectangles);
                delete(findobj('Tag','ObjectRectangles'));
            catch
                warning('Unable to delete object rectangles!');
            end
            
            % if ShowSelection toolbar state button is pressed
            if PODSData.Handles.ShowSelectionAverageIntensity.Value == 1

                for ObjIdx = 1:cImage.nObjects
                    Handles.fH.CurrentAxes = Handles.AverageIntensityAxH;
                    hold on
                    Boundary = cImage.Object(ObjIdx).Boundary;
                    Handles.ObjectBoundaries(ObjIdx) = plot(Boundary(:,2),...
                        Boundary(:,1),...
                        'Yellow',...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'Tag','ObjectBoundary',...
                        'HitTest','On',...
                        'ButtonDownFcn',@SelectSingleObjects,...
                        'PickableParts','all',...
                        'UserData',ObjIdx);
                    hold off

                    % plot expanded bounding boxes of each object...
                    % on intensity image
                    Handles.ObjectRectangles(ObjIdx,1) = rectangle(Handles.AverageIntensityAxH,...
                        'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'HitTest','off',...
                        'PickableParts','None',...
                        'Tag','ObjectRectangles',...
                        'ButtonDownFcn',@SelectSingleObjects,...
                        'Visible','Off',...
                        'UserData',ObjIdx);
                    % and on mask image
                    Handles.ObjectRectangles(ObjIdx,2) = rectangle(Handles.OrderFactorAxH,...
                        'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                        'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                        'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                        'PickableParts','All',...
                        'Tag','ObjectRectangles',...
                        'ButtonDownFcn',@SelectSingleObjects,...
                        'Visible','Off',...
                        'UserData',ObjIdx);
                end
            end

            UpdateSliders();
            UpdateAverageIntensity();
            UpdateThreshholdSlider();            
            drawnow

        case 'Azimuth'
            %% Azimuth
            UpdateSliders();
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
            circmap = vertcat(tempmap,tempmap);

            colormap(Handles.AzimuthAxH,circmap);
            
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if Handles.ApplyMaskAzimuthImage.Value == 1
                Handles.AzimuthImgH.AlphaData = cImage.bw;
            end

            try
                delete(Handles.AzimuthLines);
            catch
                disp('Warning: Could not delete Azimuth lines');
            end
            
            % if we wanted to show all lines (one per pixel) - NOT RECOMMENDED
%             tempmask = false(1024,1024);
% 
%             for rowidx = 4:4:1024
%                 for colidx = 4:4:1024
%                     tempmask(rowidx,colidx) = true;
%                 end
%             end
%             [y,x] = find(tempmask==1);
%             theta = cImage.AzimuthImage(tempmask);
%             rho = cImage.OF_image(tempmask);

            % get y and x coordinates from 'On' pixels in the mask image
            [y,x] = find(cImage.bw==1);
            % theta (direction) values are azimuth values from the pixels above
            theta = cImage.AzimuthImage(cImage.bw);
            % rho (magnitude) values come from the OF image
            rho = cImage.OF_image(cImage.bw);
            % convert to cartesian coordinates
            [u,v] = pol2cart(theta,rho);
            % transpose each set of endpoint coordinates
            x = x';
            y = y';
            u = u';
            v = v';
            % scaling factor of each 'half-line'
            HalfLineScale = PODSData.Settings.AzimuthLineScale/2;
            % x and y coordinates for each 'half-line'
            xnew = [x+HalfLineScale*u;x-HalfLineScale*u];
            ynew = [y-HalfLineScale*v;y+HalfLineScale*v];
            % 'bin' the x and y coords if desired,
            %   sometimes useful if plotting many lines
            xnew = xnew(:,1:PODSData.Settings.AzimuthScaleDownFactor:end);
            ynew = ynew(:,1:PODSData.Settings.AzimuthScaleDownFactor:end);
            rho = rho(1:PODSData.Settings.AzimuthScaleDownFactor:end);
            theta = theta(1:PODSData.Settings.AzimuthScaleDownFactor:end);
            % determine how many lines we will plot
            nLines = length(xnew);
            % cell array of azimuth line colors (empty for now)
            PatchColors = zeros(nLines,3);
            % transparency of the azimuth lines
            LineAlpha = PODSData.Settings.AzimuthLineAlpha;
            % mode by which to color the lines
            ColorMode = PODSData.Settings.AzimuthColorMode;

            switch ColorMode
                case 'Magnitude'
                    % colormap used to color azimuth lines by magnitude
                    MagnitudeColorMap = PODSData.Settings.OrderFactorColormap;
                    % number of colors in the map (for indexing)
                    nColors = length(MagnitudeColorMap);
                    % determine the color of each line based on the OF
                    % in its corresponding pixel
                    for i = 1:nLines
                        ColorIdx = round(nColors*rho(i));
                        if ColorIdx==0
                            ColorIdx=1;
                        end
                        if ColorIdx>nColors
                            ColorIdx = nColors;
                        end
                        PatchColors(i,:) = MagnitudeColorMap(ColorIdx,:);
                    end
                case 'Direction'
                    nColors = length(circmap);
                    % get the region of the circular map from
                    % -pi/2 to pi/2 (the range of our values)
                    halfcircmap = circmap(0.25*nColors:0.75*nColors,:);
                    nColors = length(halfcircmap);
                    ColorIdxsNorm = round(((theta+pi/2)./(pi))*nColors);
                    
                    for i = 1:nLines
                        ColorIdx = ColorIdxsNorm(i);
                        if ColorIdx==0
                            ColorIdx=1;
                        end
                        if ColorIdx>nColors
                            ColorIdx = nColors;
                        end
                        PatchColors(i,:) = halfcircmap(ColorIdx,:);
                    end
                case 'Mono'
                    MonoColor = [1 1 1];
                    for i = 1:nLines
                        PatchColors(i,:) = MonoColor;
                    end
            end

            Handles.AzimuthLines = QuiverPatch(Handles.AverageIntensityAxH,...
                xnew,ynew,...
                PatchColors,...
                PODSData.Settings.AzimuthLineWidth,...
                LineAlpha);

        case 'Plots'
            %% Scatter and swarm plots
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

            UpdateSliders();
            UpdateAverageIntensity();            
            UpdateThreshholdSlider();            
            
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

            % display object OF contour VERY SLOW - SHOULD REPLACE WITH A DIFFERENT PLOT
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

            drawnow
             
    end

    function UpdateSliders()
        % only update the sliders if the intensity display setting is active
        if strcmp(PODSData.Settings.CurrentImageOperation,'Intensity Display')
            Handles.PrimaryIntensitySlider.Value = cImage.PrimaryIntensityDisplayLimits;
            Handles.ReferenceIntensitySlider.Value = cImage.ReferenceIntensityDisplayLimits;
        end
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
                        CompositeRGB(Scale0To1(cImage.I),Map1,cImage.PrimaryIntensityDisplayLimits,...
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

    function UpdateThreshholdSlider()
        try
            [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.EnhancedImg);
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
    end

    % update local PODSData structure with updated Handles
    PODSData.Handles = Handles;
    guidata(PODSData.Handles.fH,PODSData);

end