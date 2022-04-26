function [] = UpdateImages(source)
    %% Get relevant variables needed to update image data
    
    % get main data structure
    PODSData = guidata(source);
    
    % get gui handles
    Handles = PODSData.Handles;
    
    % get current group index
    cGroupIndex = PODSData.CurrentGroupIndex;
    % get current channel index
    cChannelIdx = PODSData.CurrentChannelIndex;
    % get current replicate index within group
    cImageIndex = PODSData.Group(cGroupIndex,cChannelIdx).CurrentImageIndex;
    
    % if multiple replicates selected, only update the gui to show the first one
    if length(cImageIndex) > 1
        cImageIndex = cImageIndex(1);
    end
    
    % get current replicate data structure, based on current group, image, and channel
    Replicate = PODSData.Group(cGroupIndex,cChannelIdx).Replicate(cImageIndex);
    % get FFC data for current group, separate data per channel
    FFCData = PODSData.Group(cGroupIndex,cChannelIdx).FFCData;

    % empty image to serve as a placeholder
    EmptyImage = sparse(zeros(Replicate.Width,Replicate.Height));
    
    CurrentTab = PODSData.Settings.CurrentTab;

%% Update CData of gui image objects to reflect user-specified group/image change 

    switch CurrentTab
        case 'Files'
            try
                for i = 1:4
                    Handles.FFCImgH(i).CData = FFCData.cal_norm(:,:,i);
                    Handles.FFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
                end
                drawnow
            catch
                UpdateLog3(source,'WARNING: No FFC Images found for this group, try loading them now','append');
                for i = 1:4
                    Handles.FFCImgH(i).CData = EmptyImage;
                    Handles.FFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
                end                
                drawnow
            end

            try
                images = Replicate.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
                end
                drawnow                
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
                end                
                
            end

        case 'FFC'
            
            %% Flat-Field Corrected Intensity Images
            try
                images = Replicate.pol_ffc_normalizedbystack;
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = images(:,:,i);
                    Handles.PolFFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
                end        
            catch
                for i = 1:4
                    Handles.PolFFCImgH(i).CData = EmptyImage;
                    Handles.PolFFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
                end                      
            end
            
            clear images

            %% Experimental Intensity Images
            try
                images = Replicate.pol_rawdata_normalizedbystack;
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = images(:,:,i);
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
                end
                drawnow                 
            catch
                for i = 1:4
                    Handles.RawIntensityImgH(i).CData = EmptyImage;
                    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};                    
                end
            end
            
            clear images
            
        case 'Generate Mask'
            %% Masking Steps
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
                Handles.MStepsAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
            end
            
            %% Mask
            try
                Handles.MaskImgH.CData = Replicate.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end

            %% Thresh Slider
            try
                Handles.ThreshSlider.Limits = [0 1];
                Handles.ThreshSlider.Value = Replicate.level;
            catch
                Handles.ThreshSlider.Value = 0.5;
            end
            
            try
                Handles.CurrentThresholdLine.Value = Replicate.level;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Error moving thresh line...')
                Handles.CurrentThresholdLine.Value = 0.5;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            end            

        case 'View/Adjust Mask'
            
            %% Mask
            try
                Handles.MaskImgH.CData = Replicate.bw;
            catch
                Handles.MaskImgH.CData = EmptyImage;
            end
            
            try
                Handles.ThreshBar.XData = Replicate.IntensityBinCenters;
                Handles.ThreshBar.YData = Replicate.IntensityHistPlot;
            catch
                warning('Failed to update threshold slider with currently selected image data...');
            end

            try
                Handles.CurrentThresholdLine.Value = Replicate.level;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            catch
                disp('Error moving thresh line...')
                Handles.CurrentThresholdLine.Value = 0.5;
                Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
            end            

            %% Average Intensity
            try
                Handles.AverageIntensityImgH.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImgH.CData = EmptyImage;
            end
            Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};

        case 'Order Factor'
            
            %% Order Factor
            try
                Handles.OrderFactorImgH.CData = Replicate.OF_image;
            catch
                Handles.OrderFactorImgH.CData = EmptyImage;
            end
            Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;
            
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if Handles.ApplyMaskOrderFactor.Value == 1
                Handles.OrderFactorImgH.AlphaData = Replicate.bw
            end

            %% Average Intensity
            try
                Handles.AverageIntensityImgH.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImgH.CData = EmptyImage;
            end
            Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};

        case 'Azimuth'
            
            try 
                Handles.AverageIntensityImgH.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImgH.CData = EmptyImage;
            end
            
            try
                delete(Handles.AzimuthLines);
            catch
                warning('Could not delete Azimuth lines');
            end

            Handles.QuiverAxH.XLim = [1 Replicate.Width];
            Handles.QuiverAxH.YLim = [1 Replicate.Height];
            %axis square

            [y,x] = find(Replicate.bw==1);
            theta = Replicate.AzimuthImage(Replicate.bw);
            rho = Replicate.OF_image(Replicate.bw);
            [u,v] = pol2cart(theta,rho);

            x = x';
            y = y';
            u = u';
            v = v';

            xnew = zeros(2,numel(x));
            ynew = zeros(2,numel(y));
            % we want lines to pass through each px of interest, so each line will actually be two half lines
            % coordinates for 1/2 of dipole, 
