function [G,edges,Midline] = getObjectMidline(I,Options)
%%input validation

arguments
    I {mustBeA(I,'logical')}
    Options.BoundaryInterpolation {mustBeA(Options.BoundaryInterpolation,'logical')} = true
    Options.BoundarySmoothing {mustBeA(Options.BoundarySmoothing,'logical')} = true
    Options.MidlineInterpolation {mustBeA(Options.MidlineInterpolation,'logical')} = true
    Options.MidlineSmoothing {mustBeA(Options.MidlineSmoothing,'logical')} = true
    Options.DisplayResults {mustBeA(Options.DisplayResults,'logical')} = false
end

Iorig = I;

% end testing
midline_interp_res = 0.1;

%% determine the original object boundary using bwboundaries()

% get the object boundary coordinates
boundaries = bwboundaries(I,8);
% split into column vectors of x and y coordinates
boundariesx = boundaries{1}(:,2);
boundariesy = boundaries{1}(:,1);

orig_boundariesx = boundariesx;
orig_boundariesy = boundariesy;

%% Convert to polygon and measure perimeter, nPoints, and nEdges

% convert to polyshape, don't keep collinear points (won't take effect unless we simplify)
boundarypoly = polyshape(boundariesx(1:end),boundariesy(1:end),"KeepCollinearPoints",false,"Simplify",false);

%boundarypoly = simplify(boundarypoly);

% testing below, get buffer around polygon for larger boundary
d = 0.7071;
%boundarypoly = polybuffer(boundarypoly,d);
boundarypoly = polybuffer(boundarypoly,d,"JointType","round");
% % boundarypoly = simplify(boundarypoly);
% % end testing

% extract coordinates of the polyshape vertices, these are our new boundaries
boundariesx = [boundarypoly.Vertices(1:end,1);boundarypoly.Vertices(1,1)];
boundariesy = [boundarypoly.Vertices(1:end,2);boundarypoly.Vertices(1,2)];
% n points in the original boundary (subtract one to account for overlapping endpoints)
boundaryPoints = length(boundariesx)-1;
% get the perimeter of the boundary
boundaryPerimeter = boundarypoly.perimeter;
% same number of edges as number of unique vertices
boundaryEdges = boundaryPoints;
% determine the length of each edge of the boundary
lengthPerEdge = boundaryPerimeter/boundaryEdges;

%% interpolate and respace the boundary coordinates

if Options.BoundaryInterpolation
    % desired spacing between points after interpolation (we want less interpolation as the object gets larger)
    boundary_interp_res = log(nthroot(boundaryPerimeter,4))*1.5;

    % determine the number of edges to draw in the interpolated curve
    nEdgesDesired = ceil(boundaryPerimeter/boundary_interp_res);
    % if odd, make even (seems to work better for small objects)

    % % check if this helps or not
    % if mod(nEdgesDesired,2)
    %     nEdgesDesired = nEdgesDesired+1;
    % end

    % rescale the edge length to perfectly fit nEdgesDesired edges in our original boundary
    length1 = nEdgesDesired*boundary_interp_res;
    length2 = boundaryPerimeter;
    interpScale = length1/length2;
    boundary_interp_res = boundary_interp_res/interpScale;

    % using interparc interpolation method - seems to work better but need to tweak params
    nPointsDesired = round(boundaryPerimeter/boundary_interp_res)+1;

    % check which method is best
    %nPointsDesired = round(boundaryPerimeter/boundary_interp_res);

    % working method
    newPoints = interparc(nPointsDesired,boundariesx,boundariesy,'linear');

    boundariesx = newPoints(:,1);
    boundariesy = newPoints(:,2);

end

% save the interpolated boundaries for plotting
interp_boundariesx = boundariesx;
interp_boundariesy = boundariesy;

%% smooth out the boundary

