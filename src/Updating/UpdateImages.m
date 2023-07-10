function [] = UpdateImages(source,varargin)
    
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
            %% FILES
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
            %% FFC
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

            % raw data images, normalized to stack max
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
            %% VIEW MASK
            %UpdateSliders();
            
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

            if any(isvalid(OOPSData.Handles.ObjectBoxes))
                delete(OOPSData.Handles.ObjectBoxes);
                clear OOPSData.Handles.ObjectBoxes
                %OOPSData.Handles.ObjectBoxes = gobjects(1,1);
            end

            if any(isvalid(OOPSData.Handles.SelectedObjectBoxes))
                delete(OOPSData.Handles.SelectedObjectBoxes);
                clear OOPSData.Handles.SelectedObjectBoxes
                %OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);
            end

            % if ShowSelection toolbar state button is pressed,
            % show object selection boxes
            if OOPSData.Handles.ShowSelectionAverageIntensity.Value == 1 && ~isempty(cImage)
                switch OOPSData.Settings.ObjectBoxType
                    % simple rectangles
                    case 'Box'
                        [AllVertices,...
                            AllCData,...
                            SelectedFaces,...
                            UnselectedFaces...
                            ] = getObjectRectanglePatchData(cImage);

                        OOPSData.Handles.ObjectBoxes = gobjects(1,1);
                        OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);
                        % change the current axes of the main window
                        OOPSData.Handles.fH.CurrentAxes = OOPSData.Handles.AverageIntensityAxH;
                        % hold on so we can preserve our images/other objects
                        hold on
                        % plot a patch object containing the unselected objects
                        OOPSData.Handles.ObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',UnselectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceColor','none',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectRectanglePatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.ObjectBoxes.LineWidth = 1;
                        % plot a patch object containing the selected objects
                        OOPSData.Handles.SelectedObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',SelectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceAlpha',0.5,...
                            'FaceColor','Flat',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectRectanglePatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.SelectedObjectBoxes.LineWidth = 2;
                        % remove the hold
                        hold off
                    case 'Boundary'
                        %% using patch objects
                        % plotting obj patches with faces/vertices
                        % (we could also pass in the object boundary coordinates as XData and YData)
                        [AllVertices,...
                            AllCData,...
                            SelectedFaces,...
                            UnselectedFaces...
                            ] = getObjectPatchData(cImage);

                        OOPSData.Handles.ObjectBoxes = gobjects(1,1);
                        OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);
                        % change the current axes of the main window
                        OOPSData.Handles.fH.CurrentAxes = OOPSData.Handles.AverageIntensityAxH;
                        % hold on so we can preserve our images/other objects
                        hold on
                        % plot a patch object containing the unselected objects
                        OOPSData.Handles.ObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',UnselectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceColor','none',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectPatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.ObjectBoxes.LineWidth = 1;
                        % plot a patch object containing the selected objects
                        OOPSData.Handles.SelectedObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',SelectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceAlpha',0.5,...
                            'FaceColor','Flat',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectPatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.SelectedObjectBoxes.LineWidth = 2;
                        % remove the hold
                        hold off
                end
            end
            
            UpdateAverageIntensity();            


        case 'Order Factor'
            %% Order Factor Tab
            % Order Factor
            if OOPSData.Handles.ShowAsOverlayOrderFactor.Value == 1
                % show the OF-intensity composite image
                try
                    % get the average intensity image to use as an opacity mask
                    OverlayIntensity = cImage.I;
                    % get the raw OF image
                    OF = cImage.OF_image;
                    % depending on the selection state of the ScaleToMaxOrderFactor toolbar btn, get the value to scale to
                    if OOPSData.Handles.ScaleToMaxOrderFactor.Value == 1
                        maxOF = max(max(OF));
                    else
                        maxOF = 1;
                    end
                    % now get the scaled or unscaled OF-intensity RGB overlay
                    OFRGB = MaskRGB(ind2rgb(im2uint8(OF./maxOF),OOPSData.Settings.OrderFactorColormap),OverlayIntensity);
                    % set the image CData
                    OOPSData.Handles.OrderFactorImgH.CData = OFRGB;
                    % set the colorbar tick locations
                    OOPSData.Handles.OFCbar.Ticks = 0:0.1:1;
                    % set the colorbar tick labels
                    OOPSData.Handles.OFCbar.TickLabels = round(linspace(0,maxOF,11),2);
                    % reset the default axes limits if zoom is not active
                    if ~OOPSData.Settings.Zoom.Active
                        OOPSData.Handles.OrderFactorAxH.XLim = [0.5 cImage.Width+0.5];
                        OOPSData.Handles.OrderFactorAxH.YLim = [0.5 cImage.Height+0.5];
                    end
                catch
                    OOPSData.Handles.OrderFactorImgH.CData = EmptyImage;
                    OOPSData.Handles.OFCbar.Ticks = 0:0.1:1;
                    OOPSData.Handles.OFCbar.TickLabels = 0:0.1:1;
                    disp('Warning: Error displaying OF-intensity composite image')
                end
            else
                % show the unmasked OF image, scaled or unscaled
                try
                    % get the raw OF image
                    OF = cImage.OF_image;
                    % if ScaleToMaxOrderFactor toolbar btn is in the on state
                    if OOPSData.Handles.ScaleToMaxOrderFactor.Value == 1
                        maxOF = max(max(OF));
                    else
                        maxOF = 1;
                    end
                    % set the image CData
                    OOPSData.Handles.OrderFactorImgH.CData = OF./maxOF;
                    % set the colorbar tick locations
                    OOPSData.Handles.OFCbar.Ticks = 0:0.1:1;
                    % set the colorbar tick labels
                    OOPSData.Handles.OFCbar.TickLabels = round(linspace(0,maxOF,11),2);
                    % reset the default axes limits if zoom is not active
                    if ~OOPSData.Settings.Zoom.Active
                        OOPSData.Handles.OrderFactorAxH.XLim = [0.5 cImage.Width+0.5];
                        OOPSData.Handles.OrderFactorAxH.YLim = [0.5 cImage.Height+0.5];
                    end
                catch
                    OOPSData.Handles.OrderFactorImgH.CData = EmptyImage;
                    OOPSData.Handles.OFCbar.Ticks = 0:0.1:1;
                    OOPSData.Handles.OFCbar.TickLabels = 0:0.1:1;
                end
            end

            % show or hide the OF colorbar
            if OOPSData.Handles.ShowColorbarOrderFactor.Value == 1
                OOPSData.Handles.OFCbar.Visible = 'on';
            else
                OOPSData.Handles.OFCbar.Visible = 'off';
            end

            % change colormap to currently selected Order factor colormap
            OOPSData.Handles.OrderFactorAxH.Colormap = OOPSData.Settings.OrderFactorColormap;

            % if ApplyMask toolbar state button set to true...
            if OOPSData.Handles.ApplyMaskOrderFactor.Value == 1
                % ...then apply current mask by setting image AlphaData
                OOPSData.Handles.OrderFactorImgH.AlphaData = cImage.bw;

                % % testing below: applying the mask in a different way
                % OOPSData.Handles.OrderFactorImgH.CData = cImage.MaskedOFImageRGB;
            end

            if any(isvalid(OOPSData.Handles.ObjectBoxes))
                delete(OOPSData.Handles.ObjectBoxes);
                clear OOPSData.Handles.ObjectBoxes
                OOPSData.Handles.ObjectBoxes = gobjects(1,1);
            end

            if any(isvalid(OOPSData.Handles.SelectedObjectBoxes))
                delete(OOPSData.Handles.SelectedObjectBoxes);
                clear OOPSData.Handles.SelectedObjectBoxes
                OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);
            end

            % if ShowSelection toolbar state button is pressed
            if OOPSData.Handles.ShowSelectionAverageIntensity.Value == 1

                switch OOPSData.Settings.ObjectBoxType
                    case 'Box'
                        %% using patch objects
                        % plotting obj patches with faces/vertices
                        % (we could also pass in the object boundary coordinates as XData and YData)
                        [AllVertices,...
                            AllCData,...
                            SelectedFaces,...
                            UnselectedFaces...
                            ] = getObjectRectanglePatchData(cImage);

                        OOPSData.Handles.ObjectBoxes = gobjects(1,1);
                        OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);

                        % change the current axes of the main window
                        OOPSData.Handles.fH.CurrentAxes = OOPSData.Handles.AverageIntensityAxH;

                        % hold on so we can preserve our images/other objects
                        hold on

                        % plot a patch object containing the unselected objects
                        OOPSData.Handles.ObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',UnselectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceColor','none',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectRectanglePatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.ObjectBoxes.LineWidth = 1;

                        % plot a patch object containing the selected objects
                        OOPSData.Handles.SelectedObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',SelectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceAlpha',0.5,...
                            'FaceColor','Flat',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectRectanglePatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.SelectedObjectBoxes.LineWidth = 2;

                        % remove the hold
                        hold off
                    % in development - object boundaries
                    case 'Boundary'

                        %% using patch objects
                        % plotting obj patches with faces/vertices
                        % (we could also pass in the object boundary coordinates as XData and YData)
                        [AllVertices,...
                            AllCData,...
                            SelectedFaces,...
                            UnselectedFaces...
                            ] = getObjectPatchData(cImage);

                        OOPSData.Handles.ObjectBoxes = gobjects(1,1);
                        OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);

                        % change the current axes of the main window
                        OOPSData.Handles.fH.CurrentAxes = OOPSData.Handles.AverageIntensityAxH;

                        % hold on so we can preserve our images/other objects
                        hold on

                        % plot a patch object containing the unselected objects
                        OOPSData.Handles.ObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',UnselectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceColor','none',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectPatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.ObjectBoxes.LineWidth = 1;

                        % plot a patch object containing the selected objects
                        OOPSData.Handles.SelectedObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
                            'Faces',SelectedFaces,...
                            'Vertices',AllVertices,...
                            'Tag','ObjectBox',...
                            'FaceVertexCData',AllCData,...
                            'EdgeColor','Flat',...
                            'FaceAlpha',0.5,...
                            'FaceColor','Flat',...
                            'HitTest','On',...
                            'ButtonDownFcn',@SelectObjectPatches,...
                            'PickableParts','all',...
                            'Interruptible','off');
                        OOPSData.Handles.SelectedObjectBoxes.LineWidth = 2;

                        % remove the hold
                        hold off
                end
            end

            UpdateAverageIntensity();

            % this drawnow line might be causing issues
            %drawnow

        case 'Azimuth'
            %% Azimuth
            UpdateAverageIntensity();

            try
                if OOPSData.Handles.ShowAzimuthHSVOverlayAzimuth.Value == 1
                    % no enhancement
                    %OverlayIntensity = imadjust(cImage.I,stretchlim(cImage.I));
                    OverlayIntensity = cImage.I;

                    % BEST WORKING HSV DISPLAY
                    % HSV image with H,S,V = azimuth,OF,intensity
                    Az = cImage.AzimuthImage;
                    Az(Az<0) = Az(Az<0)+pi;
                    Az = Az./pi;

                    OF = cImage.OF_image;
                    OF = OF./max(max(OF));

                    AzimuthHSV = makeHSVSpecial(Az,OF,OverlayIntensity);

                    OOPSData.Handles.AzimuthImgH.CData = AzimuthHSV;
                elseif OOPSData.Handles.ShowAsOverlayAzimuth.Value == 1
                    I = cImage.I;
                    AzimuthRGB = cImage.AzimuthRGB;
                    AzimuthRGBMasked = MaskRGB(AzimuthRGB,I);
                    OOPSData.Handles.AzimuthImgH.CData = AzimuthRGBMasked;
                else
                    OOPSData.Handles.AzimuthImgH.CData = cImage.AzimuthImage;
                    OOPSData.Handles.AzimuthAxH.CLim = [-pi,pi]; % very important to set for proper display colors
                    if ~OOPSData.Settings.Zoom.Active
                        OOPSData.Handles.AzimuthAxH.XLim = [0.5 cImage.Width+0.5];
                        OOPSData.Handles.AzimuthAxH.YLim = [0.5 cImage.Height+0.5];
                    end
                end
            catch
                OOPSData.Handles.AzimuthImgH.CData = EmptyImage;
                disp('Warning: Error displaying azimuth image')
            end

            % show or hide the azimuth colorbar
            if OOPSData.Handles.ShowColorbarAzimuth.Value == 1
                set(OOPSData.Handles.PhaseBarComponents,'Visible','on');
            else
                set(OOPSData.Handles.PhaseBarComponents,'Visible','off');
            end

            
            azimuthMap = repmat(OOPSData.Settings.AzimuthColormap,2,1);
            OOPSData.Handles.AzimuthAxH.Colormap = azimuthMap;
            
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if OOPSData.Handles.ApplyMaskAzimuth.Value == 1
                try
                    OOPSData.Handles.AzimuthImgH.AlphaData = cImage.bw;
                catch
                    OOPSData.Handles.AzimuthImgH.AlphaData = 1;
                    disp('Warning: Error applying mask to azimuth image')
                end
            end

            try
                delete(OOPSData.Handles.AzimuthLines);
            catch
                disp('Warning: Could not delete Azimuth lines')
            end

            try
                LineMask = cImage.bw;
                LineScaleDown = OOPSData.Settings.AzimuthScaleDownFactor;
    
                if LineScaleDown > 1
                    ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
                    LineMask = LineMask & logical(ScaleDownMask);
                end

                [y,x] = find(LineMask==1);
                theta = cImage.AzimuthImage(LineMask);
                rho = cImage.OF_image(LineMask);
    
                ColorMode = OOPSData.Settings.AzimuthColorMode;
                LineWidth = OOPSData.Settings.AzimuthLineWidth;
                LineAlpha = OOPSData.Settings.AzimuthLineAlpha;
                LineScale = OOPSData.Settings.AzimuthLineScale;
    
                switch ColorMode
                    case 'Magnitude'
                        Colormap = OOPSData.Settings.OrderFactorColormap;
                    case 'Direction'
                        Colormap = azimuthMap;
                    case 'Mono'
                        Colormap = [1 1 1];
                end

                OOPSData.Handles.AzimuthLines = QuiverPatch2(OOPSData.Handles.AverageIntensityAxH,...
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

        case 'Plots'
            %% Scatter and swarm plots
            try
                delete(OOPSData.Handles.ScatterPlotAxH.Children)
            catch
                % do nothing
            end
            
            try
                delete(OOPSData.Handles.SwarmPlotAxH.Children)
            catch
                % do nothing
            end

            OOPSData.Handles.hScatterPlot = PlotGroupScatterPlot(source,...
                OOPSData.Handles.ScatterPlotAxH);


            switch OOPSData.Settings.SwarmPlotGroupingType
                case 'Group'
                    % plot the swarm chart and save the plot handle
                    OOPSData.Handles.hSwarmChart = PlotGroupSwarmChart(source,OOPSData.Handles.SwarmPlotAxH);
                    OOPSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Group";
                case 'Label'
                    % plot the swarm chart and save the plot handle
                    OOPSData.Handles.hSwarmChart = PlotSwarmChartByLabels(source,OOPSData.Handles.SwarmPlotAxH);
                    OOPSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Label";
                case 'Both'
                    OOPSData.Handles.hSwarmChart = PlotSwarmChartByGroupAndLabels(source,OOPSData.Handles.SwarmPlotAxH);
                    OOPSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Group (Label)";
            end
            
            OOPSData.Handles.SwarmPlotAxH.Title.String = ExpandVariableName(OOPSData.Settings.SwarmPlotYVariable);
            OOPSData.Handles.SwarmPlotAxH.YAxis.Label.String = ExpandVariableName(OOPSData.Settings.SwarmPlotYVariable);            
            
        case 'Polar Plots'
            %% polar histograms

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
            OOPSData.Handles.ImagePolarHistogram.Title = ['Image - Object ',ExpandVariableName(OOPSData.Settings.PolarHistogramVariable)];

            % set polar data and title for group polar histogram
            OOPSData.Handles.GroupPolarHistogram.polarData = [groupPolarData,groupPolarData+pi];
            OOPSData.Handles.GroupPolarHistogram.Title = ['Group - Object ',ExpandVariableName(OOPSData.Settings.PolarHistogramVariable)];

        case 'Objects'
            %% Object Viewer
            try
                % get handle to the current object
                cObject = cImage.CurrentObject;
                % get object mask image, restricted -> does not include nearby objects
                % within padded object bounding box
                RestrictedPaddedObjMask = cObject.paddedSubImage;
                % pad the object subarrayidx with 5 pixels per side
                PaddedSubarrayIdx = padSubarrayIdx(cObject.SubarrayIdx,5);
            catch
                disp('Warning: Error retrieving object data')
            end
            
            if any(isvalid(OOPSData.Handles.ObjectIntensityPlotAxH.Children))
                delete(OOPSData.Handles.ObjectIntensityPlotAxH.Children);
            end      

            try
                % initialize pixel-normalized intensity stack for curve fitting
                PaddedObjPixelNormIntensity = zeros([size(RestrictedPaddedObjMask),4]);
                % get pixel-normalized intensity stack for curve fitting
                PaddedObjPixelNormIntensity(:) = cObject.Parent.ffcFPMPixelNorm(PaddedSubarrayIdx{:},:);
                % calculate and plot object intensity curve fits
                OOPSData.Handles.ObjectIntensityPlotAxH = PlotObjectIntensityProfile([0,pi/4,pi/2,3*(pi/4)],...
                    PaddedObjPixelNormIntensity,...
                    RestrictedPaddedObjMask,...
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
                %OOPSData.Handles.ObjectMaskImgH.CData = cObject.RestrictedPaddedMaskSubImage;

                % testing below - use RGB instead of logical for easier exporting
                OOPSData.Handles.ObjectMaskImgH.CData = cObject.MaskImageRGB;

            catch
                disp('Warning: Error displaying object binary image');
                OOPSData.Handles.ObjectMaskImgH.CData = EmptyImage;
            end
            
            % display object OF image
            try
                ObjectOFImg = cObject.PaddedOFSubImage;
                OOPSData.Handles.ObjectOFImgH.CData = ObjectOFImg;
            catch
                disp('Warning: Error displaying object OF image');
                OOPSData.Handles.ObjectOFImgH.CData = EmptyImage;
            end

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

                azimuthMap = repmat(OOPSData.Settings.AzimuthColormap,2,1);

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
                rho = cObject.PaddedOFSubImage(LineMask);
                % settings controlling line appearance
                ColorMode = OOPSData.Settings.ObjectAzimuthColorMode;
                LineWidth = OOPSData.Settings.ObjectAzimuthLineWidth;
                LineAlpha = OOPSData.Settings.ObjectAzimuthLineAlpha;
                LineScale = OOPSData.Settings.ObjectAzimuthLineScale;

                %ColorMode = 'RelativeDirection';

                if strcmp(ColorMode,'RelativeDirection')
                    theta2 = cObject.MidlineRelativeAzimuthImage(LineMask);
                else
                    theta2 = [];
                end
    
                switch ColorMode
                    case 'Magnitude'
                        Colormap = OOPSData.Settings.OrderFactorColormap;
                    case {'Direction','RelativeDirection'}
                        Colormap = azimuthMap;
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
                % send error message to the OOPS log window
                % UpdateLog3(source,['Error displaying object azimuth sticks: ',ME.message],'append');
            end

            % retrieve the object midline coordinates
            Midline = cObject.Midline;
            % if not empty...
            if ~isempty(Midline) && ~any(isnan(Midline(:)))
                % then attempt to plot the midline coordinates
                try
                    % % plot as a primitive line
                    % OOPSData.Handles.ObjectMidlinePlot = line(OOPSData.Handles.ObjectAzimuthOverlayAxH,...
                    %     'XData',Midline(:,1),...
                    %     'YData',Midline(:,2),...
                    %     'Marker','none',...
                    %     'LineStyle','-',...
                    %     'LineWidth',2,...
                    %     'Color',[0 0 0]);

                    % plot as a primitive line
                    OOPSData.Handles.ObjectMidlinePlot = line(OOPSData.Handles.ObjectMaskAxH,...
                        'XData',Midline(:,1),...
                        'YData',Midline(:,2),...
                        'Marker','none',...
                        'LineStyle','-',...
                        'LineWidth',2,...
                        'Color',[0 0 0]);
                    
                catch ME
                    UpdateLog3(source,['Warning: Error displaying object midline: ', ME.message],'append');
                    % % reset the axes limits to match the object image size
                    % OOPSData.Handles.ObjectAzimuthOverlayAxH.XLim = OOPSData.Handles.ObjectPolFFCAxH.XLim;
                    % OOPSData.Handles.ObjectAzimuthOverlayAxH.YLim = OOPSData.Handles.ObjectPolFFCAxH.YLim;

                    OOPSData.Handles.ObjectMaskAxH.XLim = OOPSData.Handles.ObjectPolFFCAxH.XLim;
                    OOPSData.Handles.ObjectMaskAxH.YLim = OOPSData.Handles.ObjectPolFFCAxH.YLim;

                end
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
                msg = getReport(ME);
                warning(['Error displaying object boundary: ', msg]);
            end


            try
                % initialize stack-normalized intensity stack for display
                PaddedObjNormIntensity = zeros([size(RestrictedPaddedObjMask),4]);
                % get stack-normalized intensity stack for display
                PaddedObjNormIntensity(:) = cObject.Parent.ffcFPMStack(PaddedSubarrayIdx{:},:);
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

            % having a drawnow here can cause an long, unstoppable upddate queue
            % now testing if necessary
            %drawnow limitrate nocallbacks
             
    end

    function UpdateAverageIntensity()

        if isempty(cImage)
            OOPSData.Handles.AverageIntensityImgH.CData = EmptyImage;
            return
        end

        if ~OOPSData.Settings.Zoom.Active
            OOPSData.Handles.AverageIntensityAxH.XLim = [0.5 cImage.Width+0.5];
            OOPSData.Handles.AverageIntensityAxH.YLim = [0.5 cImage.Height+0.5];
        end

        % if ApplyMask state button set to true, apply current mask by setting AlphaData
        if OOPSData.Handles.ApplyMaskAverageIntensity.Value == 1
            OOPSData.Handles.AverageIntensityImgH.AlphaData = cImage.bw;
        end

        % make avg intensity/reference composite RGB, if applicable
        if cImage.ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value == 1
            % get the intensity-reference overlay RGB image
            OOPSData.Handles.AverageIntensityImgH.CData = ...
                CompositeRGB(Scale0To1(cImage.I),...
                OOPSData.Settings.IntensityColormap,...
                cImage.PrimaryIntensityDisplayLimits,...
                Scale0To1(cImage.ReferenceImage),...
                OOPSData.Settings.ReferenceColormap,...
                cImage.ReferenceIntensityDisplayLimits);
            % set axes CLim
            OOPSData.Handles.AverageIntensityAxH.CLim = [0 255];
        else % just show avg intensity
            OOPSData.Handles.AverageIntensityImgH.CData = Scale0To1(cImage.I);
            OOPSData.Handles.AverageIntensityAxH.CLim = cImage.PrimaryIntensityDisplayLimits;
        end

    end

end