function [] = UpdateImages(source)
    
    % get main data structure
    PODSData = guidata(source);
    
    % get gui handles
    Handles = PODSData.Handles;

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
            %% FILES
            try
                for i = 1:4
                    Handles.FFCImgH(i).CData = FFCData.cal_norm(:,:,i);
                end
            catch
                UpdateLog3(source,'WARNING: No FFC Images found for this group, try loading them now','append');
                for i = 1:4
                    Handles.FFCImgH(i).CData = EmptyImage;
                end
            end

            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                end                
            end
        case 'FFC'
            %% FFC
            % flat-field corrected images
            try
                images = cImage.pol_ffc_normalizedbystack;
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = EmptyImage;
                end                      
            end

            % raw data images, normalized to stack max
            try
                images = cImage.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                end
                clear images
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                end
            end
            
        case 'Generate Mask'
            %% MASKING STEPS
            try
                % average FF-corrected intensity
                Handles.MStepsImgH(1).CData = cImage.I;
                
                % opened image (BG)
                Handles.MStepsImgH(2).CData = cImage.BGImg;

                % BG-subtracted image (tophat filtered)
                Handles.MStepsImgH(3).CData = cImage.BGSubtractedImg;
                Handles.MStepsAxH(3).CLim = [min(min(cImage.BGSubtractedImg)) max(max(cImage.BGSubtractedImg))];

                % enhanced image
                Handles.MStepsImgH(4).CData = cImage.EnhancedImg;
                Handles.MStepsAxH(4).CLim = [min(min(cImage.EnhancedImg)) max(max(cImage.EnhancedImg))];
            catch
                Handles.MStepsImgH(1).CData = EmptyImage;
                Handles.MStepsImgH(2).CData = EmptyImage;
                Handles.MStepsImgH(3).CData = EmptyImage;
                Handles.MStepsImgH(4).CData = EmptyImage;        
            end
            
            % mask
            try
                Handles.MaskImgH.CData = cImage.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            UpdateThreshholdSlider();          

        case 'View/Adjust Mask'
            %% VIEW MASK
            UpdateSliders();
            
            % Mask
            try
                Handles.MaskImgH.CData = cImage.bw;
                if ~PODSData.Settings.Zoom.Active
                    Handles.MaskAxH.XLim = [0.5 cImage.Width+0.5];
                    Handles.MaskAxH.YLim = [0.5 cImage.Height+0.5];
                end
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            if any(isvalid(Handles.ObjectBoxes))
                delete(Handles.ObjectBoxes);
                clear Handles.ObjectBoxes
                Handles.ObjectBoxes = gobjects(1,1);
            end

            if any(isvalid(Handles.SelectedObjectBoxes))
                delete(Handles.SelectedObjectBoxes);
                clear Handles.SelectedObjectBoxes
                Handles.SelectedObjectBoxes = gobjects(1,1);
            end

            % if ShowSelection toolbar state button is pressed,
            % show object selection boxes
            if PODSData.Handles.ShowSelectionAverageIntensity.Value == 1
                switch PODSData.Settings.ObjectBoxType
                    case 'Boundary'
                        for ObjIdx = 1:cImage.nObjects
                            Handles.fH.CurrentAxes = Handles.AverageIntensityAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            Handles.ObjectBoxes(ObjIdx,1) = plot(Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);
                            hold off
        
                            Handles.fH.CurrentAxes = Handles.MaskAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            Handles.ObjectBoxes(ObjIdx,2) = plot(Boundary(:,2),...
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
                            Handles.ObjectBoxes(ObjIdx,1) = rectangle(Handles.AverageIntensityAxH,...
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
                            Handles.ObjectBoxes(ObjIdx,2) = rectangle(Handles.MaskAxH,...
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

                        Handles.fH.CurrentAxes = Handles.AverageIntensityAxH;
                        hold on

                        if ~isempty(UnselectedVertices)
                            Handles.ObjectBoxes = patch(Handles.AverageIntensityAxH,...
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
                            Handles.ObjectBoxes.LineWidth = 1;
                        end
                        if ~isempty(SelectedVertices)
                            Handles.SelectedObjectBoxes = patch(Handles.AverageIntensityAxH,...
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
                            Handles.SelectedObjectBoxes.LineWidth = 2;
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
            try
                Handles.OrderFactorImgH.CData = cImage.OF_image;
                if ~PODSData.Settings.Zoom.Active
                    Handles.OrderFactorAxH.XLim = [0.5 cImage.Width+0.5];
                    Handles.OrderFactorAxH.YLim = [0.5 cImage.Height+0.5];
                end
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

            if any(isvalid(Handles.ObjectBoxes))
                delete(Handles.ObjectBoxes);
                clear Handles.ObjectBoxes
                Handles.ObjectBoxes = gobjects(1,1);
            end

            if any(isvalid(Handles.SelectedObjectBoxes))
                delete(Handles.SelectedObjectBoxes);
                clear Handles.SelectedObjectBoxes
                Handles.SelectedObjectBoxes = gobjects(1,1);
            end

            % if ShowSelection toolbar state button is pressed
            if PODSData.Handles.ShowSelectionAverageIntensity.Value == 1

                switch PODSData.Settings.ObjectBoxType
                    case 'Boundary'
                        for ObjIdx = 1:cImage.nObjects
                            Handles.fH.CurrentAxes = Handles.AverageIntensityAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            Handles.ObjectBoxes(ObjIdx,1) = plot(Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);
                            hold off
        
                            Handles.fH.CurrentAxes = Handles.OrderFactorAxH;
                            hold on
                            Boundary = cImage.Object(ObjIdx).Boundary;
                            Handles.ObjectBoxes(ObjIdx,2) = plot(Boundary(:,2),...
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
                            Handles.ObjectBoxes(ObjIdx,1) = rectangle(Handles.AverageIntensityAxH,...
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
                            Handles.ObjectBoxes(ObjIdx,2) = rectangle(Handles.OrderFactorAxH,...
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
            
            try
                Handles.AzimuthImgH.CData = cImage.AzimuthImage;
                Handles.AzimuthAxH.CLim = [-pi,pi]; % very important to set for proper display colors
                if ~PODSData.Settings.Zoom.Active
                    Handles.AzimuthAxH.XLim = [0.5 cImage.Width+0.5];
                    Handles.AzimuthAxH.YLim = [0.5 cImage.Height+0.5];
                end
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

            Handles.AzimuthLines = QuiverPatch2(Handles.AverageIntensityAxH,...
                x,...
                y,...
                theta,...
                rho,...
                ColorMode,...
                Colormap,...
                LineWidth,...
                LineAlpha,...
                LineScale);

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
            
            switch PODSData.Settings.SwarmPlotGroupingType
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
            
            Handles.SwarmPlotAxH.Title.String = ExpandVariableName(PODSData.Settings.SwarmPlotYVariable);
            
            Handles.SwarmPlotAxH.YAxis.Label.String = ExpandVariableName(PODSData.Settings.SwarmPlotYVariable);
             
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
            %% Object Viewer
            cObject = cImage.CurrentObject;

            if any(isvalid(Handles.ObjectIntensityPlotAxH.Children))
                delete(Handles.ObjectIntensityPlotAxH.Children);
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
%             [ny,nx] = size(ObjectOFImg);
% 
%             y = 1:1:ny;
%             x = 1:1:nx;
% 
%             [X,Y] = meshgrid(x,y);

%             yq = 1:0.25:ny;
%             xq = 1:0.25:nx;
% 
%             [Xq,Yq] = meshgrid(xq,yq);
%             ObjectOFImg_Interp = interp2(X,Y,ObjectOFImg,Xq,Yq,'cubic');
            
            try
                Handles.ObjectOFImgH.CData = ObjectOFImg;
            catch
                disp('Warning: Error displaying object OF image');
                Handles.ObjectOFImgH.CData = EmptyImage;
            end

% object azimuth overlay

            % display the (padded) intensity image of the object
            try
                Handles.ObjectAzimuthOverlayImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
            catch
                disp('Warning: Error displaying object intensity image');
                Handles.ObjectAzimuthOverlayImgH.CData = EmptyImage;
            end

            if any(isvalid(Handles.ObjectAzimuthLines))
                delete(Handles.ObjectAzimuthLines);
            end

%             try
%                 delete(Handles.ObjectAzimuthLines);
%             catch
%                 disp('Warning: Could not delete Object Azimuth lines');
%             end

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


            Handles.ObjectAzimuthLines = QuiverPatch(Handles.ObjectAzimuthOverlayAxH,...
                xnew,ynew,...
                PatchColors,...
                PODSData.Settings.AzimuthLineWidth,...
                LineAlpha);
            Handles.ObjectAzimuthOverlayAxH.XLim = Handles.ObjectPolFFCAxH.XLim;
            Handles.ObjectAzimuthOverlayAxH.YLim = Handles.ObjectPolFFCAxH.YLim;

% end object azimuth lines
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

            drawnow
             
    end

    function UpdateSliders()
        % only update the sliders if the intensity display setting is active
        if strcmp(PODSData.Settings.CurrentImageOperation,'Intensity Display')
            PODSData.Handles.PrimaryIntensitySlider.Value = cImage.PrimaryIntensityDisplayLimits;
            PODSData.Handles.ReferenceIntensitySlider.Value = cImage.ReferenceIntensityDisplayLimits;
        end
    end

    function UpdateAverageIntensity()
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

    %update PODSData structure with updated Handles
    PODSData.Handles = Handles;
    guidata(PODSData.Handles.fH,PODSData);

end