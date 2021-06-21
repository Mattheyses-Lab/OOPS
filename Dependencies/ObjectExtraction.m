function [] = ObjectExtraction(source,type)

    PODSData = guidata(source);
    cGroupIndex = PODSData.CurrentGroupIndex;
    
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    cReplicate = PODSData.Group(cGroupIndex).Replicate;

    if length(cImageIndex) > 1
        first = cImageIndex(1);
        last = cImageIndex(end);
    else
        first = cImageIndex;
        last = cImageIndex;
    end    
    
    
    
    
    
switch type
    case 'Mask'
    
    %% Extract object paramaters calculated from regionprops    
        % iterate through replicates
        for i = 1:length(cImageIndex)

            % get replicate index, ii
            ii = cImageIndex(i);

            % get some Average FFC-Corrected Intensity Object Properties
            [~,~,~,~,FFCAvgObjProps] = ObjectDetection3(cReplicate(ii).bw,'FFCAvg',cReplicate(ii).Pol_ImAvg);

            %% UPDATE OBJECT SELECTION BOX

            % Create default object
            cReplicate(ii).Object = MakeNewObject();

            % iterate through each object
            for j = 1:cReplicate(ii).nObjects

                % Add size/shape/position properties of object, calculated from
                % regionprops(L,bw,'all')
                cReplicate(ii).Object(j).Area = cReplicate(ii).bwObjectProperties(j).Area;
                cReplicate(ii).Object(j).BoundingBox = cReplicate(ii).bwObjectProperties(j).BoundingBox;
                cReplicate(ii).Object(j).Centroid = cReplicate(ii).bwObjectProperties(j).Centroid;
                cReplicate(ii).Object(j).Circularity = cReplicate(ii).bwObjectProperties(j).Circularity;
                cReplicate(ii).Object(j).ConvexArea = cReplicate(ii).bwObjectProperties(j).ConvexArea;
                cReplicate(ii).Object(j).ConvexHull = cReplicate(ii).bwObjectProperties(j).ConvexHull;
                cReplicate(ii).Object(j).ConvexImage = cReplicate(ii).bwObjectProperties(j).ConvexImage;
                cReplicate(ii).Object(j).Eccentricity = cReplicate(ii).bwObjectProperties(j).Eccentricity;
                cReplicate(ii).Object(j).Extrema = cReplicate(ii).bwObjectProperties(j).Extrema;
                cReplicate(ii).Object(j).FilledArea = cReplicate(ii).bwObjectProperties(j).FilledArea;
                cReplicate(ii).Object(j).Image = cReplicate(ii).bwObjectProperties(j).Image;
                cReplicate(ii).Object(j).MajorAxisLength = cReplicate(ii).bwObjectProperties(j).MajorAxisLength;
                cReplicate(ii).Object(j).MinorAxisLength = cReplicate(ii).bwObjectProperties(j).MinorAxisLength;
                cReplicate(ii).Object(j).Orientation = cReplicate(ii).bwObjectProperties(j).Orientation;
                cReplicate(ii).Object(j).Perimeter = cReplicate(ii).bwObjectProperties(j).Perimeter;
                cReplicate(ii).Object(j).PixelIdxList = cReplicate(ii).bwObjectProperties(j).PixelIdxList;
                cReplicate(ii).Object(j).PixelList = cReplicate(ii).bwObjectProperties(j).PixelList;

                % Add intensity properties from FFC-Corrected Avg Intensity
                % Image:regionprops(L,PODSData.Group(#).Replicate(#).Pol_ImAvg)
                cReplicate(ii).Object(j).MaxFFCAvgIntensity = FFCAvgObjProps(j).MaxIntensity;
                cReplicate(ii).Object(j).MeanFFCAvgIntensity = FFCAvgObjProps(j).MeanIntensity;
                cReplicate(ii).Object(j).MinFFCAvgIntensity = FFCAvgObjProps(j).MinIntensity;

                % Add default names and indices to objects
                cReplicate(ii).Object(j).Name = ['Object ',num2str(j)];
                cReplicate(ii).Object(j).OriginalIdx = j;

                cReplicate(ii).Object(j).GroupName = PODSData.Group(cGroupIndex).GroupName;

            end  % end of object(s)

            ObjectNames = {};
            [ObjectNames{1:cReplicate(ii).nObjects,1}] = deal(cReplicate(ii).Object.Name);

            cReplicate(ii).ObjectNames = [ObjectNames];

            PODSData.Group(cGroupIndex).Replicate(ii) = cReplicate(ii);

            %% UPDATE TABLE TO REFLECT 1ST REPLICATE PROCESSED (CURRENT)
            % set object name list box values to object names
            PODSData.Handles.ObjectSelector.Items = ObjectNames;
            % set ItemsValue of object listbox so we can index it
            PODSData.Handles.ObjectSelector.ItemsData = [1:length(ObjectNames)];        

            UpdateLog3(source,['    Image ',num2str(i),' of ',num2str(length(cImageIndex)),'...'],'append');

        end  % end of replicates(s)

    case 'Order Factor'
        for i = 1:length(cImageIndex) % for each technical replicate
            
            % get replicate index, ii
            ii = cImageIndex(i);            
            
            for j = 1:cReplicate(ii).nObjects % for each object
                % get linear px indices for current object
                PxIdxList = cReplicate(ii).Object(j).PixelIdxList;
                
                cReplicate(ii).Object(j).OFPixelValues = cReplicate(ii).OF_image(PxIdxList);
                cReplicate(ii).Object(j).OFMax = max(cReplicate(ii).Object(j).OFPixelValues);
                cReplicate(ii).Object(j).OFMin = min(cReplicate(ii).Object(j).OFPixelValues);
                cReplicate(ii).Object(j).OFAvg = mean(cReplicate(ii).Object(j).OFPixelValues);

            end % end of objects
            
            PODSData.Group(cGroupIndex).Replicate(ii) = cReplicate(ii);

        end % end of replicates

end % end switch statement   
    
    
    
    
    

    % return updated PODSData to gui
    guidata(source,PODSData);
    UpdateLog3(source,'Done.','append');
    
end