function [G,edges,Midline] = getObjectMidline2(I,Options)
%% input validation
arguments
    I {mustBeA(I,'logical')}
    Options.BoundaryInterpolation {mustBeA(Options.BoundaryInterpolation,'logical')} = true
    Options.BoundarySmoothing {mustBeA(Options.BoundarySmoothing,'logical')} = true
    Options.MidlineInterpolation {mustBeA(Options.MidlineInterpolation,'logical')} = true
    Options.MidlineSmoothing {mustBeA(Options.MidlineSmoothing,'logical')} = true
    Options.DisplayResults {mustBeA(Options.DisplayResults,'logical')} = false
end

% store the original input image
Iorig = I;

% midline interpolation resolution
midline_interp_res = 0.1;

%% determine the original object boundary using bwboundaries()


boundaries = perfectBinaryBoundaries(I,"method","tightest");
boundariesx = boundaries(:,2);
boundariesy = boundaries(:,1);

orig_boundariesx = boundariesx;
orig_boundariesy = boundariesy;

%% Convert to polygon and measure perimeter, nPoints, and nEdges

% convert to polyshape, don't keep collinear points (won't take effect unless we simplify)
boundarypoly = polyshape(boundariesx(1:end),boundariesy(1:end),"KeepCollinearPoints",false,"Simplify",false);

% % testing below, get buffer around polygon for larger boundary
% d = 0.7071;
% boundarypoly = polybuffer(boundarypoly,d,"JointType","round");
% end testing

% extract coordinates of the polyshape vertices, these are our new boundaries
boundariesx = [boundarypoly.Vertices(1:end,1);boundarypoly.Vertices(1,1)];
boundariesy = [boundarypoly.Vertices(1:end,2);boundarypoly.Vertices(1,2)];
% n points in the original boundary (subtract one to account for overlapping endpoints)
% boundaryPoints = length(boundariesx)-1;
% get the perimeter of the boundary
boundaryPerimeter = boundarypoly.perimeter;

% % same number of edges as number of unique vertices
% boundaryEdges = boundaryPoints;
% % determine the average length of each edge of the boundary
% lengthPerEdge = boundaryPerimeter/boundaryEdges;

%% interpolate and respace the boundary coordinates

if Options.BoundaryInterpolation
    % METHOD 1
    % desired spacing between points after interpolation (we want less interpolation as the object gets larger)
    boundary_interp_res = log(nthroot(boundaryPerimeter,4))*1.5;
    % determine the number of edges to draw in the interpolated curve
    nEdgesDesired = ceil(boundaryPerimeter/boundary_interp_res);
    % rescale the edge length to perfectly fit nEdgesDesired edges in our original boundary
    length1 = nEdgesDesired*boundary_interp_res;
    length2 = boundaryPerimeter;
    interpScale = length1/length2;
    boundary_interp_res = boundary_interp_res/interpScale;
    % using interparc interpolation method - seems to work better but need to tweak params
    nPointsDesired = round(boundaryPerimeter/boundary_interp_res)+1;
    % working method
    newPoints = interparc(nPointsDesired,boundariesx,boundariesy,'linear');
    boundariesx = newPoints(:,1);
    boundariesy = newPoints(:,2);
    % END METHOD 1


    % METHOD 2
    % newPoints = approximateRespaceCurve([boundariesx,boundariesy],0.2);
    % boundariesx = newPoints(:,1);
    % boundariesy = newPoints(:,2);
    % END METHOD 2

end

% save the interpolated boundaries for plotting
interp_boundariesx = boundariesx;
interp_boundariesy = boundariesy;

%% smooth out the boundary

if Options.BoundarySmoothing
    % % METHOD 1
    % % get number of points to compute windowWidth
    % interp_nBoundaries = length(boundariesx)-1;
    % % degree of the polynomial and window width for Savitzky-Golay smoothing filter
    % polynomialOrder = 2;
    % % windowWidth must be odd and greater than polynomialOrder
    % boundarySmoothWidth = max(round(interp_nBoundaries/10),7);
    % if ~mod(boundarySmoothWidth,2) % if even
    %     boundarySmoothWidth = boundarySmoothWidth+1; % make odd
    % end
    % % smooth out the boundaries so that the majority of vertices within the mask are at the approximate centerline
    % [boundariesx,boundariesy] = sgolayfilt_closedcurve(boundariesx,boundariesy,polynomialOrder,boundarySmoothWidth);
    % % !important step! if we do not re-space boundary points after smoothing, we could end up with a very jagged midline
    % %boundaryPerimeter = getCurveLength([boundariesx,boundariesy]);
    % % we want the respaced boundary to have the same number of points
    % nPointsDesired = numel(boundariesx);
    % % now re-interpolate
    % newPoints = interparc(nPointsDesired,boundariesx,boundariesy,'linear');
    % boundariesx = newPoints(:,1);
    % boundariesy = newPoints(:,2);
    % % END METHOD 1


    % METHOD 2
    newPoints = smoothBoundaries([boundariesy,boundariesx]);
    boundariesx = newPoints(:,2);
    boundariesy = newPoints(:,1);
    % END METHOD 2
