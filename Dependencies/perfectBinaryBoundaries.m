function boundaries = perfectBinaryBoundaries(I,Options)
% returns exact coordinates of the edges of a binary object
%% input validation
arguments
    I {mustBeA(I,'logical')}
    Options.method (1,:) char {mustBeMember(Options.method,{'loose','tight','tightest','cornersonly'})} = 'tightest'
    Options.interpResolution (1,1) double {mustEvenlyDivideIntoOne(Options.interpResolution)} = 1
end

% size of the input
Isz = size(I);

% initialize boundaries coordinate list (1x2 double | [y,x])
boundaries = [];
edgeMidpoints = [];

%% define the types of neighborhoods we are searching for to locate our edge pixels
% first the outer corners
% upper left corner (also shows target pixel for each of our 2x2 luts, see below)
corners{1} = [...
    1 0;...
    0 0 ...
    ];
% lower left corner
corners{2} = [...
    0 0;...
    1 0 ...
    ];
% upper right corner
corners{3} = [...
    0 1;...
    0 0 ...
    ];
% lower right corner
corners{4} = [...
    0 0;...
    0 1 ...
    ];
% now the inner corners
% upper left corner missing
incorners{1} = [...
    0 1;...
    1 1 ...
    ];
% lower left corner missing
incorners{2} = [...
    1 1;...
    0 1 ...
    ];
% upper right corner missing
incorners{3} = [...
    1 0;...
    1 1 ...
    ];
% lower right corner missing
incorners{4} = [...
    1 1;...
    1 0 ...
    ];
% finally, the flat edges
% vertical 2-pixel edge
flatedge{1} = [...
    1 0;...
    1 0 ...
    ];
% horizontal 2-pixel edge
flatedge{2} = [...
    1 1;...
    0 0 ...
    ];

%% find inner and outer corner pixels, store coordinates of the corners of those corner pixels and of midpoints of corner pixel edges

r = cell(6,1);
c = cell(6,1);

[r{1},c{1}] = ind2sub(Isz,find(bwlookup(I,makelut(@(x) all(x(:)==corners{1}(:)) || all(x(:)==incorners{1}(:)),2))));
boundaries = [r{1} + 0.5, c{1} + 0.5; r{1}, c{1} + 0.5; r{1} + 0.5, c{1}];
edgeMidpoints = [r{1}, c{1} + 0.5; r{1} + 0.5, c{1}];

[r{2},c{2}] = ind2sub(Isz,find(bwlookup(I,makelut(@(x) all(x(:)==corners{2}(:)) || all(x(:)==incorners{2}(:)),2))));
boundaries = [boundaries; r{2} + 0.5, c{2} + 0.5; r{2} + 0.5, c{2}; r{2} + 1, c{2} + 0.5];
edgeMidpoints = [edgeMidpoints; r{2} + 0.5, c{2}; r{2} + 1, c{2} + 0.5];

[r{3},c{3}] = ind2sub(Isz,find(bwlookup(I,makelut(@(x) all(x(:)==corners{3}(:)) || all(x(:)==incorners{3}(:)),2))));
boundaries = [boundaries; r{3} + 0.5, c{3} + 0.5; r{3}, c{3} + 0.5; r{3} + 0.5, c{3} + 1];
edgeMidpoints = [edgeMidpoints; r{3}, c{3} + 0.5; r{3} + 0.5, c{3} + 1];

[r{4},c{4}] = ind2sub(Isz,find(bwlookup(I,makelut(@(x) all(x(:)==corners{4}(:)) || all(x(:)==incorners{4}(:)),2))));
boundaries = [boundaries; r{4} + 0.5, c{4} + 0.5; r{4} + 1, c{4} + 0.5; r{4} + 0.5, c{4} + 1];
edgeMidpoints = [edgeMidpoints; r{4} + 1, c{4} + 0.5; r{4} + 0.5, c{4} + 1];

%% find edge pixels, store coordinates of the corners and midpoints of those edges

[r{5},c{5}] = ind2sub(Isz,find(bwlookup(I,makelut(@(x) checkEdgeMatch(x,flatedge{1}),2))));
boundaries = [boundaries; r{5} + 0.5, c{5} + 0.5; r{5}, c{5} + 0.5; r{5} + 1, c{5} + 0.5];
edgeMidpoints = [edgeMidpoints; r{5}, c{5} + 0.5; r{5} + 1, c{5} + 0.5];