if Options.BoundarySmoothing
    % get number of points to compute windowWidth
    interp_nBoundaries = length(boundariesx)-1;
    % degree of the polynomial and window width for Savitzky-Golay smoothing filter
    polynomialOrder = 2;
    % windowWidth must be odd and greater than polynomialOrder
    boundarySmoothWidth = max(round(interp_nBoundaries/10),7);
    if ~mod(boundarySmoothWidth,2) % if even
        boundarySmoothWidth = boundarySmoothWidth+1; % make odd
    end
    % smooth out the boundaries so that the majority of vertices within the mask are at the approximate centerline
    [boundariesx,boundariesy] = sgolayfilt_closedcurve(boundariesx,boundariesy,polynomialOrder,boundarySmoothWidth);


    % !important step! if we do not re-space boundary points after smoothing, we could end up with a very jagged midline
    %boundaryPerimeter = getCurveLength([boundariesx,boundariesy]);
    % we want the respaced boundary to have the same number of points
    nPointsDesired = numel(boundariesx);
    % now re-interpolate
    newPoints = interparc(nPointsDesired,boundariesx,boundariesy,'linear');
    boundariesx = newPoints(:,1);
    boundariesy = newPoints(:,2);

end

smooth_boundariesx = boundariesx;
smooth_boundariesy = boundariesy;

% could interpolate/respace again here, as smoothing changes the positions of coordinates
% -- code to respace here --
% end respace

%% Delaunay triangulation and Voronoi tesselation to find edges


%% testing below
% % convert to polyshape, don't keep collinear points (won't take effect unless we simplify)
% boundarypoly = polyshape(boundariesx(1:end),boundariesy(1:end),"KeepCollinearPoints",false,"Simplify",false);
% 
% % testing below, get buffer around polygon for larger boundary
% d = 0.7071;
% %boundarypoly = polybuffer(boundarypoly,d);
% boundarypoly = polybuffer(boundarypoly,d,"JointType","round");
% %boundarypoly = simplify(boundarypoly);
% % end testing
% 
% % extract coordinates of the polyshape vertices, these are our new boundaries
% boundariesx = [boundarypoly.Vertices(1:end,1);boundarypoly.Vertices(1,1)];
% boundariesy = [boundarypoly.Vertices(1:end,2);boundarypoly.Vertices(1,2)];
%% end testing



% extracting unique coordinates of the boundary for 
% Voronoi tesselation & Delaunay triangulation
x = boundariesx(1:end-1);
y = boundariesy(1:end-1);
% the number of coordinates
nstr = length(x);
% compute the Delaunay triangulation
DT = delaunayTriangulation(x,y);
 % construct Thiessen (Voronoi) polygons by Voronoi tesselation
[V,C] = DT.voronoiDiagram;
% get the triangle edges
dt_ed = DT.edges;
% indices to nodes representing the endpoints of edges of Delaunay traingles
istr = dt_ed(dt_ed(:,1)<=nstr,1);
neigh = dt_ed(dt_ed(:,1)<=nstr,2);

% initialize edge array
edge = nan(numel(istr),2);
% for each triangle edge
for i = 1:numel(istr)
    % get the two polygons linked by the triangle edge
    poly1 = C{istr(i)};
    poly2 = C{neigh(i)};
    % from those two polygons, get the overlapping Voronoi edge
    sharedEdge = poly1(ismember(poly1,poly2));
    % we only want the last two vertices if there are more than 2
    edge(i,:) = sharedEdge(:,end-1:end);
    % clear temps
    clear poly1 poly2 sharedEdge
end

%% find only edges within the object boundary

% get only those voronoi vertices within the object boundary
% v_inobj_idx = idxs to nodes inside object
v_inobj_idx = find(inpolygon(V(:,1),V(:,2),boundariesx,boundariesy));
% v_inobj = (x,y) coordinates of nodes inside object
v_inobj = V(v_inobj_idx,:);
% only keep unique values and do not sort
v_inobj = unique(v_inobj,'rows','stable');
% arrays to hold all edges and edge weights within the object boundary
edges = [];
weights = [];
% for each Voronoi edge
for i = 1:length(edge)
    % get the node idxs to the edge endpoints
    endIdx1 = edge(i,1);
    endIdx2 = edge(i,2);
    % get the endpoint coordinates (x,y)
    v1 = V(endIdx1,:);
    v2 = V(endIdx2,:);
    % if vertices are equivalent or non-finite
    if all(v1==v2) || any(v1==inf) || any(v2==inf)
        % then do not save the edge
        continue
    end
    % vertically concatenate the endpoint coords
    edgeLine = [v1;v2];

    if ismember(endIdx1,v_inobj_idx) && ismember(endIdx2,v_inobj_idx)
        % find idxs to the two nodes with respect to the list of nodes inside the object 
        NEWendIdx1 = find(ismember(v_inobj,v1,'rows'));
        NEWendIdx2 = find(ismember(v_inobj,v2,'rows'));
        % the edge is a 2-element row vector of those nodes
        NEWedge = [NEWendIdx1 NEWendIdx2];
        % add it to the list
        edges(end+1,:) = NEWedge;
        % calculate the edge weight (euclidean distances between nodes)
        weights(end+1,1) = sqrt((v1(1,1)-v2(1,1))^2+(v1(1,2)-v2(1,2))^2);
    end