end

smooth_boundariesx = boundariesx;
smooth_boundariesy = boundariesy;

%% Delaunay triangulation and Voronoi tesselation to find edges

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
% indices to nodes representing the endpoints of edges of Delaunay triangles
istr = dt_ed(dt_ed(:,1)<=nstr,1);
neigh = dt_ed(dt_ed(:,1)<=nstr,2);

% preallocate edge array - holds all shared edges
edge = nan(numel(istr),2);

% get idxs to Voronoi nodes within the object boundary
v_inobj_idx = find(inpolygon(V(:,1),V(:,2),boundariesx,boundariesy));
% using those idxs, get the actual (x,y) coordinates of each Voronoi node
v_inobj = V(v_inobj_idx,:);

% preallocate array of edges and weights, should be one less edge than there are nodes in the object
edges = zeros(numel(v_inobj_idx)-1,2);
weights = zeros(numel(v_inobj_idx)-1,1);
edgeCounter = 1;

% for each triangle edge
for i = 1:numel(istr)
    % get the two polygons linked by the triangle edge
    poly1 = C{istr(i)};
    poly2 = C{neigh(i)};
    % from those two polygons, get the overlapping Voronoi edge
    sharedEdge = poly1(ismember(poly1,poly2));
    % we only want the last two vertices if there are more than 2
    edge(i,:) = sharedEdge(:,end-1:end);
    % get the node idxs to the edge endpoints
    endIdx1 = edge(i,1);
    endIdx2 = edge(i,2);
    % try to find those edge endpoints in our list of Voronoi nodes within the object
    NEWendIdx1 = find(v_inobj_idx==endIdx1);
    NEWendIdx2 = find(v_inobj_idx==endIdx2);
    % if both found
    if ~(isempty(NEWendIdx1) || isempty(NEWendIdx2))
        % add a new edge to our list
        edges(edgeCounter,:) = [NEWendIdx1 NEWendIdx2];
        % get (x,y) coordinates to the two endpoints of the edge
        v1 = V(endIdx1,:);
        v2 = V(endIdx2,:);
        % compute the edge weight as the Euclidean distance between them
        weights(edgeCounter,1) = sqrt((v1(1,1)-v2(1,1))^2+(v1(1,2)-v2(1,2))^2);
        % increment the edge counter
        edgeCounter = edgeCounter+1;
    end
end


%% construct an undirected graph, trim any branches, find the endpoints, then trace the shortest path between them

% create an undirected graph using the edges and edge weights we jsut found
G = graph(edges(:,1),edges(:,2),weights);
% create a cell array of character vectors from the node idxs to use as the node names for the graph
G.Nodes.Name = arrayfun(@num2str, (1:G.numnodes).', 'UniformOutput', 0);
% add x and y coordinate information for each node in the graph
G.Nodes.Xcoord = v_inobj(:,1);
G.Nodes.Ycoord = v_inobj(:,2);

% trim the graph (remove all but the longest two branches)
G = trimGraph(G);

% remove any isolated nodes
G = rmnode(G,find(degree(G)==0));

% if there are no remaining nodes (possible if 'I' contains a circularly symmetric object)
if numel(G.Nodes)==0
    % return empty
    G = []; edges = []; Midline = [];
    return
end

% at this point, there should only be two endpoint nodes
endpointNodes = find(degree(G)==1);

if numel(endpointNodes) > 2
    error('There should only be two endpoint nodes remaining');
end

% get the path from one endpointNode to the other
midlinePathNodes = shortestpath(G,endpointNodes(1),endpointNodes(2));

% reorder the graph accordingly
G = reordernodes(G,midlinePathNodes);

% finally, convert the node list to midline coordinates
Midline = [G.Nodes.Xcoord G.Nodes.Ycoord];

% due to the use of floating point coordinates, there is a chance for "near duplicate" vertices
% so we will round the vertex coordinates and only keep the unique values
Midline = unique(round(Midline,8),'rows','stable');

% get the midline endpoint coordinates
endNode1 = Midline(1,:);
endNode2 = Midline(end,:);

% get the length of the midline (in pixels)
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
            'Color',[0.0745 0.6235 1],...
            'LineWidth',2,...
            'DisplayName','');
    end
    % plot the edges found within the object as solid red lines
    for i = 1:size(edges,1)
        v1idx = edges(i,1);
        v2idx = edges(i,2);
        v1 = v_inobj(v1idx,:);
        v2 = v_inobj(v2idx,:);
        plot([v1(1,1) v2(1,1)],[v1(1,2) v2(1,2)],'LineStyle','-','Color',[1 0 0],'LineWidth',2,'Marker','none');
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