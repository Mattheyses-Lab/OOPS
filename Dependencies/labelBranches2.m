function [branchesLabeled,dilatedL] = labelBranches2(I)
    % skeletonizes, then labels individual branches in skeletonized 
    % binary image and returns unskeletonized label matrix

    % skeletonize the binary image (works better if we thin first)
    binarySkeleton = bwmorph(I,"thin",inf);
    binarySkeleton = bwskel(binarySkeleton);
    % get the branchpoints from the skeletonized binary image
    branchPoints = bwmorph(binarySkeleton,'branchpoints');
    % remove branchpoints so we are left with only branches
    branches = imsubtract(binarySkeleton,branchPoints);
    % label the individual 8-connected branches (this is the first output)
    branchesLabeled = bwlabel(branches);
    % create an image where every unlabeled pixel = NaN
    nanL = branchesLabeled;
    nanL(nanL==0) = NaN;
    % initialize the output image which will hold our full labeled image
    dilatedL = zeros(size(nanL));
    % preallocate mask image of just the branches
    branchMask = false(size(branchesLabeled));
    % set branch pixels to true
    branchMask(branchesLabeled>0) = 1;
    % get the linear pixel idx list for each 8-connected object in the input binary image
    props = regionprops(I,{'PixelIdxList'});
    % cell array of labels for each pixel in the mask
    pixelLabels = cell(length(props),1);
    % cell array of linear idxs for each pixel in the mask
    pixelLinearIdxs = cell(length(props),1);
    % the number of 8-connected objects in the input mask
    nObjects = length(props);

    % for each object
    parfor i = 1:nObjects
        % initialize array of NaNs, same size as input
        objectnanL = nan(size(nanL));
        % get the list of linear idxs for each pixel in the object
        objectPixels = props(i).PixelIdxList;
        % get the branch labels for this object
        objectnanL(objectPixels) = nanL(objectPixels);
        % get the unique labels in the object
        labelsInObject = unique(objectnanL(~isnan(objectnanL)));
        % add the object pixel idxs to our cell array
        pixelLinearIdxs{i,1} = objectPixels;
        % if only one unique label
        if numel(labelsInObject)==1
            % add labels to the cell array of pixel labels
            pixelLabels{i,1} = repmat(labelsInObject,numel(objectPixels),1);
        else
            % get the mask of just this object
            objectMask = false(size(I));
            objectMask(objectPixels) = 1;
            % the mask representing missing pixels we want to fill with fillmissing2()
            objectMissingMask = objectMask & ~branchMask;
            % get the label image for this object
            objectDilatedL = fillmissing2(objectnanL,"nearest","MissingLocations",objectMissingMask);
            % add labels to the cell array of pixel labels
            pixelLabels{i,1} = objectDilatedL(objectPixels);
        end

    end

    % concatenate cell arrays of pixel idxs and labels into column vectors
    pixelLinearIdxsVec = cat(1,pixelLinearIdxs{:});
    pixelLabelsVec = cat(1,pixelLabels{:});
    % add the labels to their corresponding pixels
    dilatedL(pixelLinearIdxsVec) = pixelLabelsVec;

end