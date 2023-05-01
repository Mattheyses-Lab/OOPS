function polarHistogram(nbins,polarData,cmap)
% num_triangles: the number of triangles to use to approximate the circle

if isempty(cmap)
    cmap = vertcat(hsv,hsv);
else
    cmap = vertcat(cmap,cmap);
end

nColors = length(cmap);

% construct the bin edges 
binEdges = linspace(0, 2*pi, nbins+1);

% Calculate the counts in each bin
hist_counts = histcounts(polarData, binEdges);
hist_counts(end+1) = hist_counts(1);

% determine the maximum number of bin counts
maxCounts = max(hist_counts);

upperLim = 0;
increment = 1;

while upperLim <= maxCounts
    if upperLim == increment*10
        increment = increment.*10;
    end
    upperLim = upperLim + increment;
end

% get the radii of the circles to draw and the number of circles
radii = (increment:increment:upperLim).';
numCircles = numel(radii);

% Define the center of the circle
center = [0, 0];

% Create a figure and axis
ax = axes();
hold on

% plot the circles that will show our bin count grid
hCircles = viscircles(ax,repmat([0,0],numCircles,1),radii);
set(hCircles.Children(:),'LineWidth',1,'Color','k');


theta = binEdges;

%theta(end) = [];
for ii = 1:nbins

    radius = hist_counts(ii);

    % Calculate the vertices of the current triangle
    thetaEdge1 = theta(ii);
    thetaEdge2 = theta(ii+1);
    x1 = center(1) + radius*cos(thetaEdge1);
    y1 = center(2) + radius*sin(thetaEdge1);
    x2 = center(1) + radius*cos(thetaEdge2);
    y2 = center(2) + radius*sin(thetaEdge2);
    x3 = center(1);
    y3 = center(2);

    wedgeColorIdx = floor((thetaEdge1/(2*pi))*nColors)+1;
    wedgeColor = cmap(wedgeColorIdx,:);
    
    % Plot the current triangle
    patch(ax, [x1,x2,x3], [y1,y2,y3], 'w', 'EdgeColor', 'k', 'FaceColor', wedgeColor, 'FaceAlpha', 0.75);
end

axis square
axis equal

% Set the axis labels and title
xlabel(ax, 'x');
ylabel(ax, 'y');
title(ax, 'Polar Histogram');
end