[r{6},c{6}] = ind2sub(Isz,find(bwlookup(I,makelut(@(x) checkEdgeMatch(x,flatedge{2}),2))));
boundaries = [boundaries; r{6} + 0.5, c{6} + 0.5; r{6} + 0.5, c{6}; r{6} + 0.5, c{6} + 1];
edgeMidpoints = [edgeMidpoints; r{6} + 0.5, c{6}; r{6} + 0.5, c{6} + 1];

%% uncondensed version of above code

% %% corners{1} and incorners{1}
% % anonymous lut function
% cornerlutfun = @(x) all(x(:)==corners{1}(:)) || all(x(:)==incorners{1}(:));
% % create 2x2 lut using function handle above
% cornerlut = makelut(cornerlutfun,2);
% % image representing locations of target pixels whose nhoods match corner{1}
% cornerlocations = bwlookup(I,cornerlut);
% % linear indices of the corner pixels we just found
% cornerIdx = find(cornerlocations);
% % now convert them to row and column coordinates (of the centers of those pixels)
% [r,c] = ind2sub(Isz,cornerIdx);
% % finally, get the x,y coordinates to the actual corner of those corner pixels
% y = r + 0.5;
% x = c + 0.5;
% % add those coordinates to the coordinate list
% boundaries = [boundaries;y x];
% 
% % now get coordinates to the center of pixel edges
% y = r;
% x = c + 0.5;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% y = r + 0.5;
% x = c;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
%
% %% corners{2} and incorners{2}
% % anonymous lut function
% cornerlutfun = @(x) all(x(:)==corners{2}(:)) || all(x(:)==incorners{2}(:));
% % create 2x2 lut using function handle above
% cornerlut = makelut(cornerlutfun,2);
% % image representing locations of target pixels whose nhoods match corner{1}
% cornerlocations = bwlookup(I,cornerlut);
% % linear indices of the corner pixels we just found
% cornerIdx = find(cornerlocations);
% % now convert them to row and column coordinates (of the centers of those pixels)
% [r,c] = ind2sub(Isz,cornerIdx);
% % finally, get the x,y coordinates to the actual corner of those corner pixels
% y = r + 0.5;
% x = c + 0.5;
% % add those coordinates to the coordinate list
% boundaries = [boundaries;y x];
% 
% % now get coordinates to the center of pixel edges
% y = r + 0.5;
% x = c;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% y = r + 1;
% x = c + 0.5;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% %% corners{3} and incorners{3}
% % anonymous lut function
% cornerlutfun = @(x) all(x(:)==corners{3}(:)) || all(x(:)==incorners{3}(:));
% % create 2x2 lut using function handle above
% cornerlut = makelut(cornerlutfun,2);
% % image representing locations of target pixels whose nhoods match corner{1}
% cornerlocations = bwlookup(I,cornerlut);
% % linear indices of the corner pixels we just found
% cornerIdx = find(cornerlocations);
% % now convert them to row and column coordinates (of the centers of those pixels)
% [r,c] = ind2sub(Isz,cornerIdx);
% % finally, get the x,y coordinates to the actual corner of those corner pixels
% y = r + 0.5;
% x = c + 0.5;
% % add those coordinates to the coordinate list
% boundaries = [boundaries;y x];
% 
% % now get coordinates to the center of pixel edges
% y = r;
% x = c + 0.5;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% y = r + 0.5;
% x = c + 1;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% %% corners{4} and incorners{4}
% % anonymous lut function
% cornerlutfun = @(x) all(x(:)==corners{4}(:)) || all(x(:)==incorners{4}(:));
% % create 2x2 lut using function handle above
% cornerlut = makelut(cornerlutfun,2);
% % image representing locations of target pixels whose nhoods match corner{1}
% cornerlocations = bwlookup(I,cornerlut);
% % linear indices of the corner pixels we just found
% cornerIdx = find(cornerlocations);
% % now convert them to row and column coordinates (of the centers of those pixels)
% [r,c] = ind2sub(Isz,cornerIdx);
% % finally, get the x,y coordinates to the actual corner of those corner pixels
% y = r + 0.5;
% x = c + 0.5;
% % add those coordinates to the coordinate list
% boundaries = [boundaries;y x];
% 
% % now get coordinates to the center of pixel edges
% y = r + 1;
% x = c + 0.5;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% y = r + 0.5;
% x = c + 1;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
%
% %% flatedge{1} (vertical 2-pixel edge)
% % anonymous lut function for a vertical 2-pixel edge
% edgelutfun = @(x) checkEdgeMatch(x,flatedge{1});
% % create 2x2 lut using function handle above
% edgelut = makelut(edgelutfun,2);
% % image representing locations of target pixels whose nhoods match edge{1} or any of its n*90° rotations
% edgelocations = bwlookup(I,edgelut);
% % linear idxs of the target pixel in 2x2 nhoods matching the edge or any of its n*90° rotations
% edgeIdx = find(edgelocations);
% % now convert them to row and column coordinates (of the centers of those pixels)
% [r,c] = ind2sub(Isz,edgeIdx);
% % we don't need to add an offset to get to the target pixel, the coordinate we want is at the center
% % of the 2x2 nhood
% y = r + 0.5;
% x = c + 0.5;
% % add those coordinates to the coordinate list
% boundaries = [boundaries;y x];
% 
% % now get coordinates to the center of pixel edges
% y = r;
% x = c + 0.5;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% y = r + 1;
% x = c + 0.5;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% %% flatedge{2} (horizontal 2-pixel edge)
% % anonymous lut function for a vertical 2-pixel edge
% edgelutfun = @(x) checkEdgeMatch(x,flatedge{2});
% % create 2x2 lut using function handle above
% edgelut = makelut(edgelutfun,2);
% % image representing locations of target pixels whose nhoods match edge{1} or any of its n*90° rotations
% edgelocations = bwlookup(I,edgelut);
% % linear idxs of the target pixel in 2x2 nhoods matching the edge or any of its n*90° rotations
% edgeIdx = find(edgelocations);
% % now convert them to row and column coordinates (of the centers of those pixels)
% [r,c] = ind2sub(Isz,edgeIdx);
% % we don't need to add an offset to get to the target pixel, the coordinate we want is at the center
% % of the 2x2 nhood
% y = r + 0.5;
% x = c + 0.5;
% % add those coordinates to the coordinate list
% boundaries = [boundaries;y x];
% 
% % now get coordinates to the center of pixel edges
% y = r + 0.5;
% x = c;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];
% 
% y = r + 0.5;
% x = c + 1;
% boundaries = [boundaries;y x];
% edgeMidpoints = [edgeMidpoints;y x];