end

%% construct an undirected graph, find the endpoints, then trace the shortest path between them

% create the undirected graph object
G = graph(edges(:,1),edges(:,2),weights);
% add a name for each node
nodenames = cell(size(v_inobj,1),1);
nodexcoord = [];
nodeycoord = [];
for i = 1:numel(nodenames)
    nodenames{i,1} = num2str(i);
    nodexcoord(i,1) = v_inobj(i,1);
    nodeycoord(i,1) = v_inobj(i,2);
end
G.Nodes.Name = nodenames;
G.Nodes.Xcoord = nodexcoord;
G.Nodes.Ycoord = nodeycoord;

% [~,ia,~] = unique(round([G.Nodes.Xcoord G.Nodes.Ycoord],4),'rows');
% G = subgraph(G,ia);


nDegreeGT2 = numel(find(degree(G)>2));
% attempt to prune the graph
while nDegreeGT2 > 0
    G = rmnode(G,find(degree(G)<2));

    temp = numel(find(degree(G)>2));

    % if the number of nodes with degree > 2 did not change
    if temp==nDegreeGT2
        % break to prevent infinite loop
        break
    else
        nDegreeGT2 = temp;
    end
end

% remove any isolated nodes
G = rmnode(G,find(degree(G)==0));

if numel(G.Nodes)==0
    G = [];
    edges = [];
    Midline = [];
    return
end

% % get the largest connected component if there is more than 1 graph component
% [bin,binsize] = conncomp(G,'Type','weak');
% idx = binsize(bin) == max(binsize);
% G = subgraph(G, idx);

% get the shortest distance between all nodes
d = distances(G);
% the largest distance represents the path between endpoint nodes
[maxDist,maxIdx] = max(d,[],'all');
% get node idxs from the linear idx found above (maxIdx)
[end1,end2] = ind2sub(size(d),maxIdx);


% % get the ordered list of nodes representing the midline
% midlinePathNodes = shortestpath(G,end1,end2);
% % reorder the graph
% G = reordernodes(G,midlinePathNodes);

try    
    % get the ordered list of nodes representing the midline
    midlinePathNodes = shortestpath(G,end1,end2);
    % reorder the graph
    G = reordernodes(G,midlinePathNodes);
catch
    [~,~,edgepath] = shortestpath(G,end1,end2);

    goodEdges = G.Edges.EndNodes(edgepath,:);
    goodNodes = Interleave2DArrays(goodEdges(:,1),goodEdges(:,2),'row');
    goodNodes = unique(goodNodes,'stable');
    goodNodes = [goodNodes(2);goodNodes(1);goodNodes(3:end)];
    G = subgraph(G,goodNodes);
end


% get the midline coordinates
Midline = [G.Nodes.Xcoord G.Nodes.Ycoord];

% get the endpoint coordinates
endNode1 = Midline(1,:);
endNode2 = Midline(end,:);


% % now get the (x,y) coordinates of those nodes
% endNode1 = v_inobj(end1,:);
% endNode2 = v_inobj(end2,:);
% 
% % finally, convert the node list to midline coordinates
% Midline = [v_inobj(midlinePathNodes,1),v_inobj(midlinePathNodes,2)];
% due to the use of floating point coordinates, there is a chance for "near duplicate" vertices
% so we will round the vertex coordinates and only keep the unique values
Midline = unique(round(Midline,8),'rows','stable');

curveLength = getCurveLength(Midline);

%% interpolate the midline curve

