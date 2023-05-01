function boundaries = getPerfectBinaryBoundaries(I,Options)
% returns exact coordinates of the edges of a binary object
%% input validation
arguments
    I {mustBeA(I,'logical')}
    Options.method (1,:) char {mustBeMember(Options.method,{'loose','tight','tightest','cornersonly'})} = 'tightest'
    Options.interpResolution (1,1) double {mustEvenlyDivideIntoOne(Options.interpResolution)} = 1
    Options.conn (1,1) double {mustBeMember(Options.conn,[4,8])} = 8
end

switch Options.conn
    case 8
        % get the 8-connected components in this image
        CC_8conn = bwconncomp(I,8);
        % get the Image and BoundingBox for each object
        props_8conn = regionprops(CC_8conn,{'Image','BoundingBox'});
        % initialize cell array of boundaries
        boundaries = cell(CC_8conn.NumObjects,1);
        % for each 8-connected object
        for i = 1:CC_8conn.NumObjects
            % get the image for this 8-connected object
            thisI = props_8conn(i).Image;
            % get the individual 4-connected boundaries in this object
            boundaries_4conn = getPerfectBinaryBoundaries(...
                thisI,...
                "method",Options.method,...
                "interpResolution",Options.interpResolution,...
                "conn",4);
            % add the bounding box offset from the original 8-connected object to each of the object boundaries
            boundaries_4conn = cellfun(@(b) bsxfun(@plus,b,props_8conn(i).BoundingBox([2 1]) - 0.5),boundaries_4conn,'UniformOutput',0);
            % if number of boundaries is 1, we can simply continue
            if numel(boundaries_4conn)==1
                boundaries(i) = boundaries_4conn;
            else
                boundaries(i) = link4ConnectedBoundaries(boundaries_4conn);
            end
        end
    case 4
        % get the 4-connected components in this image
        CC_4conn = bwconncomp(I,4);
        % get the Image and BoundingBox of the 4-connected components
        ObjectProperties = regionprops(CC_4conn,{'Image','BoundingBox'});
        % get the field names of the ObjectProperties struct
        fnames = fieldnames(ObjectProperties);
        % convert ObjectProperties struct to cell array
        C = struct2cell(ObjectProperties).';
        % get object images (using struct fieldnames to find idx to 'Image' column in cell array)
        ObjectImages = C(:,ismember(fnames,'Image'));
        % get object bounding boxes (using fieldnames to find idx to 'BoundingBox' column in cell array)
        ObjectBBox = C(:,ismember(fnames,'BoundingBox'));
        % get boundaries from ObjectImages
        B = cellfun(@(obj_img)perfectBinaryBoundaries(padarray(obj_img,[1,1]),...
            "interpResolution",Options.interpResolution,...
            "method",Options.method),...
            ObjectImages,'UniformOutput',0);
        % add bounding box offsets to boundary coordinates from ObjectImages
        % box([2 1]) gives the (y,x) coordinates of the top-left corner of the box
        B = cellfun(@(b,box) bsxfun(@plus,b,box([2 1]) - 1.5),B,ObjectBBox,'UniformOutput',0);
        % return our cell array of 4-connected boundaries
        boundaries = B;
end

end

function linkedBoundaries = link4ConnectedBoundaries(unlinkedBoundaries)
    % recursion termination condition (we stop when there is only one boundary remaining)
    if numel(unlinkedBoundaries)==1
        linkedBoundaries = unlinkedBoundaries;
        return
    end
    % pull out the first boundary, this is the one we will try to link first
    boundary2Link = unlinkedBoundaries(1);
    % separate the rest of the boundaries, these are what we will check for matches to the boundary above
    boundaries2Check = unlinkedBoundaries(2:end);
    % for each boundary to check
    for k = 1:numel(boundaries2Check)
        % check for row matches
        [q,idx] = ismember(boundary2Link{1},boundaries2Check{k},'rows');
        % if a match was found
        if any(q)
            % the indices of the matching boundary coordinates we are trying to link
            % in the first boundary
            idx1 = find(idx);
            % and the second boundary
            idx2 = idx(idx1);
            % extract the arrays of boundary coordinates
            boundary1 = boundary2Link{1};
            boundary2 = boundaries2Check{k};
            % link them together
            newBoundary = [...
                boundary1(1:idx1,:);...
                boundary2(idx2+1:end-1,:);...
                boundary2(1:idx2,:);...
                boundary1(idx1+1:end,:)];
            % remove the boundary we linked to the first unlinked boundary
            boundaries2Check(k) = [];
            % recursive call with our new set of unlinked boundaries
            linkedBoundaries = link4ConnectedBoundaries([{newBoundary};boundaries2Check]);
            % finish once all calls have returned
            return
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