%% now sort the coordinates to trace the object boundary

try
    % make sure we only have unique vetices
    boundaries = unique(boundaries,'rows','stable');
    % then swap x and y columns
    boundaries = [boundaries(:,2) boundaries(:,1)];
    % try and sort the coordinates
    boundaries = traceFromEndpoint(boundaries(1,:),boundaries(2:end,:));
    % switch back to [y,x] format
    boundaries = [boundaries(:,2) boundaries(:,1)];
catch
    blah = 0;
end

%% adjust which coordinates we keep based on method chosen

switch Options.method
    case 'loose'
        % get coordinates to the outer corners
        outerCorners = getOuterCorners();
        % remove any boundaries that are not outer corners
        boundaries = unique(boundaries(ismember(boundaries,outerCorners,'rows'),:),'rows','stable');
        % set new endpoints
        boundaries(end+1,:) = boundaries(1,:);
    case 'tight'
        % get coordinates to the inner corners
        innerCorners = getInnerCorners();
        % remove any boundary coordinates that are inner corners
        boundaries = unique(boundaries(~ismember(boundaries,innerCorners,'rows'),:),'rows','stable');
        % remove any boundary coordinates that are edge midpoints
        boundaries = unique(boundaries(~ismember(boundaries,edgeMidpoints,'rows'),:),'rows','stable');
        % set new endpoints
        boundaries(end+1,:) = boundaries(1,:);
    case 'tightest'
        % remove any boundary coordinates that are edge midpoints
        boundaries = unique(boundaries(~ismember(boundaries,edgeMidpoints,'rows'),:),'rows','stable');
        % set new endpoints
        boundaries(end+1,:) = boundaries(1,:);
        % if we want to interpolate, use the code below
        curveLength = getCurveLength([boundaries(:,2),boundaries(:,1)]);
        interpResolution = Options.interpResolution;

        boundariesXY = interparc((curveLength/interpResolution)+1,boundaries(:,2),boundaries(:,1),'linear');
        boundaries = [boundariesXY(:,2) boundariesXY(:,1)];

    case 'cornersonly'
        % get coordinates to the outer corners
        outerCorners = getOuterCorners();
        % get coordinates to the inner corners
        innerCorners = getInnerCorners();
        % concatenate outer and inner corner coordinate lists
        allCorners = [outerCorners; innerCorners];
        % remove any boundaries that are not inner or outer corners
        boundaries = unique(boundaries(ismember(boundaries,allCorners,'rows'),:),'rows','stable');
        % set new endpoints
        boundaries(end+1,:) = boundaries(1,:);
