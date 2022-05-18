function [] = FindOrderFactor3(source,event)

    PODSData = guidata(source);
    cGroupIndex = PODSData.CurrentGroupIndex;
    %cChannelIndex = PODSData.CurrentChannelIndex;
    
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    cReplicate = PODSData.Group(cGroupIndex).Replicate;

    UpdateLog3(source,'Calculating Order Factor...','append');
    chartab = '    ';

    % finds the order factor for all user-specified replicates or for the
    % entire group if batch processing
    for i = 1:length(cImageIndex)
        ii = cImageIndex(i);
        UpdateLog3(source,[chartab,'Image ',num2str(i),' of ',num2str(length(cImageIndex)),'...'],'append');        
        
        %% Normalize pixel-by-pixel
        %cReplicate(ii).norm = zeros(size(cReplicate(ii).pol_ffc));

        n_img = 4;

        maximum = max(cReplicate(ii).pol_ffc,[],3);
        
        % This should always be true for all pixels
        cReplicate(ii).r1 = cReplicate(ii).pol_ffc(:,:,1) > 0;

        % divide each pixel by maximum pixel value in polarization stack
        for j=1:n_img
            cReplicate(ii).norm(:,:,j) = cReplicate(ii).pol_ffc(:,:,j)./maximum;
        end

        %% Find pixel-by-pixel order factor for whole image   
        cReplicate(ii).a = cReplicate(ii).norm(:,:,1) - cReplicate(ii).norm(:,:,3);
        cReplicate(ii).b = cReplicate(ii).norm(:,:,2) - cReplicate(ii).norm(:,:,4);

        cReplicate(ii).OF_image = zeros(size(cReplicate(ii).norm(:,:,1)));
        cReplicate(ii).OF_image(cReplicate(ii).r1) = sqrt(cReplicate(ii).a(cReplicate(ii).r1).^2+cReplicate(ii).b(cReplicate(ii).r1).^2);
            
        %% Find azimuth image
        cReplicate(ii).AzimuthImage = zeros(size(cReplicate(ii).norm(:,:,1)));
        % !WARNING! Output is in radians! Counterclockwise with respect to the horizontal direction in the image
        cReplicate(ii).AzimuthImage(cReplicate(ii).r1) = (1/2).*atan2(cReplicate(ii).b(cReplicate(ii).r1),cReplicate(ii).a(cReplicate(ii).r1));

        %apply mask to order factor image
        temp = zeros(size(cReplicate(ii).OF_image));  
        temp(cReplicate(ii).bw) = cReplicate(ii).OF_image(cReplicate(ii).bw);
        cReplicate(ii).masked_OF_image = sparse(temp);
        clear temp
        
        logmsg = [chartab,chartab,'Image-Average Order Factor: ', num2str(cReplicate(ii).OFAvg),... 
                  chartab,chartab,chartab,'Max: ', num2str(cReplicate(ii).OFMax),...
                  chartab,chartab,chartab,'Min: ', num2str(cReplicate(ii).OFMin)];
              
        UpdateLog3(source,logmsg,'append');
        
        % order factor image exists for this replicate
        cReplicate(ii).OFDone = 1;
        
    end

    % update PODSData with new replicate data
    PODSData.Group(cGroupIndex).Replicate = cReplicate;
    
    % update gui with new PODSData
    guidata(source,PODSData);
    
    % change to the Order Factor 'tab' if not there already
    if ~strcmp(PODSData.Settings.CurrentTab,'Order Factor')
        feval(PODSData.Handles.hTabOrderFactor.Callback,PODSData.Handles.hTabOrderFactor,[]);
    end    
    
    % Update GUI
    UpdateTables(source);
    UpdateImages(source);
    UpdateLog3(source,'Done calculating Order Factor.','append');

end