if Options.MidlineInterpolation && curveLength > 0.2
    % desired spacing between points after interpolation (we want less interpolation as the object gets larger)

    % how many edges desired in our final curve assuming the given interpolation resolution
    nEdgesDesired = ceil(curveLength/midline_interp_res);

    % rescale the edge length to perfectly fit nEdgesDesired edges in our original boundary
    length1 = nEdgesDesired*midline_interp_res;
    length2 = curveLength;
    interpScale = length1/length2;
    midline_interp_res = midline_interp_res/interpScale;

    % get the number of desired points
    nPointsDesired = round(curveLength/midline_interp_res)+1;

    % using interparc interpolation method - seems to work better but need to tweak params
    Midline = interparc(nPointsDesired,Midline(:,1),Midline(:,2),'linear');

end

%% smooth out the midline curve

if Options.MidlineSmoothing && curveLength > 1

    xPoints = Midline(:,1);
    yPoints = Midline(:,2);
    % get number of points to compute windowWidth
    interp_nMidline = size(Midline,1);
    % degree of the polynomial and window width for Savitzky-Golay smoothing filter
    polynomialOrder = 2;
    % windowWidth must be odd, greater than polynomialOrder, <= input frame (curve)
    midlineSmoothWidth = min(max(round(interp_nMidline/6),9),interp_nMidline);
    if ~mod(midlineSmoothWidth,2) % if even
        midlineSmoothWidth = midlineSmoothWidth+1; % make odd
    end
    % smooth out the boundaries so that the majority of vertices within the mask are at the approximate centerline
    [xPoints,yPoints] = sgolayfilt_opencurve(xPoints,yPoints,polynomialOrder,midlineSmoothWidth);

    Midline = [xPoints, yPoints];
end


%% Plot the results

if Options.DisplayResults
    % show the original input image
    hImg = imshow2(Iorig);
    hold on
    alphaData = ones(size(I));
    alphaData(I) = 0.5;
    hImg.AlphaData = alphaData;
    % plot the voronoi tesselation
    voronoi(x,y);
    % plot all the *finite* edges found as solid blue lines
    for i = 1:size(edge,1)
        v1idx = edge(i,1);
        v2idx = edge(i,2);
        v1 = V(v1idx,:);
        v2 = V(v2idx,:);
        plot([v1(1,1) v2(1,1)],[v1(1,2) v2(1,2)],...
            'LineStyle','-',...
            'Color',[0 0 1],...
            'LineWidth',2,...
            'DisplayName','');
    end
    % plot the edges found within the object as solid red lines
    for i = 1:size(edges,1)
        v1idx = edges(i,1);
        v2idx = edges(i,2);
        v1 = v_inobj(v1idx,:);
        v2 = v_inobj(v2idx,:);
        plot([v1(1,1) v2(1,1)],[v1(1,2) v2(1,2)],'LineStyle','-','Color',[1 0 0],'LineWidth',2,'Marker','o');
    end

    % plot the original boundary
    p1 = plot(orig_boundariesx,orig_boundariesy,...
        'LineStyle','-',...
        'LineWidth',2,...
        'Color',[1 0 1],...
        'Marker','none',...
        'DisplayName','8-connected boundary');
    % plot the boundaries after interpolation
    p2 = plot(interp_boundariesx,interp_boundariesy,...
        'LineStyle','--',...
        'LineWidth',2,...
        'Color',[1 0 0],...
        'Marker','none',...
        'DisplayName','Interpolated boundary');
    % plot the boundaries after smoothing
    p3 = plot(smooth_boundariesx,smooth_boundariesy,...
        'LineStyle','--',...
        'LineWidth',2,...
        'Color',[1 1 0],...
        'Marker','none',...
        'DisplayName','Smooth boundary');


    % plot the midline as a dotted black line
    p4 = plot(Midline(:,1),Midline(:,2),...
        'LineStyle',':',...
        'LineWidth',3,...
        'Color',[0 0 0],...
        'Marker','none',...
        'DisplayName','Midline');
    % plot the endpoint coordinates as red stars
    p5 = plot([endNode1(1,1) endNode2(1,1)],[endNode1(1,2) endNode2(1,2)],...
        'Marker','pentagram',...
        'MarkerSize',15,...
        'LineStyle','none',...
        'MarkerFaceColor',[1 0 0],...
        'DisplayName','Endpoint nodes');

    hold off
    legend([p1 p2 p3 p4 p5])
end

end % end of main function