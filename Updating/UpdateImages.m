function [] = UpdateImages(source)
    
    % get main data structure
    PODSData = guidata(source);
    
    % get the current image
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
            %% FILES
            cGroup = PODSData.CurrentGroup;
            try
                for i = 1:4
                    PODSData.Handles.FFCImgH(i).CData = cGroup.FFC_cal_norm(:,:,i);
                end
            catch
                UpdateLog3(source,'WARNING: No FFC Images found for this group, try loading them now','append');
                for i = 1:4
                    PODSData.Handles.FFCImgH(i).CData = EmptyImage;
                end
            end

            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    PODSData.Handles.RawIntensityImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    PODSData.Handles.RawIntensityImgH(i).CData = EmptyImage;
                end                
            end
        case 'FFC'
            %% FFC
            % flat-field corrected images
            try
                images = cImage.pol_ffc_normalizedbystack;
                for i = 1:4
                    PODSData.Handles.PolFFCImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    PODSData.Handles.PolFFCImgH(i).CData = EmptyImage;
                end                      
            end

            % raw data images, normalized to stack max
            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    PODSData.Handles.RawIntensityImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    PODSData.Handles.RawIntensityImgH(i).CData = EmptyImage;
                end
            end
            
        case 'Generate Mask'
            %% MASKING STEPS
            try
                % average FF-corrected intensity
                PODSData.Handles.MStepsImgH(1).CData = cImage.I;
                
                % opened image (BG)
                PODSData.Handles.MStepsImgH(2).CData = cImage.BGImg;

                % BG-subtracted image (tophat filtered)
                PODSData.Handles.MStepsImgH(3).CData = cImage.BGSubtractedImg;
                PODSData.Handles.MStepsAxH(3).CLim = [min(min(cImage.BGSubtractedImg)) max(max(cImage.BGSubtractedImg))];

                % enhanced image
                PODSData.Handles.MStepsImgH(4).CData = cImage.EnhancedImg;
                PODSData.Handles.MStepsAxH(4).CLim = [min(min(cImage.EnhancedImg)) max(max(cImage.EnhancedImg))];
            catch
                PODSData.Handles.MStepsImgH(1).CData = EmptyImage;
                PODSData.Handles.MStepsImgH(2).CData = EmptyImage;
                PODSData.Handles.MStepsImgH(3).CData = EmptyImage;
                PODSData.Handles.MStepsImgH(4).CData = EmptyImage;        
            end
            
            % mask
            try
                PODSData.Handles.MaskImgH.CData = cImage.bw;
            catch
                PODSData.Handles.MaskImgH.CData = EmptyImage;
            end

            UpdateThreshholdSlider();          

        case 'Mask'
            %% VIEW MASK
            UpdateSliders();
            
            % Mask
            try
                PODSData.Handles.MaskImgH.CData = cImage.bw;
                if ~PODSData.Settings.Zoom.Active
                    PODSData.Handles.MaskAxH.XLim = [0.5 cImage.Width+0.5];
                    PODSData.Handles.MaskAxH.YLim = [0.5 cImage.Height+0.5];
                end
            catch
                PODSData.Handles.MaskImgH.CData = EmptyImage;
            end

            if any(isvalid(PODSData.Handles.ObjectBoxes))
                delete(PODSData.Handles.ObjectBoxes);
                clear PODSData.Handles.ObjectBoxes
                PODSData.Handles.ObjectBoxes = gobjects(1,1);
            end

            if any(isvalid(PODSData.Handles.SelectedObjectBoxes))
                delete(PODSData.Handles.SelectedObjectBoxes);
                clear PODSData.Handles.SelectedObjectBoxes
                PODSData.Handles.SelectedObjectBoxes = gobjects(1,1);
            end

            % if ShowSelection toolbar state button is pressed,
            % show object selection boxes
            if PODSData.Handles.ShowSelectionAverageIntensity.Value == 1
                switch PODSData.Settings.ObjectBoxType
                    case 'Boundary'
                        for ObjIdx = 1:cImage.nObjects
                            PODSData.Handles.fH.CurrentAxes = PODSData.Handles.AverageIntensityAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            PODSData.Handles.ObjectBoxes(ObjIdx,1) = plot(Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);
                            hold off
        
                            PODSData.Handles.fH.CurrentAxes = PODSData.Handles.MaskAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            PODSData.Handles.ObjectBoxes(ObjIdx,2) = plot(Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);
                            hold off
                        end
                    case 'Box'
                        for ObjIdx = 1:cImage.nObjects
                            % plot expanded bounding boxes of each object...
                            % on intensity image
                            PODSData.Handles.ObjectBoxes(ObjIdx,1) = rectangle(PODSData.Handles.AverageIntensityAxH,...
                                'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                                'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'HitTest','On',...
                                'PickableParts','All',...
                                'Tag','ObjectBox',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'Visible','On',...
                                'UserData',ObjIdx);
                            % and on mask image
                            PODSData.Handles.ObjectBoxes(ObjIdx,2) = rectangle(PODSData.Handles.MaskAxH,...
                                'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                                'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'HitTest','On',...
                                'PickableParts','All',...
                                'Tag','ObjectBox',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'Visible','On',...
                                'UserData',ObjIdx);
                        end
                    case 'NewBoxes'
                        % plotting obj patches with faces/vertices
                        % (we could also pass in the object boundary coordinates as XData and YData)
                        [SelectedFaces,...
                            SelectedVertices,...
                            SelectedCData,...
                            UnselectedFaces,...
                            UnselectedVertices,...
                            UnselectedCData...
                            ] = getObjectPatchData(cImage);

                        PODSData.Handles.fH.CurrentAxes = PODSData.Handles.AverageIntensityAxH;
                        hold on

                        if ~isempty(UnselectedVertices)
                            PODSData.Handles.ObjectBoxes = patch(PODSData.Handles.AverageIntensityAxH,...
                                'Faces',UnselectedFaces,...
                                'Vertices',UnselectedVertices,...
                                'Tag','ObjectBox',...
                                'FaceVertexCData',UnselectedCData,...
                                'EdgeColor','Flat',...
                                'FaceColor','none',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectSingleObjects,...
                                'PickableParts','all',...
                                'Interruptible','off');
                            PODSData.Handles.ObjectBoxes.LineWidth = 1;
                        end
                        if ~isempty(SelectedVertices)
                            PODSData.Handles.SelectedObjectBoxes = patch(PODSData.Handles.AverageIntensityAxH,...
                                'Faces',SelectedFaces,...
                                'Vertices',SelectedVertices,...
                                'Tag','ObjectBox',...
                                'FaceVertexCData',SelectedCData,...
                                'EdgeColor','Flat',...
                                'FaceColor','none',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectSingleObjects,...
                                'PickableParts','all',...
                                'Interruptible','off');
                            PODSData.Handles.SelectedObjectBoxes.LineWidth = 2;
                        end
                        hold off
                end
            end
            
            UpdateAverageIntensity();            
            UpdateThreshholdSlider();

            drawnow

        case 'Order Factor'
            %% Order Factor Tab
            % Order Factor
            if PODSData.Handles.ShowAsOverlayOrderFactor.Value == 1
                % show the OF-intensity composite image
                try
                    %OverlayIntensity = imadjust(cImage.I,cImage.PrimaryIntensityDisplayLimits);
                    %OverlayIntensity = imadjust(cImage.I);
                    %OverlayIntensity = imadjust(cImage.I);
                    %OverlayIntensity = Scale0To1(imadjust(cImage.I.*cImage.OF_image));
                    OverlayIntensity = cImage.I;
                    OFRGB = ind2rgb(im2uint8(cImage.OF_image),PODSData.Settings.OrderFactorColormap);
                    OFRGB = MaskRGB(OFRGB,OverlayIntensity);
                    PODSData.Handles.OrderFactorImgH.CData = OFRGB;
                catch
                    PODSData.Handles.AzimuthImgH.CData = EmptyImage;
                    disp('Warning: Error displaying OF-intensity composite image')
                end
            else
                % show the regular OF image
                try
                    PODSData.Handles.OrderFactorImgH.CData = cImage.OF_image;
                    if ~PODSData.Settings.Zoom.Active
                        PODSData.Handles.OrderFactorAxH.XLim = [0.5 cImage.Width+0.5];
                        PODSData.Handles.OrderFactorAxH.YLim = [0.5 cImage.Height+0.5];
                    end
                catch
                    PODSData.Handles.OrderFactorImgH.CData = EmptyImage;
                end
            end

            % change colormap to currently selected Order factor colormap
            PODSData.Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;

            % if ApplyMask toolbar state button set to true...
            if PODSData.Handles.ApplyMaskOrderFactor.Value == 1
                % ...then apply current mask by setting image AlphaData
                PODSData.Handles.OrderFactorImgH.AlphaData = cImage.bw;
            end

            if any(isvalid(PODSData.Handles.ObjectBoxes))
                delete(PODSData.Handles.ObjectBoxes);
                clear PODSData.Handles.ObjectBoxes
                PODSData.Handles.ObjectBoxes = gobjects(1,1);
            end

            if any(isvalid(PODSData.Handles.SelectedObjectBoxes))
                delete(PODSData.Handles.SelectedObjectBoxes);
                clear PODSData.Handles.SelectedObjectBoxes
                PODSData.Handles.SelectedObjectBoxes = gobjects(1,1);
            end

            % if ShowSelection toolbar state button is pressed
            if PODSData.Handles.ShowSelectionAverageIntensity.Value == 1

                switch PODSData.Settings.ObjectBoxType
                    case 'Boundary'
                        for ObjIdx = 1:cImage.nObjects
                            PODSData.Handles.fH.CurrentAxes = PODSData.Handles.AverageIntensityAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            PODSData.Handles.ObjectBoxes(ObjIdx,1) = plot(Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);
                            hold off
        
                            PODSData.Handles.fH.CurrentAxes = PODSData.Handles.OrderFactorAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            PODSData.Handles.ObjectBoxes(ObjIdx,2) = plot(Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);
                            hold off
                        end
                    case 'Box'
                        for ObjIdx = 1:cImage.nObjects
                            % plot expanded bounding boxes of each object...
                            % on intensity image
                            PODSData.Handles.ObjectBoxes(ObjIdx,1) = rectangle(PODSData.Handles.AverageIntensityAxH,...
                                'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                                'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'HitTest','On',...
                                'PickableParts','All',...
                                'Tag','ObjectBox',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'Visible','On',...
                                'UserData',ObjIdx);
                            % and on mask image
                            PODSData.Handles.ObjectBoxes(ObjIdx,2) = rectangle(PODSData.Handles.OrderFactorAxH,...
                                'Position',ExpandBoundingBox(cImage.Object(ObjIdx).BoundingBox,4),...
                                'EdgeColor',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'HitTest','On',...
                                'PickableParts','All',...
                                'Tag','ObjectBox',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'Visible','On',...
                                'UserData',ObjIdx);
                        end
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
            UpdateThreshholdSlider();

            if PODSData.Handles.ShowAsOverlayAzimuthImage.Value == 1
                try
                    %OverlayIntensity = imadjust(cImage.I,cImage.PrimaryIntensityDisplayLimits);
                    %OverlayIntensity = imadjust(cImage.I);
                    %OverlayIntensity = imadjust(cImage.I);
                    %OverlayIntensity = Scale0To1(imadjust(cImage.I.*cImage.OF_image));
                    
                    %Enhanced = adapthisteq(cImage.I,"Distribution","exponential");
                    %OverlayIntensity = imadjust(Enhanced,stretchlim(Enhanced));

                    % most predictable is just using 'I'
                    OverlayIntensity = cImage.I;
                    AzimuthRGB = MaskRGB(MakeAzimuthRGB(cImage.AzimuthImage,PODSData.Settings.AzimuthColormap),OverlayIntensity);
                    PODSData.Handles.AzimuthImgH.CData = AzimuthRGB;
                catch
                    PODSData.Handles.AzimuthImgH.CData = EmptyImage;
                    disp('Warning: Error displaying azimuth-intensity composite image')
                end
            else
                try
                    PODSData.Handles.AzimuthImgH.CData = cImage.AzimuthImage;
                    PODSData.Handles.AzimuthAxH.CLim = [-pi,pi]; % very important to set for proper display colors
                    if ~PODSData.Settings.Zoom.Active
                        PODSData.Handles.AzimuthAxH.XLim = [0.5 cImage.Width+0.5];
                        PODSData.Handles.AzimuthAxH.YLim = [0.5 cImage.Height+0.5];
                    end
                catch
                    PODSData.Handles.AzimuthImgH.CData = EmptyImage;
                    disp('Warning: Error displaying azimuth image')
                end
            end
            
            % create 'circular' colormap by vertically concatenating
            %   2 hsv maps and make it current
            tempmap = PODSData.Settings.AzimuthColormap;
            circmap = vertcat(tempmap,tempmap);

            colormap(PODSData.Handles.AzimuthAxH,circmap);
            
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if PODSData.Handles.ApplyMaskAzimuthImage.Value == 1
                try
                    PODSData.Handles.AzimuthImgH.AlphaData = cImage.bw;
                catch
                    PODSData.Handles.AzimuthImgH.AlphaData = 1;
                    disp('Warning: Error applying mask to azimuth image')
                end
            end

            try
                delete(PODSData.Handles.AzimuthLines);
            catch
                disp('Warning: Could not delete Azimuth lines')
            end

            try
                LineMask = cImage.bw;
                LineScaleDown = PODSData.Settings.AzimuthScaleDownFactor;
    
                if LineScaleDown > 1
                    ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
                    LineMask = LineMask & logical(ScaleDownMask);
                end

                [y,x] = find(LineMask==1);
                theta = cImage.AzimuthImage(LineMask);
                rho = cImage.OF_image(LineMask);
    
                ColorMode = PODSData.Settings.AzimuthColorMode;
                LineWidth = PODSData.Settings.AzimuthLineWidth;
                LineAlpha = PODSData.Settings.AzimuthLineAlpha;
                LineScale = PODSData.Settings.AzimuthLineScale;
    
                switch ColorMode
                    case 'Magnitude'
                        Colormap = PODSData.Settings.OrderFactorColormap;
                    case 'Direction'
                        Colormap = circmap;
                    case 'Mono'
                        Colormap = [1 1 1];
                end
    
                PODSData.Handles.AzimuthLines = QuiverPatch2(PODSData.Handles.AverageIntensityAxH,...
                    x,...
                    y,...
                    theta,...
                    rho,...
                    ColorMode,...
                    Colormap,...
                    LineWidth,...
                    LineAlpha,...
                    LineScale);
            catch
                disp('Warning: Error displaying azimuth sticks')
            end

            % testing below
            drawnow
            % end testing

        case 'Plots'
            %% Scatter and swarm plots
            try
                delete(PODSData.Handles.ScatterPlotAxH.Children)
            catch
                % do nothing
            end
            
            PODSData.Handles.hScatterPlot = PlotGroupScatterPlot(source,PODSData.Handles.ScatterPlotAxH);

            try
                delete(PODSData.Handles.SwarmPlotAxH.Children)
            catch
                % do nothing
            end
            
            switch PODSData.Settings.SwarmPlotGroupingType
                case 'Group'
                    % plot the swarm chart and save the plot handle
                    PODSData.Handles.hSwarmChart = PlotGroupSwarmChart(source,PODSData.Handles.SwarmPlotAxH);
                    PODSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Group";
                case 'Label'
                    % plot the swarm chart and save the plot handle
                    PODSData.Handles.hSwarmChart = PlotSwarmChartByLabels(source,PODSData.Handles.SwarmPlotAxH);
                    PODSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Label";
                case 'Both'
                    PODSData.Handles.hSwarmChart = PlotSwarmChartByGroupAndLabels(source,PODSData.Handles.SwarmPlotAxH);
                    PODSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Group (Label)";
            end
            
            PODSData.Handles.SwarmPlotAxH.Title.String = ExpandVariableName(PODSData.Settings.SwarmPlotYVariable);
            
            PODSData.Handles.SwarmPlotAxH.YAxis.Label.String = ExpandVariableName(PODSData.Settings.SwarmPlotYVariable);            
            
        case 'View Objects'
            %% Object Viewer
            try
                % get handle to the current object
                cObject = cImage.CurrentObject;
                % get object mask image, restrictive -> does not include nearby objects
                % within padded object bounding box
                RestrictedPaddedObjMask = cObject.RestrictedPaddedMaskSubImage;
                % pad the object subarrayidx with 5 pixels per side
                PaddedSubarrayIdx = padSubarrayIdx(cObject.SubarrayIdx,5);
            catch
                disp('Warning: Error retrieving object data')
            end
            
            if any(isvalid(PODSData.Handles.ObjectIntensityPlotAxH.Children))
                delete(PODSData.Handles.ObjectIntensityPlotAxH.Children);
            end      

            try
                % initialize pixel-normalized intensity stack for curve fitting
                PaddedObjPixelNormIntensity = zeros([size(RestrictedPaddedObjMask),4]);
                % get pixel-normalized intensity stack for curve fitting
                PaddedObjPixelNormIntensity(:) = cObject.Parent.norm(PaddedSubarrayIdx{:},:);
                % calculate and plot object intensity curve fits
                PODSData.Handles.ObjectIntensityPlotAxH = PlotObjectIntensityProfile([0,pi/4,pi/2,3*(pi/4)],...
                    PaddedObjPixelNormIntensity,...
                    RestrictedPaddedObjMask,...
                    PODSData.Handles.ObjectIntensityPlotAxH);
            catch
                disp('Warning: Error displaying object sinusoidal intensity fit curves');
            end

            % display the (padded) intensity image of the object
            try
                PODSData.Handles.ObjectPolFFCImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
            catch
                disp('Warning: Error displaying object intensity image');
                PODSData.Handles.ObjectPolFFCImgH.CData = EmptyImage;
            end

            % display object binary image
            try
                PODSData.Handles.ObjectMaskImgH.CData = cObject.RestrictedPaddedMaskSubImage;
            catch
                disp('Warning: Error displaying object binary image');
                PODSData.Handles.ObjectMaskImgH.CData = EmptyImage;
            end
            
            try
                ObjectOFImg = cObject.PaddedOFSubImage;
                PODSData.Handles.ObjectOFImgH.CData = ObjectOFImg;
            catch
                disp('Warning: Error displaying object OF image');
                PODSData.Handles.ObjectOFImgH.CData = EmptyImage;
            end

            % display the (padded) intensity image of the object
            try
                PODSData.Handles.ObjectAzimuthOverlayImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
            catch
                disp('Warning: Error displaying object intensity image');
                PODSData.Handles.ObjectAzimuthOverlayImgH.CData = EmptyImage;
            end

            if any(isvalid(PODSData.Handles.ObjectAzimuthLines))
                delete(PODSData.Handles.ObjectAzimuthLines);
            end

            try
                delete(PODSData.Handles.ObjectAzimuthLines);
            catch
                disp('Warning: Could not delete Object Azimuth lines');
            end

            try
                % create 'circular' colormap by vertically concatenating 2 hsv maps
                tempmap = hsv;
                circmap = vertcat(tempmap,tempmap);
                % get padded object Azimuth image
                PaddedAzimuthImage = cObject.PaddedAzimuthSubImage;
                % get y and x coordinates from 'On' pixels in the object mask image
                [y,x] = find(RestrictedPaddedObjMask==1);
                % theta (direction) values are azimuth values from the pixels above
                theta = PaddedAzimuthImage(RestrictedPaddedObjMask);
                % rho (magnitude) values come from the OF image
                rho = ObjectOFImg(RestrictedPaddedObjMask);
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
                % preallocate line colors array
                PatchColors = zeros(nLines,3);
                % transparency of the azimuth lines
                LineAlpha = PODSData.Settings.AzimuthLineAlpha;
                % mode by which to color the lines
                ColorMode = PODSData.Settings.AzimuthColorMode;
    
                % calculate colors for each line based on ColorMode
                switch ColorMode
                    case 'Magnitude'
                        % colormap used to color azimuth lines by magnitude
                        MagnitudeColorMap = PODSData.Settings.OrderFactorColormap;
                        % number of colors in the map (for indexing)
                        nColors = length(MagnitudeColorMap);
                        % determine the colormap idx of each line based on its pixel's OF (range 0-1)
                        ColorIdx = round(rho.*(nColors-1))+1;
                        % preallocate the line colors array
                        PatchColors = zeros(nLines,3);
                        % fill the array with colors based on idxs in ColorIdx
                        PatchColors(:,:) = MagnitudeColorMap(ColorIdx,:);
                    case 'Direction'
                        % determine how many colors in the full map
                        nColors = length(circmap);
                        % get the region of the circular map from
                        % -pi/2 to pi/2 (the range of our values)
                        % (pi/2)/(2pi) = 0.25
                        % (3pi/2)/(2pi) = 0.75
                        halfcircmap = circmap(0.25*nColors:0.75*nColors,:);
                        % how many colors in the truncated map
                        nColors = length(halfcircmap);
                        % normalize our theta values and convert to idxs
                        % theta is in the range [-pi/2,pi/2]...
                        % (theta+pi/2)./(pi) will scale theta to 0-1...
                        % thus: 0 -> -pi/2, 1 -> pi/2
                        ColorIdxsNorm = round(((theta+pi/2)./(pi))*(nColors-1))+1;
                        % preallocate the line colors array
                        PatchColors = zeros(nLines,3);
                        % fill the array with colors based on idxs in ColorIdxsNorm
                        PatchColors(:,:) = halfcircmap(ColorIdxsNorm,:);
                    case 'Mono'
                        MonoColor = [1 1 1];
                        % replicate the MonoColor nLines times since each line is the same color
                        PatchColors = repmat(MonoColor,nLines,1);
                end
    
                PODSData.Handles.ObjectAzimuthLines = QuiverPatch(PODSData.Handles.ObjectAzimuthOverlayAxH,...
                    xnew,ynew,...
                    PatchColors,...
                    PODSData.Settings.AzimuthLineWidth,...
                    LineAlpha);
                PODSData.Handles.ObjectAzimuthOverlayAxH.XLim = PODSData.Handles.ObjectPolFFCAxH.XLim;
                PODSData.Handles.ObjectAzimuthOverlayAxH.YLim = PODSData.Handles.ObjectPolFFCAxH.YLim;
            catch
                disp('Warning: Error displaying object azimuth sticks');
                % because setting the axes limits will change lim mode to 'manual', we need to set the limits
                % if the sticks don't display properly in the try statement above. Otherwise, the limits of 
                % the axes could be larger than the CData of the image object it holds
                PODSData.Handles.ObjectAzimuthOverlayAxH.XLim = PODSData.Handles.ObjectPolFFCAxH.XLim;
                PODSData.Handles.ObjectAzimuthOverlayAxH.YLim = PODSData.Handles.ObjectPolFFCAxH.YLim;
            end

            try
                % initialize stack-normalized intensity stack for display
                PaddedObjNormIntensity = zeros([size(RestrictedPaddedObjMask),4]);
                % get stack-normalized intensity stack for display
                PaddedObjNormIntensity(:) = cObject.Parent.pol_ffc(PaddedSubarrayIdx{:},:);
                % normalize to stack maximum
                PaddedObjNormIntensity = PaddedObjNormIntensity./max(max(max(PaddedObjNormIntensity)));
                % show stack-normalized object intensity stack
                PODSData.Handles.ObjectNormIntStackImgH.CData = [PaddedObjNormIntensity(:,:,1),...
                    PaddedObjNormIntensity(:,:,2),...
                    PaddedObjNormIntensity(:,:,3),...
                    PaddedObjNormIntensity(:,:,4)];
            catch
                disp('Warning: Error displaying stack-normalized object intensity')
                PODSData.Handles.ObjectNormIntStackImgH.CData = repmat(EmptyImage,1,4);
            end

            drawnow
             
    end

    function UpdateSliders()
        try
            % only update the sliders if the intensity display setting is active
            if strcmp(PODSData.Settings.CurrentImageOperation,'Intensity Display')
                PODSData.Handles.PrimaryIntensitySlider.Value = cImage.PrimaryIntensityDisplayLimits;
                PODSData.Handles.ReferenceIntensitySlider.Value = cImage.ReferenceIntensityDisplayLimits;
            end
        catch
            PODSData.Handles.PrimaryIntensitySlider.Value = [0 1];
            PODSData.Handles.ReferenceIntensitySlider.Value = [0 1];
        end
    end

    function UpdateAverageIntensity()
        try
            if ~PODSData.Settings.Zoom.Active
                PODSData.Handles.AverageIntensityAxH.XLim = [0.5 cImage.Width+0.5];
                PODSData.Handles.AverageIntensityAxH.YLim = [0.5 cImage.Height+0.5];
            end
    
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if PODSData.Handles.ApplyMaskAverageIntensity.Value == 1
                PODSData.Handles.AverageIntensityImgH.AlphaData = cImage.bw;
            end
    
            % make avg intensity/reference composite RGB, if applicable
            if cImage.ReferenceImageLoaded
                % truecolor composite overlay
                if PODSData.Handles.ShowReferenceImageAverageIntensity.Value == 1
                    Map1 = PODSData.Settings.IntensityColormap;
                    Map2 = PODSData.Settings.ReferenceColormap;
                    try
                        PODSData.Handles.AverageIntensityImgH.CData = ...
                            CompositeRGB(Scale0To1(cImage.I),Map1,cImage.PrimaryIntensityDisplayLimits,...
                            Scale0To1(cImage.ReferenceImage),Map2,cImage.ReferenceIntensityDisplayLimits);
                        PODSData.Handles.AverageIntensityAxH.CLim = [0 255];
                    catch
                        disp('Warning: Failed to make composite RGB')
                    end
                else % just show avg intensity
                    try
                        PODSData.Handles.AverageIntensityImgH.CData = Scale0To1(cImage.I);
                        PODSData.Handles.AverageIntensityAxH.CLim = cImage.PrimaryIntensityDisplayLimits;
                    catch
                        PODSData.Handles.AverageIntensityImgH.CData = EmptyImage;
                    end
                end
            else % just show avg intensity
                try
                    PODSData.Handles.AverageIntensityImgH.CData = Scale0To1(cImage.I);
                    PODSData.Handles.AverageIntensityAxH.CLim = cImage.PrimaryIntensityDisplayLimits;
                catch
                    PODSData.Handles.AverageIntensityImgH.CData = EmptyImage;
                end
            end
        catch
            PODSData.Handles.AverageIntensityImgH.CData = EmptyImage;
        end
    end

    function UpdateThreshholdSlider()
        if PODSData.Settings.ManualThreshEnabled
            try
                [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.EnhancedImg);
                PODSData.Handles.ThreshBar.XData = cImage.IntensityBinCenters;
                PODSData.Handles.ThreshBar.YData = cImage.IntensityHistPlot;
            catch
                disp('Warning: Failed to update threshold slider with currently selected image data');
            end

            try
                PODSData.Handles.CurrentThresholdLine.Value = cImage.level;
                PODSData.Handles.CurrentThresholdLine.Label = {[PODSData.Settings.ThreshStatisticName,' = ',num2str(PODSData.Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Warning: Error while moving thresh line...')
                PODSData.Handles.CurrentThresholdLine.Value = 0;
                PODSData.Handles.CurrentThresholdLine.Label = {[PODSData.Settings.ThreshStatisticName,' = ',num2str(PODSData.Handles.CurrentThresholdLine.Value)]};
            end
        else
            try
                [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.I);
                PODSData.Handles.ThreshBar.XData = cImage.IntensityBinCenters;
                PODSData.Handles.ThreshBar.YData = cImage.IntensityHistPlot;
            catch
                disp('Warning: Failed to update threshold slider with currently selected image data');
            end

            PODSData.Handles.CurrentThresholdLine.Value = 0;
            PODSData.Handles.CurrentThresholdLine.Label = {['']};

        end
    end

end