%             xnew(1,:) = x; % x-coord of origin
%             ynew(1,:) = y; % y-coord of origin
%             xnew(2,:) = x+25*u; % x-coord of endpoint
%             ynew(2,:) = y-25*v; % y-coord of endpoint
% 
%             % for 2nd half of dipole
%             xnew2 = xnew; % x-coord of origin, same as other half-line
%             xnew2(2,:) = x-25*u; % x-coord of endpoint of other half-line
%             ynew2 = ynew; % same story
%             ynew2(2,:) = y+25*v; % same story
% 
%             % combine the half lines so that we have one full line per px of interest
%             xnew3 = xnew2;
%             xnew3(1,:) = xnew(2,:);
%             ynew3 = ynew2;
%             ynew3(1,:) = ynew(2,:);
%             xnew3 = zeros(2,numel(x));
%             ynew3 = zeros(2,numel(y));

            xnew3 = [x+25*u;x-25*u];
            ynew3 = [y-25*v;y+25*v];

            cmap = PODSData.Settings.AllColormaps.OFMap;

            nColors = length(cmap);

            Handles.AzimuthLines = line(Handles.QuiverAxH,xnew3,ynew3,'LineWidth',0.2);

            LineColors = cell(length(Handles.AzimuthLines),1);

            for i = 1:length(Handles.AzimuthLines)
                ColorIdx = round(nColors*rho(i));
                if ColorIdx==0;ColorIdx=1;end
                %if ColorIdx>153;ColorIdx=153;end
                Clr = cmap(ColorIdx,:);
                LineColors{i} = Clr;
            end

            set(Handles.AzimuthLines,{'Color'},LineColors);            

        case 'Plots'
            
            try
                %delete(Handles.SwarmPlotAxH.Children)
                delete(Handles.hSwarmChart)
            catch
                % do nothing
            end
            
            Handles.hSwarmChart = PlotGroupSwarmChart(source,Handles.SwarmPlotAxH);
            
        case 'Filtered Order Factor'
            %% Filtered Order Factor
            try
                Handles.FilteredOFImgH.CData = Replicate.OFFiltered;
            catch
                Handles.FilteredOFImgH.CData = EmptyImage;
            end
            
        case 'View Objects'

            %% Object Viewer
            try;delete(Handles.hObjectOFContour);catch;warning('Failed to delete contour plot');end
            
            cObject = Replicate.CurrentObject;
%%
            % display the (padded) intensity image of the object
            try
                Handles.ObjectPolFFCImgH.CData = Scale0To1(cObject.PaddedFFCIntensitySubImage);
                %Handles.ObjectPolFFCAxH.CLim = [0 1];
            catch
                error('Error displaying object intensity image');
                Handles.ObjectPolFFCImgH.CData = EmptyImage;
            end

            % display object binary image
            try
                Handles.ObjectMaskImgH.CData = cObject.PaddedMaskSubImage;
            catch
                error('Error displaying object binary image');
                Handles.ObjectMaskImgH.CData = EmptyImage;
            end
            
            %Handles.ObjectOFImgH.CData = cObject.PaddedOFSubImage;
            Handles.ObjectOFImgH.CData = cObject.PaddedOFSubImage;
            Handles.ObjectOFAxH.Colormap = PODSData.Settings.OrderFactorColormap;
            
%             try
%                 Handles.ObjectOFImgH.CData = cObject.PaddedOFSubImage;
%             catch
%                 error('Error displaying object OF image');
%                 Handles.ObjectOFImgH.CData = EmptyImage;
%             end

%% display object OF contour - retired for now
            try
                [~,Handles.hObjectOFContour] = contourf(Handles.ObjectOFContourAxH,cObject.OFSubImage,'ShowText','On');
                colormap(Handles.ObjectOFContourAxH,PODSData.Settings.OrderFactorColormap);
            catch
                error('Error displaying 2D Object Order Factor contours');
            end
%%
            drawnow
            
        case 'Image Colocalization'
            
            try
                Handles.PrimaryColocIntensityImgH.CData = Replicate.MedianFilteredImg;
                Handles.PrimaryColocIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
            catch
                Handles.PrimaryColocIntensityImgH.CData = EmptyImage;
            end
            
            try
                Handles.SecondaryColocIntensityImgH.CData = Replicate.ColocEnhanced;
                Handles.SecondaryColocIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
            catch
                Handles.SecondaryColocIntensityImgH.CData = EmptyImage;
            end            
            
            % primary channel mask image
            try
                Handles.PrimaryColocMaskImgH.CData = Replicate.bw;
            catch
                Handles.PrimaryColocMaskImgH.CData = EmptyImage;
            end
            
            % secondary channel mask image
            try
                Handles.SecondaryColocMaskImgH.CData = Replicate.ColocMask;
            catch
                Handles.SecondaryColocMaskImgH.CData = EmptyImage;
            end            
            
            % delete current scatter plot
            try
                delete(Handles.PixelCorrelationPlot)
            catch
                % do nothing
            end

            %Handles.PixelCorrelationPlot = PlotPixelCorrelation(Handles.PixelCorrelationPlotAxH,Replicate.Pol_ImAvg,Replicate.ColocImage,Replicate.CombinedMask);
            Handles.PixelCorrelationPlot = PlotPixelCorrelation(Handles.PixelCorrelationPlotAxH,...
                Replicate.Pol_ImAvg,...
                Replicate.ColocImage,...
                Replicate.CombinedMask,...
                Replicate.UnionMask,...
                Replicate.PrimaryOnlyMask,...
                Replicate.ColocOnlyMask);
            
        end

    % update local PODSData structure with updated Handles
    PODSData.Handles = Handles;
    % update guidata with updated PODSData structure
    guidata(source,PODSData);
    

end