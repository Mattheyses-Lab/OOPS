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

        case 'Mask'
            %% VIEW MASK
            %UpdateSliders();
            
            % display mask image
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
                    % simple lines showing the boundaries
                    case 'Boundary'

                        for ObjIdx = 1:cImage.nObjects

                            % new method below (using primitive lines instead of plot()
                            % retrieve the boundary coordinates
                            Boundary = cImage.Object(ObjIdx).SimplifiedBoundary;

                            PODSData.Handles.ObjectBoxes(ObjIdx,1) = line(...
                                PODSData.Handles.AverageIntensityAxH,...
                                Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);

                            PODSData.Handles.ObjectBoxes(ObjIdx,2) = line(...
                                PODSData.Handles.MaskAxH,...
                                Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);
                        end

                    % simple rectangles
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
                    % in development - various methods
                    case 'Patch'

                        % %% using patch objects
                        % % plotting obj patches with faces/vertices
                        % % (we could also pass in the object boundary coordinates as XData and YData)
                        % [SelectedFaces,...
                        %     SelectedVertices,...
                        %     SelectedCData,...
                        %     UnselectedFaces,...
                        %     UnselectedVertices,...
                        %     UnselectedCData...
                        %     ] = getObjectPatchData(cImage);
                        % 
                        % PODSData.Handles.fH.CurrentAxes = PODSData.Handles.AverageIntensityAxH;
                        % hold on
                        % 
                        % if ~isempty(UnselectedVertices)
                        %     PODSData.Handles.ObjectBoxes = patch(PODSData.Handles.AverageIntensityAxH,...
                        %         'Faces',UnselectedFaces,...
                        %         'Vertices',UnselectedVertices,...
                        %         'Tag','ObjectBox',...
                        %         'FaceVertexCData',UnselectedCData,...
                        %         'EdgeColor','Flat',...
                        %         'FaceColor','none',...
                        %         'HitTest','On',...
                        %         'ButtonDownFcn',@SelectSingleObjects,...
                        %         'PickableParts','all',...
                        %         'Interruptible','off');
                        %     PODSData.Handles.ObjectBoxes.LineWidth = 1;
                        % end
                        % if ~isempty(SelectedVertices)
                        %     PODSData.Handles.SelectedObjectBoxes = patch(PODSData.Handles.AverageIntensityAxH,...
                        %         'Faces',SelectedFaces,...
                        %         'Vertices',SelectedVertices,...
                        %         'Tag','ObjectBox',...
                        %         'FaceVertexCData',SelectedCData,...
                        %         'EdgeColor','Flat',...
                        %         'FaceAlpha',0.5,...
                        %         'FaceColor','Flat',...
                        %         'HitTest','On',...
                        %         'ButtonDownFcn',@SelectSingleObjects,...
                        %         'PickableParts','all',...
                        %         'Interruptible','off');
                        %     PODSData.Handles.SelectedObjectBoxes.LineWidth = 2;
                        % end
                        % hold off

                        %% using patch objects
                        % plotting obj patches with faces/vertices
                        % (we could also pass in the object boundary coordinates as XData and YData)
                        [AllVertices,...
                            AllCData,...
                            SelectedFaces,...
                            UnselectedFaces...
                            ] = getObjectPatchData2(cImage);

                        % change the current axes of the main window
                        PODSData.Handles.fH.CurrentAxes = PODSData.Handles.AverageIntensityAxH;

                        % hold on so we can preserve our images/other objects
                        hold on

                        % plot a patch object containing the unselected objects
                        PODSData.Handles.ObjectBoxes = patch(PODSData.Handles.AverageIntensityAxH,...
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
                        PODSData.Handles.ObjectBoxes.LineWidth = 1;

                        % plot a patch object containing the selected objects
                        PODSData.Handles.SelectedObjectBoxes = patch(PODSData.Handles.AverageIntensityAxH,...
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
                        PODSData.Handles.SelectedObjectBoxes.LineWidth = 2;

                        % remove the hold
                        hold off
                        
                end
            end
            
            UpdateAverageIntensity();            
            %UpdateThreshholdSlider();

            %drawnow

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
                    % stretchlim(OverlayIntensity)
                    % OverlayIntensity = imadjust(OverlayIntensity,stretchlim(OverlayIntensity));
                    OF = cImage.OF_image;
                    maxOF = max(max(OF));

                    OFRGB = ind2rgb(im2uint8(OF./maxOF),PODSData.Settings.OrderFactorColormap);
                    OFRGB = MaskRGB(OFRGB,OverlayIntensity);
                    PODSData.Handles.OrderFactorImgH.CData = OFRGB;
                    PODSData.Handles.OFCbar.Ticks = 0:0.1:1;
                    PODSData.Handles.OFCbar.TickLabels = round(linspace(0,maxOF,11),2);

                catch
                    PODSData.Handles.OrderFactorImgH.CData = EmptyImage;
                    PODSData.Handles.OFCbar.Ticks = 0:0.1:1;
                    PODSData.Handles.OFCbar.TickLabels = 0:0.1:1;
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
                    PODSData.Handles.OFCbar.Ticks = 0:0.1:1;
                    PODSData.Handles.OFCbar.TickLabels = 0:0.1:1;
                catch
                    PODSData.Handles.OrderFactorImgH.CData = EmptyImage;
                end
            end

            % show or hide the OF colorbar
            if PODSData.Handles.ShowColorbarOrderFactor.Value == 1
                PODSData.Handles.OFCbar.Visible = 'on';
            else
                PODSData.Handles.OFCbar.Visible = 'off';
            end

            % change colormap to currently selected Order factor colormap
            PODSData.Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;

            % if ApplyMask toolbar state button set to true...
            if PODSData.Handles.ApplyMaskOrderFactor.Value == 1
                % ...then apply current mask by setting image AlphaData
                PODSData.Handles.OrderFactorImgH.AlphaData = cImage.bw;

                % % testing below: applying the mask in a different way
                % PODSData.Handles.OrderFactorImgH.CData = cImage.MaskedOFImageRGB;
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

                            % new method below (using primitive lines instead of plot()
                            % retrieve the boundary coordinates
                            Boundary = cImage.Object(ObjIdx).SimplifiedBoundary;

                            PODSData.Handles.ObjectBoxes(ObjIdx,1) = line(...
                                PODSData.Handles.AverageIntensityAxH,...
                                Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);

                            PODSData.Handles.ObjectBoxes(ObjIdx,2) = line(...
                                PODSData.Handles.OrderFactorAxH,...
                                Boundary(:,2),...
                                Boundary(:,1),...
                                'Color',cImage.Object(ObjIdx).Label.Color,...
                                'LineWidth',cImage.Object(ObjIdx).SelectionBoxLineWidth,...
                                'Tag','ObjectBox',...
                                'HitTest','On',...
                                'ButtonDownFcn',@SelectObjectRectangles,...
                                'PickableParts','all',...
                                'UserData',ObjIdx);

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

            UpdateAverageIntensity();           
            drawnow

        case 'Azimuth'
            %% Azimuth
            %UpdateSliders();
            UpdateAverageIntensity();
            %UpdateThreshholdSlider();

            if PODSData.Handles.ShowAsOverlayAzimuth.Value == 1
                try

                    % no enhancement
                    OverlayIntensity = cImage.I;

                    % auto-stretch contrast
                    %OverlayIntensity = imadjust(OverlayIntensity,stretchlim(OverlayIntensity));

                    %overlay intensity-weighted-OF, auto-contrast adjusted
                    % OverlayIntensity = cImage.I .* cImage.OF_image;
                    % OverlayIntensity = imadjust(OverlayIntensity,stretchlim(OverlayIntensity));

                    % overlay intensity-weighted-OF, scaled to fall between 0 and 1
                    %OverlayIntensity = Scale0To1(cImage.I .* cImage.OF_image);
                   
                    % AzimuthRGB = MaskRGB(MakeAzimuthRGB(...
                    %     getAverageAzimuthImage(cImage.AzimuthImage),...
                    %     PODSData.Settings.AzimuthColormap),...
                    %     OverlayIntensity);

                    % AzimuthRGB = MaskRGB(MakeAzimuthRGB(...
                    %     cImage.AzimuthImage,...
                    %     PODSData.Settings.AzimuthColormap),...
                    %     OverlayIntensity);


                    % BEST WORKING HSV DISPLAY
                    % HSV image with H,S,V = azimuth,OF,intensity
                    Az = cImage.AzimuthImage;
                    Az(Az<0) = Az(Az<0)+pi;
                    Az = Az./pi;

                    OF = cImage.OF_image;
                    OF = OF./max(max(OF));

                    AzimuthRGB = makeHSVSpecial(Az,OF,OverlayIntensity,[]);

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

            % show or hide the azimuth colorbar
            if PODSData.Handles.ShowColorbarAzimuth.Value == 1
                set(PODSData.Handles.PhaseBarComponents,'Visible','on');
            else
                set(PODSData.Handles.PhaseBarComponents,'Visible','off');
            end

            % create 'circular' colormap by vertically concatenating
            %   2 hsv maps and make it current
            tempmap = PODSData.Settings.AzimuthColormap;
            circmap = vertcat(tempmap,tempmap);

            colormap(PODSData.Handles.AzimuthAxH,circmap);
            
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if PODSData.Handles.ApplyMaskAzimuth.Value == 1
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
            %drawnow
            % end testing

        case 'Plots'
            %% Scatter and swarm plots
            try
                delete(PODSData.Handles.ScatterPlotAxH.Children)
            catch
                % do nothing
            end
            
            try
                delete(PODSData.Handles.SwarmPlotAxH.Children)
            catch
                % do nothing
            end


            % if isempty(cImage)
            %     return
            % end

            PODSData.Handles.hScatterPlot = PlotGroupScatterPlot(source,...
                PODSData.Handles.ScatterPlotAxH,...
                PODSData.Settings.ScatterPlotLegendVisible,...
                PODSData.Settings.ScatterPlotBackgroundColor,...
                PODSData.Settings.ScatterPlotForegroundColor);


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
                % get object mask image, restricted -> does not include nearby objects
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
            
            % display object OF image
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
                delete(PODSData.Handles.ObjectMidlinePlot);
            catch
                disp('Warning: Could not delete object midline plot');
            end

            try
                delete(PODSData.Handles.ObjectBoundaryPlot);
            catch
                disp('Warning: Could not delete object boundary plot');
            end

            try
                % create 'circular' colormap by vertically concatenating 2 hsv maps
                tempmap = hsv;
                circmap = vertcat(tempmap,tempmap);

                LineMask = cObject.RestrictedPaddedMaskSubImage;
                LineScaleDown = PODSData.Settings.AzimuthScaleDownFactor;
    
                if LineScaleDown > 1
                    ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
                    LineMask = LineMask & logical(ScaleDownMask);
                end

                [y,x] = find(LineMask==1);
                theta = cObject.PaddedAzimuthSubImage(LineMask);
                rho = cObject.PaddedOFSubImage(LineMask);
    
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

                % plot pixel azimuth sticks for the object
                PODSData.Handles.ObjectAzimuthLines = QuiverPatch2(PODSData.Handles.ObjectAzimuthOverlayAxH,...
                    x,...
                    y,...
                    theta,...
                    rho,...
                    ColorMode,...
                    Colormap,...
                    LineWidth,...
                    LineAlpha,...
                    LineScale);


                objectPaddedSize = size(cObject.RestrictedPaddedMaskSubImage);

                PODSData.Handles.ObjectAzimuthOverlayAxH.YLim = [0.5 objectPaddedSize(1)+0.5];
                PODSData.Handles.ObjectAzimuthOverlayAxH.XLim = [0.5 objectPaddedSize(2)+0.5];
                
            catch ME
                msg = getReport(ME);
                warning(['Error displaying object azimuth sticks: ', msg]);
                % because setting the axes limits will change lim mode to 'manual', we need to set the limits
                % if the sticks don't display properly in the try statement above. Otherwise, the limits of 
                % the axes could be larger than the CData of the image object it holds
                PODSData.Handles.ObjectAzimuthOverlayAxH.XLim = PODSData.Handles.ObjectPolFFCAxH.XLim;
                PODSData.Handles.ObjectAzimuthOverlayAxH.YLim = PODSData.Handles.ObjectPolFFCAxH.YLim;
            end

            % retrieve the object midline coordinates
            Midline = cObject.Midline;
            % if not empty...
            if ~isempty(Midline)
                % then attempt to plot the midline coordinates
                try
                    % plot as a primitive line
                    PODSData.Handles.ObjectMidlinePlot = line(PODSData.Handles.ObjectAzimuthOverlayAxH,...
                        'XData',Midline(:,1),...
                        'YData',Midline(:,2),...
                        'Marker','none',...
                        'LineStyle','-',...
                        'LineWidth',2,...
                        'Color',[0 0 0]);
                catch ME
                    UpdateLog3(source,['Warning: Error displaying object midline: ', ME.message],'append');
                    % reset the axes limits to match the object image size
                    PODSData.Handles.ObjectAzimuthOverlayAxH.XLim = PODSData.Handles.ObjectPolFFCAxH.XLim;
                    PODSData.Handles.ObjectAzimuthOverlayAxH.YLim = PODSData.Handles.ObjectPolFFCAxH.YLim;
                end
            end


            
            % try and plot the object boundary
            try
                % get the object boundary coordinates w.r.t. the padded intensity image
                paddedBoundary = cObject.PaddedSubIdxBoundary;

                PODSData.Handles.ObjectBoundaryPlot = line(PODSData.Handles.ObjectPolFFCAxH,...
                    paddedBoundary(:,2),...
                    paddedBoundary(:,1),...
                    'Color',cObject.Label.Color,...
                    'LineWidth',2);
            catch ME
                msg = getReport(ME);
                warning(['Error displaying object boundary: ', msg]);
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
                        PODSData.Handles.AverageIntensityImgH.CData = EmptyImage;
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

end