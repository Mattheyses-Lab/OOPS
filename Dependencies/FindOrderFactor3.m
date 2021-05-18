function [] = FindOrderFactor3(source,event)

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


    % finds the order factor for all user-specified replicates or for the
    % entire group if batch processing
    for i = first:last
        %% Normalize pixel-by-pixel
        logmsg = ['Normalizing polarization stack pixel-by-pixel...'];
        UpdateLog3(source,logmsg,'append');
        cReplicate(i).norm = zeros(size(cReplicate(i).pol_ffc));
        maximum = cReplicate(i).pol_ffc(:,:,1);
        minimum = cReplicate(i).pol_ffc(:,:,1);
        n_img = 4;

        % create maximum and minimum, matrices to hold max and min for each
        % pixel across polarization stack
        for ii = 2:n_img
            next = cReplicate(i).pol_ffc(:,:,ii);
            max_update = next > maximum;
            min_update = next < minimum;
            maximum(max_update) = next(max_update);
            minimum(min_update) = next(min_update);
        end

        % This should always be true for all pixels
        cReplicate(i).r1 = cReplicate(i).pol_ffc(:,:,1) > 0;

        % divide each pixel by maximum pixel value in polarization stack
        for ii=1:n_img
            current = cReplicate(i).pol_ffc(:,:,ii);
            normcurrent = zeros(size(cReplicate(i).norm(:,:,ii)));

            normcurrent(cReplicate(i).r1) = current(cReplicate(i).r1)./maximum(cReplicate(i).r1);
            cReplicate(i).norm(:,:,ii) = normcurrent;
        end

        %% Find pixel-by-pixel order factor for whole image
        logmsg = ['Calculating pixel-by-pixel Order Factor...'];
        UpdateLog3(source,logmsg,'append');    
        cReplicate(i).a = cReplicate(i).norm(:,:,1) - cReplicate(i).norm(:,:,3);
        cReplicate(i).b = cReplicate(i).norm(:,:,2) - cReplicate(i).norm(:,:,4);

        cReplicate(i).OF_image = zeros(size(cReplicate(i).norm(:,:,1)));
        cReplicate(i).OF_image(cReplicate(i).r1) = sqrt(cReplicate(i).a(cReplicate(i).r1).^2+cReplicate(i).b(cReplicate(i).r1).^2);

        %apply mask to order factor image
        temp = zeros(size(cReplicate(i).OF_image));  
        temp(cReplicate(i).bw) = cReplicate(i).OF_image(cReplicate(i).bw);
        cReplicate(i).masked_OF_image = temp;

        % compute OF_avg and OF_list
        cReplicate(i).OF_avg = sum(sum(cReplicate(i).masked_OF_image))/nnz(cReplicate(i).masked_OF_image);
        cReplicate(i).OF_list = cReplicate(i).masked_OF_image(cReplicate(i).bw);
        cReplicate(i).OF_properties = regionprops(logical(cReplicate(i).L), cReplicate(i).masked_OF_image, 'all');
        cReplicate(i).OF_max = max(cReplicate(i).OF_list(:));
        cReplicate(i).OF_min = min(cReplicate(i).OF_list(:));

        logmsg = ['Image-Average Order Factor: ', num2str(cReplicate(i).OF_avg),... 
                  '    Max: ', num2str(cReplicate(i).OF_max),...
                  '    Min: ', num2str(cReplicate(i).OF_min)];
        UpdateLog3(source,logmsg,'append');    
    end

    % update PODSData with new replicate data
    PODSData.Group(cGroupIndex).Replicate = cReplicate;

    % get handles
    Handles = PODSData.Handles;

    % update handles
    Handles.OrderFactorImgH.CData = PODSData.Group(cGroupIndex).Replicate(first).masked_OF_image;
    Handles.AverageIntensityImgH.CData = PODSData.Group(cGroupIndex).Replicate(first).I;
    
    % update PODSData Handles with altered handles
    PODSData.Handles = Handles;
    
    % update gui with new PODSData
    guidata(source,PODSData);

end