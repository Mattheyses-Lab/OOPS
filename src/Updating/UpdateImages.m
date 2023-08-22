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
            
            UpdateAverageIntensityImage(source);            


        case 'Order'

            % update the Order image CData, colorbar, and AlphaData
            UpdateOrderImage(source);

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

            UpdateAverageIntensityImage(source);

            % this drawnow line might be causing issues
            %drawnow

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
            
            OOPSData.Handles.SwarmPlotAxH.Title.String = OOPSData.Settings.expandVariableName(OOPSData.Settings.SwarmPlotYVariable);
            OOPSData.Handles.SwarmPlotAxH.YAxis.Label.String = OOPSData.Settings.expandVariableName(OOPSData.Settings.SwarmPlotYVariable);            
            
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
            try
                ObjectOrderImg = cObject.PaddedOrderSubImage;
                OOPSData.Handles.ObjectOrderImgH.CData = ObjectOrderImg;
            catch
                disp('Warning: Error displaying object Order image');
                OOPSData.Handles.ObjectOrderImgH.CData = EmptyImage;
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
                % send error message to the OOPS log window
                % UpdateLog3(source,['Error displaying object azimuth sticks: ',ME.message],'append');
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

                OOPSData.Handles.ObjectMaskAxH.YLim = [0.5 objectPaddedSize(1)+0.5];
                OOPSData.Handles.ObjectMaskAxH.XLim = [0.5 objectPaddedSize(2)+0.5];

            catch ME
                UpdateLog3(source,['Warning: Error displaying object midline: ', ME.message],'append');
                % % reset the axes limits to match the object image size
                % OOPSData.Handles.ObjectAzimuthOverlayAxH.XLim = OOPSData.Handles.ObjectPolFFCAxH.XLim;
                % OOPSData.Handles.ObjectAzimuthOverlayAxH.YLim = OOPSData.Handles.ObjectPolFFCAxH.YLim;

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

            % get the idx of the custom stat to display based on the selected menu option
            statIdx = ismember(OOPSData.Settings.CurrentTab,OOPSData.Settings.CustomStatisticDisplayNames);
            % get the stat
            thisStat = OOPSData.Settings.CustomStatistics(statIdx);
            % get the name of the variable holding the stat
            statName = thisStat.StatisticName;
            % get the display name of the stat
            statDisplayName = thisStat.StatisticDisplayName;
            % get the output range of the stat
            statRange = thisStat.StatisticRange;

            % set the title of the axes/image
            OOPSData.Handles.CustomStatAxH.Title.String = statDisplayName;

            OOPSData.Handles.CustomStatAxH.UserData = thisStat;

            if OOPSData.Handles.ShowAsOverlayCustomStat.Value
                % show the Order-intensity composite image
                try
                    % get the average intensity image to use as an opacity mask
                    OverlayIntensity = cImage.I;
                    % get the raw Order image
                    statImage = cImage.(statName);
                    % depending on the selection state of the ScaleToMaxOrder toolbar btn, get the value to scale to
                    if OOPSData.Handles.ScaleToMaxCustomStat.Value == 1
                        statMax = max(max(statImage));
                    else
                        statMax = statRange(2);
                    end
                    % now get the scaled or unscaled Order-intensity RGB overlay
                    statImageRGB = MaskRGB(ind2rgb(im2uint8(statImage./statMax),OOPSData.Settings.OrderColormap),OverlayIntensity);
                    % set the image CData
                    OOPSData.Handles.CustomStatImgH.CData = statImageRGB;
                    % set the colorbar tick locations
                    OOPSData.Handles.CustomStatCbar.Ticks = 0:0.1:1;
                    % set the colorbar tick labels
                    OOPSData.Handles.CustomStatCbar.TickLabels = round(linspace(statRange(1),statMax,11),2);

                    % reset the default axes limits if zoom is not active
                    if ~OOPSData.Settings.Zoom.Active
                        OOPSData.Handles.CustomStatAxH.XLim = [0.5 cImage.Width+0.5];
                        OOPSData.Handles.CustomStatAxH.YLim = [0.5 cImage.Height+0.5];
                    end
                catch
                    OOPSData.Handles.CustomStatImgH.CData = EmptyImage;
                    OOPSData.Handles.CustomStatCbar.Ticks = 0:0.1:1;
                    OOPSData.Handles.CustomStatCbar.TickLabels = 0:0.1:1;
                    disp(['Warning: Error displaying ',statName,'-intensity composite image'])
                end
            else
                % show the unmasked image, scaled or unscaled
                try
                    % get the raw image
                    statImage = cImage.(statName);
                    % if ScaleToMaxCustomStat toolbar btn is on
                    if OOPSData.Handles.ScaleToMaxCustomStat.Value == 1
                        statMax = max(max(statImage));
                    else
                        statMax = statRange(2);
                    end
                    % set the image CData
                    OOPSData.Handles.CustomStatImgH.CData = statImage./statMax;
                    % set the colorbar tick locations
                    OOPSData.Handles.CustomStatCbar.Ticks = 0:0.1:1;
                    % set the colorbar tick labels
                    OOPSData.Handles.CustomStatCbar.TickLabels = round(linspace(statRange(1),statMax,11),2);
                    % reset the default axes limits if zoom is not active
                    if ~OOPSData.Settings.Zoom.Active
                        OOPSData.Handles.CustomStatAxH.XLim = [0.5 cImage.Width+0.5];
                        OOPSData.Handles.CustomStatAxH.YLim = [0.5 cImage.Height+0.5];
                    end
                catch
                    OOPSData.Handles.CustomStatImgH.CData = EmptyImage;
                    OOPSData.Handles.CustomStatCbar.Ticks = 0:0.1:1;
                    OOPSData.Handles.CustomStatCbar.TickLabels = 0:0.1:1;
                end
            end

            % show or hide the colorbar
            if OOPSData.Handles.ShowColorbarCustomStat.Value == 1
                OOPSData.Handles.CustomStatCbar.Visible = 'on';
            else
                OOPSData.Handles.CustomStatCbar.Visible = 'off';
            end

            % change colormap to currently selected Order colormap
            OOPSData.Handles.CustomStatAxH.Colormap = OOPSData.Settings.OrderColormap;

            % if ApplyMask toolbar state button set to true...
            if OOPSData.Handles.ApplyMaskCustomStat.Value == 1
                % ...then apply current mask by setting image AlphaData
                OOPSData.Handles.CustomStatImgH.AlphaData = cImage.bw;
            end

            % update the display of the average intensity image
            UpdateAverageIntensityImage(source);
             
    end

end