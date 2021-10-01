function [] = FindOrderFactor3(source,event)

    PODSData = guidata(source);
    cGroupIndex = PODSData.CurrentGroupIndex;
    cChannelIndex = PODSData.CurrentChannelIndex;
    
    cImageIndex = PODSData.Group(cGroupIndex,cChannelIndex).CurrentImageIndex;
    cReplicate = PODSData.Group(cGroupIndex,cChannelIndex).Replicate;
    
    
    if length(cImageIndex) > 1
        first = cImageIndex(1);
        last = cImageIndex(end);
    else
        first = cImageIndex;
        last = cImageIndex;
    end

    UpdateLog3(source,'Calculating Order Factor...','append');
    chartab = '    ';

    % finds the order factor for all user-specified replicates or for the
    % entire group if batch processing
    for i = 1:length(cImageIndex)
        ii = cImageIndex(i);
        UpdateLog3(source,[chartab,'Image ',num2str(i),' of ',num2str(length(cImageIndex)),'...'],'append');        
        
        %% Normalize pixel-by-pixel
        cReplicate(ii).norm = zeros(size(cReplicate(ii).pol_ffc));
        maximum = cReplicate(ii).pol_ffc(:,:,1);
        minimum = cReplicate(ii).pol_ffc(:,:,1);
        n_img = 4;

        % create maximum and minimum, matrices to hold max and min for each
        % pixel across polarization stack
        for j = 2:n_img
            next = cReplicate(ii).pol_ffc(:,:,j);
            max_update = next > maximum;
            min_update = next < minimum;
            maximum(max_update) = next(max_update);
            minimum(min_update) = next(min_update);
            clear next max_update min_update
        end

        % This should always be true for all pixels
        cReplicate(ii).r1 = cReplicate(ii).pol_ffc(:,:,1) > 0;

        % divide each pixel by maximum pixel value in polarization stack
        for j=1:n_img
            current = cReplicate(ii).pol_ffc(:,:,j);
            normcurrent = zeros(size(cReplicate(ii).norm(:,:,j)));

            normcurrent(cReplicate(ii).r1) = current(cReplicate(ii).r1)./maximum(cReplicate(ii).r1);
            cReplicate(ii).norm(:,:,j) = normcurrent;
            clear current normcurrent
        end

        %% Find pixel-by-pixel order factor for whole image   
        cReplicate(ii).a = cReplicate(ii).norm(:,:,1) - cReplicate(ii).norm(:,:,3);
        cReplicate(ii).b = cReplicate(ii).norm(:,:,2) - cReplicate(ii).norm(:,:,4);

        cReplicate(ii).OF_image = zeros(size(cReplicate(ii).norm(:,:,1)));
        cReplicate(ii).OF_image(cReplicate(ii).r1) = sqrt(cReplicate(ii).a(cReplicate(ii).r1).^2+cReplicate(ii).b(cReplicate(ii).r1).^2);
            
        %% Find azimuth image
        cReplicate(ii).AzimuthImage = zeros(size(cReplicate(ii).norm(:,:,1)));
        cReplicate(ii).AzimuthImage(cReplicate(ii).r1) = (1/2).*atan2(cReplicate(ii).b,cReplicate(ii).a);

        %apply mask to order factor image
        temp = zeros(size(cReplicate(ii).OF_image));  
        temp(cReplicate(ii).bw) = cReplicate(ii).OF_image(cReplicate(ii).bw);
        cReplicate(ii).masked_OF_image = sparse(temp);
        clear temp

        % compute OF_avg and OF_list
        cReplicate(ii).OFAvg = sum(sum(cReplicate(ii).masked_OF_image))/nnz(cReplicate(ii).masked_OF_image);
        cReplicate(ii).OFList = cReplicate(ii).masked_OF_image(cReplicate(ii).bw);
        cReplicate(ii).OFMax = max(cReplicate(ii).OFList(:));
        cReplicate(ii).OFMin = min(cReplicate(ii).OFList(:));
        
        
        OFProperties = regionprops(full(cReplicate(ii).L),...
                                   full(cReplicate(ii).masked_OF_image),...
                                   'MeanIntensity',...
                                   'MinIntensity',...
                                   'MaxIntensity',...
                                   'PixelValues');
        
        for j = 1:length(OFProperties)
            cReplicate(ii).Object(j).OFAvg = OFProperties(j).MeanIntensity;
            cReplicate(ii).Object(j).OFMin = OFProperties(j).MinIntensity;
            cReplicate(ii).Object(j).OFMax = OFProperties(j).MaxIntensity;
            cReplicate(ii).Object(j).OFPixelValues = OFProperties(j).PixelValues;
            
            if cReplicate(ii).Object(j).OFAvg == 0
                UpdateLog3(source,['WARNING: G',num2str(cGroupIndex),'R',num2str(ii),'O',num2str(j),' Avg OF = 0!'],'append');
            end
        end

        clear OFProperties
        
        logmsg = [chartab,chartab,'Image-Average Order Factor: ', num2str(cReplicate(ii).OFAvg),... 
                  chartab,chartab,chartab,'Max: ', num2str(cReplicate(ii).OFMax),...
                  chartab,chartab,chartab,'Min: ', num2str(cReplicate(ii).OFMin)];
              
        UpdateLog3(source,logmsg,'append');
        
        % order factor image exists for this replicate
        cReplicate(ii).OFDone = 1;
        
    end

    % update PODSData with new replicate data
    PODSData.Group(cGroupIndex,cChannelIndex).Replicate = cReplicate;
    % find average order factor for group for all images calculated so far
    PODSData.Group(cGroupIndex,cChannelIndex).OFAvg = mean([cReplicate(find([cReplicate.OFAvg]>0)).OFAvg]);
    
    % update gui with new PODSData
    guidata(source,PODSData);
    
    if ~strcmp(PODSData.Settings.CurrentTab,'Order Factor')
        feval(PODSData.Handles.hTabOrderFactor.Callback,PODSData.Handles.hTabOrderFactor,[]);
    end    
    
    % Update GUI
    UpdateTables(source);
    UpdateImages(source);
    UpdateLog3(source,'Done calculating Order Factor.','append');

end