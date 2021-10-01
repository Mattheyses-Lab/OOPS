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
            
        case 'Generate Mask'
            %% Masking Steps
            try
                Handles.MStepsIntensityImage.CData = Replicate.I;
                Handles.MStepsBackgroundImage.CData = Replicate.BGImg;

                Handles.MStepsBGSubtractedImage.CData = Replicate.BGSubtractedImg;
                Handles.MStepsBGSubtracted.CLim = [min(min(Replicate.BGSubtractedImg)) max(max(Replicate.BGSubtractedImg))];

                Handles.MStepsMedianFilteredImage.CData = Replicate.MedianFilteredImg;
                Handles.MStepsMedianFiltered.CLim = [min(min(Replicate.MedianFilteredImg)) max(max(Replicate.MedianFilteredImg))];
            catch
                Handles.MStepsIntensityImage.CData = EmptyImage;
                Handles.MStepsBackgroundImage.CData = EmptyImage;
                Handles.MStepsBGSubtractedImage.CData = EmptyImage;
                Handles.MStepsMedianFilteredImage.CData = EmptyImage;        
            end
            
            for i = 1:4
                Handles.MStepsAxH(i).Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};
            end
            
            %% Mask
            try
                Handles.MaskImage.CData = Replicate.bw;
            catch
                Handles.MaskImage.CData = EmptyImage;
            end

            %% Thresh Slider
            try
                Handles.ThreshSlider.Limits = [0 1];
                Handles.ThreshSlider.Value = Replicate.level;
            catch
                Handles.ThreshSlider.Value = 0.5;
            end

        case 'View/Adjust Mask'
            
            %% Mask
            try
                Handles.MaskImage.CData = Replicate.bw;
            catch
                Handles.MaskImage.CData = EmptyImage;
            end

            %% Thresh Slider Limits and Current Value
            try
                Handles.ThreshSlider.Limits = [0 1];
                Handles.ThreshSlider.Value = Replicate.level;
            catch
                Handles.ThreshSlider.Value = 0.5;
            end          
            
            %% Thresh slider data
                % Intensity Distribution Plot
            try
                Handles.ThreshBar.XData = Replicate.IntensityBinCenters;
                Handles.ThreshBar.YData = Replicate.IntensityHistPlot;
            catch
                warning('Failed to update threshold slider with currently selected image data...');
            end

            %% Average Intensity
            try
                Handles.AverageIntensityImage.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImage.CData = EmptyImage;
            end
            Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};

        case 'Order Factor'
            
            %% Order Factor
            try
                Handles.OrderFactorImage.CData = Replicate.OF_image;
            catch
                Handles.OrderFactorImage.CData = EmptyImage;
            end
            Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;
            
            % if ApplyMask state button set to true, apply current mask by setting AlphaData
            if Handles.ApplyMaskOrderFactor.Value == 1
                Handles.OrderFactorImage.AlphaData = Replicate.bw
            end

            %% Average Intensity
            try
                Handles.AverageIntensityImage.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImage.CData = EmptyImage;
            end
            Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{cChannelIdx};

        case 'Azimuth'
            
            try 
                Handles.AverageIntensityImage.CData = Replicate.I;
                Handles.AverageIntensityAxH.CLim = [min(min(Replicate.I)) max(max(Replicate.I))];
            catch
                Handles.AverageIntensityImage.CData = EmptyImage;
            end
            
            
            try
                delete(Handles.QuiverPlot)
            catch
                warning('Failed to delete quiver plot.')
            end            

            try 

                angles = zeros(size(Replicate.AzimuthImage));
                angles(Replicate.bw) = Replicate.AzimuthImage(Replicate.bw);
                
                % convert angle data into cartesian coordinates
                theta = angles;
                rho = Replicate.masked_OF_image;
                [m,n] = size(theta);                
                x = 1:n;                            % x-coordinates for width (x = [1,...,n])
                y = 1:m;                            % y-coordinates for height
                [x,y] = meshgrid(x,y);              % expand x and y arrays into matrices for quiver plot indexing
                [u,v] = pol2cart(theta,rho);        % convert polar to cartesian
                
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%                 % q = quiver(x(1:2:end),y(1:2:end),u(1:2:end),v(1:2:end),3);
%                 % 1:4:end shows 1/16th of the arrows
%                 % 1:2:end shows 1/4th of the arrows, etc.
%                 % quiver(x,y,u,v) would show ALL arrows (quite slow for large images)
%                 % '3' is a scale factor
% 
%                 % make QuiverAxH active
%                 axes(Handles.QuiverAxH);
% 
%                 % v is negative because our 1/2 waveplate rotates clockwise (i.e. E-field of light rotates clockwise)
%                  Handles.QuiverPlot = quiver(Handles.QuiverAxH,x(1:10:end),y(1:10:end),u(1:10:end),-v(1:10:end),5);
%                  disableDefaultInteractivity(Handles.QuiverAxH);
%                 % lower line width from default 0.5 and remove arrowheads
%                  Handles.QuiverPlot.LineWidth = 0.1;
%                  Handles.QuiverPlot.ShowArrowHead = 'Off';
% 
%                 % set bg color to black
%                 Handles.QuiverAxH.Color = [0 0 0];
% 
%                 % no axis tick marks
%                 Handles.QuiverAxH.XTick = [];
%                 Handles.QuiverAxH.YTick = [];
%                 
%                 % axis square - not necessary if underlying image data are square
%                 % add custom toolbar to allow zooming in/out on quiver plot
%                 %[tb1,btns1] = axtoolbar(data.sbpltBR,{'zoomin','zoomout','restoreview'});
%                 
%                 % set axis range to match size of image
%                 axis([0 n 0 m]);
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
% ONE VECTOR PER OBJECT

                arraylength = Replicate.nObjects;
                
                qrows = zeros(arraylength,1);
                qcols = zeros(arraylength,1);
                qu = zeros(arraylength,1);
                qv = zeros(arraylength,1);
                
                for ObjIdx = 1:Replicate.nObjects

                    centroid = Replicate.Object(ObjIdx).Centroid;
                    qx = round(centroid(1));
                    qy = round(centroid(2));
                    
                    qrows(ObjIdx,1) = qy;
                    qcols(ObjIdx,1) = qx;
                    
                    qtheta = theta(qy,qx);
                    qrho = rho(qy,qx);

                    [qu(ObjIdx,1),qv(ObjIdx,1)] = pol2cart(qtheta,qrho);
                    
                end
                
                % plot quiver, scaling arrow lengths by 50X (otherwise extremely small)
                Handles.QuiverPlot = quiver(Handles.QuiverAxH,qcols,qrows,50*qu,-50*qv,0);
                
                % disable default interactivity (datatips on hover is very slow with many arrows)
                %disableDefaultInteractivity(Handles.QuiverAxH);
                
                % make axes limits match image data
                Handles.QuiverAxH.XLim = [0 m];
                Handles.QuiverAxH.YLim = [0 n];
                
                disp('Done displaying quiver plot.');
           
            catch
                error('Error plotting vectors...');
            end            

        case 'Anisotropy'
            
        case 'Filtered Order Factor'
            
            %% Filtered Order Factor
            try
                Handles.FilteredOFImgH.CData = Replicate.OFFiltered;
            catch
                Handles.FilteredOFImgH.CData = EmptyImage;
            end
        case 'View Objects'

            %% Object Viewer
            try;delete(Handles.hSurfc);catch;warning('Failed to delete surf plot');end
            try;delete(Handles.Object3DAxHColorbar);catch;warning('Failed to delete surf colorbar');end
            try;delete(Handles.hObjectOFContour);catch;warning('Failed to delete contour plot');end

            try
                cObject = Replicate.CurrentObject;
                axes(Handles.Object3DAxH)
                Handles.Object3DAxHColorbar = colorbar('location','eastoutside','color','white');
                Handles.hSurfc = surfc(Handles.Object3DAxH,cObject.OFSubImage);
                Handles.hSurfc(1).EdgeColor = 'interp';
                Handles.hSurfc(1).FaceColor = 'interp';
                colormap(Handles.Object3DAxH,PODSData.Settings.OrderFactorColormap);     
            catch
                error('Error plotting object 3D contours...');
            end

            % display the (padded) intensity image of the object
            try
                Handles.ObjectPolFFCImgH.CData = cObject.PaddedFFCIntensitySubImage;
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

            % display object OF contour
            try
                [~,Handles.hObjectOFContour] = contourf(Handles.ObjectOFContourAxH,cObject.OFSubImage,'ShowText','On');
                colormap(Handles.ObjectOFContourAxH,PODSData.Settings.OrderFactorColormap);
            catch
                error('Error displaying 2D Object Order Factor contours');
            end
            drawnow            
            
    end

    % update local PODSData structure with updated Handles
    PODSData.Handles = Handles;
    % update guidata with updated PODSData structure
    guidata(source,PODSData);
    

end