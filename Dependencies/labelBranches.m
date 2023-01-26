function [skelL,dilatedL] = labelBranches(I)
% skeletonizes, then labels individual branches in skeletonized 
% binary image and returns unskeletonized label matrix

y = bwskel(I);

%% code below from https://dsp.stackexchange.com/questions/7622/find-branches-in-skeleton-image-using-matlab

mn=bwmorph(y,'branchpoints');
[row column] = find(mn);
branchPts    = [row column];
endImg    = bwmorph(y, 'endpoints');
[row column] = find(endImg);
endPts       = [row column];
% figure;imshow(y);
% hold on ; 
% plot(branchPts(:,2),branchPts(:,1),'rx');
% hold on; plot(endPts(:,2),endPts(:,1),'*');
% Labeling the Branches
branches = imsubtract(y,mn); % set branch points to zero
% figure; imshow(branches);title('no bp')
branchesLabeled = bwlabel(branches); % label connected components

% WD edits below
% figure();imshow(label2rgb(branchesLabeled));
% end WD edits
% WD: line below does not work
%vislabels(branchesLabeled);

% Calculation of Length of Branches and Circular Neighbourhood Method for
% for detection of normal and abnormal branches.
% sts = regionprops( branchesLabeled,'Area', 'Perimeter','MajorAxisLength','Centroid');
% 
% 
% figure
% imshow(branchesLabeled)
% hold on
% % Loop for circles
% for i=1:size(sts)
% r= sts(i).MajorAxisLength/2 ; %desired radius
% centerx = sts(i).Centroid(1);  
% centery = sts(i).Centroid(2);
% th = 0:pi/50:2*pi;
% xunit = r * cos(th) + centerx;
% yunit = r * sin(th) + centery;
% plot(xunit, yunit);
% end

%% end code from stack exchange

% hold off

%% reconstruct the image from skeletonized labels
skelL = branchesLabeled;

nanL = skelL;
nanL(nanL==0) = NaN;

%% trying modified version of image analyst's method - best so far!
% works well for single objects, not multiple
% dilatedL = replacenansinmask(nanL,I);
% dilatedL(isnan(dilatedL)) = 0;

% instead, we need to call it individually for each object to prevent overlapping labels
dilatedL = zeros(size(nanL));

props = regionprops(I,'PixelIdxList');

for i = 1:size(props)
    % get the branch labels for just this object
    temp_nanL = nanL;
    temp_nanL(~props(i).PixelIdxList) = NaN;
    % get the mask of just this object
    temp_mask = false(size(I));
    temp_mask(props(i).PixelIdxList) = 1;
    % get the label image for this object
    temp_dilatedL = replacenansinmask(temp_nanL,temp_mask);
    % add those labels to the full label image
    dilatedL(props(i).PixelIdxList) = temp_dilatedL(props(i).PixelIdxList);
end

dilatedLRGB = label2rgb(dilatedL);

%figure();imshow(dilatedLRGB);


end

% function out = replacenans(in)
% 
% u = in;
% 
% % Now find the nan's
% nanLocations = isnan(u);
% nanLinearIndexes = find(nanLocations);
% nonNanLinearIndexes = setdiff(1:numel(u), nanLinearIndexes);
% % Get the x,y,z of all other locations that are non nan.
% [xGood, yGood, zGood] = ind2sub(size(u), nonNanLinearIndexes);
% for index = 1 : length(nanLinearIndexes)
%   thisLinearIndex = nanLinearIndexes(index);
%   % Get the x,y,z location
%   [x,y,z] = ind2sub(size(u), thisLinearIndex);
%   % Get distances of this location to all the other locations
%   distances = sqrt((x-xGood).^2 + (y - yGood) .^ 2 + (z - zGood) .^ 2);
%   [sortedDistances, sortedIndexes] = sort(distances, 'ascend');
%   % The closest non-nan value will be located at index sortedIndexes(1)
%   indexOfClosest = sortedIndexes(1);
%   % Get the u value there.
%   goodValue = u(xGood(indexOfClosest), yGood(indexOfClosest), zGood(indexOfClosest));
%   % Replace the bad nan value in u with the good value.
%   u(x,y,z) = goodValue;
% end
% % u should be fixed now - no nans in it.
% % Double check.  Sum of nans should be zero now.
% % nanLocations = isnan(u);
% % numberOfNans = sum(nanLocations(:));
% 
% out = u;
% 
% end


function out = replacenansinmask(in,mask)

u = in;

% Now find the nan's
nanLocations = isnan(u) & mask;
nanLinearIndexes = find(nanLocations);

% and non-nans (only inside the mask)
nonNanLocations = ~isnan(u) & mask;
nonNanLinearIndexes = find(nonNanLocations);

%nonNanLinearIndexes = setdiff(1:numel(u), nanLinearIndexes);
% Get the x,y,z of all other locations that are non nan.
[xGood, yGood, zGood] = ind2sub(size(u), nonNanLinearIndexes);
for index = 1 : length(nanLinearIndexes)
  thisLinearIndex = nanLinearIndexes(index);
  % Get the x,y,z location
  % These are not actually x,y, and z coordinates in the mathematical sense!!!
  [x,y,z] = ind2sub(size(u), thisLinearIndex);
  % Get distances of this location to all the other locations
  distances = sqrt((x-xGood).^2 + (y - yGood) .^ 2 + (z - zGood) .^ 2);
  [sortedDistances, sortedIndexes] = sort(distances, 'ascend');
  % The closest non-nan value will be located at index sortedIndexes(1)
  indexOfClosest = sortedIndexes(1);
  % Get the u value there.
  goodValue = u(xGood(indexOfClosest), yGood(indexOfClosest), zGood(indexOfClosest));
  % Replace the bad nan value in u with the good value.
  u(x,y,z) = goodValue;
end

out = u;

end