end


    function innerCorners = getInnerCorners()
        % anonymous lut function for a 2x2 outer corner 
        innercornerlutfun = @(x) checkInnerCornerMatch(x);
        % create 2x2 lut using function handle above
        innercornerlut = makelut(innercornerlutfun,2);
        % image representing locations of target pixels whose nhoods match edge{1} or any of its n*90° rotations
        innercornerlocations = bwlookup(I,innercornerlut);
        % linear idxs of the target pixel in 2x2 nhoods matching the edge or any of its n*90° rotations
        innercornerIdx = find(innercornerlocations);
        % now convert them to row and column coordinates (of the centers of those pixels)
        [R,C] = ind2sub(Isz,innercornerIdx);
        % the coordinate of the corner of each corner pixel in a 2x2 nhood is at the center, so adjust x and y
        Y = R + 0.5;
        X = C + 0.5;
        % remove duplicates
        innerCorners = unique([Y X],"rows","stable");
    end

    function match = checkInnerCornerMatch(nhood)
        % check each nhood to see if it matches the any of the reference nhoods
        % default result (no match found)
        match = false;
        % check for match with each of the four corners
        for i = 1:4
            % pull the lut into ref
            ref = incorners{i};
            % check for a match with the lut
            if all(nhood(:)==ref(:))
                match = true;
                return
            end
        end
    end

    function outerCorners = getOuterCorners()
        % anonymous lut function for a 2x2 outer corner 
        outercornerlutfun = @(x) checkCornerMatch(x);
        % create 2x2 lut using function handle above
        outercornerlut = makelut(outercornerlutfun,2);
        % image representing locations of target pixels whose nhoods match edge{1} or any of its n*90° rotations
        outercornerlocations = bwlookup(I,outercornerlut);
        % linear idxs of the target pixel in 2x2 nhoods matching the edge or any of its n*90° rotations
        outercornerIdx = find(outercornerlocations);
        % now convert them to row and column coordinates (of the centers of those pixels)
        [R,C] = ind2sub(Isz,outercornerIdx);
        % the coordinate of the corner of each corner pixel in a 2x2 nhood is at the center, so adjust x and y
        Y = R + 0.5;
        X = C + 0.5;
        % remove duplicates
        outerCorners = unique([Y X],"rows","stable");
    end

    function match = checkEdgeMatch(nhood,ref)
        % check each nhood to see if it matches the any of the reference nhoods
        % default result (no match found)
        match = false;
        % check for a match with the edge
        if all(nhood(:)==ref(:))
            match = true;
            return
        end    
        % rotate the edge 180° and check for a match again
        ref = rot90(ref,2);
        if all(nhood(:)==ref(:))
            match = true;
            return
        end
    end

    function match = checkCornerMatch(nhood)
        % check each nhood to see if it matches the any of the reference nhoods
        % default result (no match found)
        match = false;
        % check for match with each of the four corners
        for i = 1:4
            % pull the lut into ref
            ref = corners{i};
            % check for a match with the lut
            if all(nhood(:)==ref(:))
                match = true;
                return
            end
        end
    end
end


function mustEvenlyDivideIntoOne(a)
    % if interpolation resolution does not evenly divide into 1
    if mod(1,a)~=0
        eidType = 'mustEvenlyDivideIntoOne:doesNotEvenlyDivideIntoOne';
        msgType = 'Interpolation resolution must evenly divide into 1';
        throwAsCaller(MException(eidType,msgType))
    end
end


