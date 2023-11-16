function L = voronoiBranchLabels(I)
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

%% setup
    % store the size of the input
    Isz = size(I);
    % preallocate our output label matrix
    L = zeros(Isz);
%% separate the branches from each other
    % skeletonize the binary image (works better if we thin first)
    binarySkeleton = bwmorph(I,"thin",inf);
    binarySkeleton = bwskel(binarySkeleton);
    % get the branchpoints from the skeletonized binary image
    branchPoints = bwmorph(binarySkeleton,'branchpoints');
    % remove branchpoints so we are left with only branches
    branches = imsubtract(binarySkeleton,branchPoints);

    % find connected components
    CC = bwconncomp(branches,8);

    % (1xCC.NumObjects) cell array of unique object labels
    labelCell = num2cell(1:CC.NumObjects)';

    % cell array of individual branch px idxs
    pixelIdxs = CC.PixelIdxList';

    fullLabelCell = cellfun(@(lbl,idx) repmat(lbl,numel(idx),1),labelCell,pixelIdxs,"UniformOutput",0);
    fullLabelCell = num2cell(cat(1,fullLabelCell{:}));


    % get list of row and col coordinates
    [skelR,skelC] = ind2sub(Isz,cat(1,pixelIdxs{:}));

    % concatenate to form skeleton points array
    skelP = [skelC,skelR];

    % form an additional set of temporary boundary points (this is to prevent non-finite vertices in branch voronoi diagram)
    tempI = false(size(I));
    %tempI = padarray(tempI,[1,1],true);
    tempI(1:end,1) = true;
    tempI(1:end,end) = true;
    tempI(1,1:end) = true;
    tempI(end,1:end) = true;


    [tempR,tempC] = find(tempI);
    tempP = [tempC,tempR];
    nTempP = size(tempP,1);

    % concatenate to form the seeds of the voronoi diagram
    voronoiPoints = [tempP;skelP];

    % compute voronoi diagram
    [V,C] = voronoin(voronoiPoints,{'Qz'});

    % remove cells corresponding to the temporary points
    C(1:nTempP) = [];

    % % temporary testing below
    % % plot the branch mask image plus bounding pixels
    % imshow(branches | tempI); hold on;
    % % overlay the voronoi diagram
    % voronoi(voronoiPoints(:,1),voronoiPoints(:,2));
    % 
    % % nPoints = size(voronoiPoints,1);
    % % pointLabels = arrayfun(@(n) {sprintf('X%d', n)}, (1:nPoints)');
    % % text(voronoiPoints(:,1), voronoiPoints(:,2), pointLabels, 'FontWeight', ...
    % %     'bold', 'HorizontalAlignment','center',...
    % %     'BackgroundColor', 'none');
    % %nPoints = size(skelP,1);
    % 
    % % make branch labels for each pixel and plot them as text objects
    % pointLabels = arrayfun(@(n) {sprintf('L%d', n)}, cell2mat(fullLabelCell));
    % text(skelP(:,1), skelP(:,2), pointLabels, 'FontWeight', ...
    %     'bold', 'HorizontalAlignment','center',...
    %     'BackgroundColor', 'none');
    % % end testing


    cellfun(@(verticesIdxs,pixelLabels) updateLabelsWithVoronoiCells(verticesIdxs,pixelLabels),C,fullLabelCell,'UniformOutput',0);

    function updateLabelsWithVoronoiCells(verticesIdxs,pixelLabels)
        % get the (x,y) coordinates of this set of vertices
        coords = V(verticesIdxs,:);
        % build mask from those coordinates
        BW = roipoly(I,coords(:,1),coords(:,2));
        % set all pixels of the mask to the corresponding label in the output
        L(BW) = pixelLabels;
    end

    % set all pixels outside the mask to 0 in the label matrix
    L(~I) = 0;

end