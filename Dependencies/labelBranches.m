function [branchesLabeled,dilatedL] = labelBranches(I)
    % skeletonizes, then labels individual branches in skeletonized 
    % binary image and returns unskeletonized label matrix
    
    % skeletonize the binary image
    

    % testing below - alternative skeletonization method
    binarySkeleton = bwmorph(I,"thin",inf);
    binarySkeleton = bwskel(binarySkeleton);

    % get the branchpoints from the skeletonized binary image
    branchPoints=bwmorph(binarySkeleton,'branchpoints');
    
    % remove branchpoints so we are left with only branches
    branches = imsubtract(binarySkeleton,branchPoints);
    
    % label the branches (8-connectivity)
    branchesLabeled = bwlabel(branches); % label connected components
    
    % create an image where every unlabeled pixel = NaN
    nanL = branchesLabeled;
    nanL(nanL==0) = NaN;
    
    % initialize the output image which will hold our full labeled image
    dilatedL = zeros(size(nanL));

    % get the pixel idx list for each 8-connected object in the input binary image
    props = regionprops(I,{'PixelIdxList'});
    
    % for each object
    for i = 1:size(props)
        % get the branch labels for just this object
        temp_nanL = zeros(size(nanL));
        temp_nanL(:) = NaN;
        temp_nanL(props(i).PixelIdxList) = nanL(props(i).PixelIdxList);
        % get the mask of just this object
        temp_mask = false(size(I));
        temp_mask(props(i).PixelIdxList) = 1;
        % get the label image for this object
        temp_dilatedL = replacenansinmask(temp_nanL,temp_mask);
        % add those labels to the full label image
        dilatedL(props(i).PixelIdxList) = temp_dilatedL(props(i).PixelIdxList);
    end

end


function out = replacenansinmask(in,mask)

    out = in;
    
    inSize = size(in);
    
    % Now find the nan's
    nanLocations = isnan(in) & mask;
    nanLinearIndexes = find(nanLocations);
    
    % and non-nans (only inside the mask)
    nonNanLocations = ~isnan(in) & mask;
    nonNanLinearIndexes = find(nonNanLocations);
    
    % Get the row and column locations of non-nan elements
    [R, C] = ind2sub(inSize, nonNanLinearIndexes);
    
    for index = 1 : length(nanLinearIndexes)
        thisLinearIndex = nanLinearIndexes(index);
        % convert linear idx to row and col coordinates
        [r,c] = ind2sub(inSize, thisLinearIndex);
        % Get distances of this location to all the other locations
        distances = sqrt((r-R).^2 + (c-C).^ 2);
        % ascending sort
        %[~, sortedIndexes] = sort(distances, 'ascend');
    
        [~,minIdx] = min(distances);
    
        % The closest non-nan value will be located at index sortedIndexes(1)
        r2 = R(minIdx);
        c2 = C(minIdx);
    
        newIdx = sub2ind(inSize,r2,c2);
        % Replace the bad nan value in out with the good value in 'in'
        out(thisLinearIndex) = in(newIdx);
    end

end
