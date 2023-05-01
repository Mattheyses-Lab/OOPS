function [shape_details,Icurv,IT,IC] = GetObjectMidlineCurvature(I)
% Author: Will Dean 
% This function uses curvature2.m, a modified version of curvature.m (originally written by Dr. Meghan Driscoll)
% From curvature.m:
% Usage of curvature.m: [shape, Icurv] = curvature(image, boundaryPoint, curvatureThresh, ...
%                                     bp_tangent, interp_resolution, loopclose)

[shape_details,Icurv] = midlineCurvature(I,10,1,1,.25,false);

Midline = shape_details.XY;

% size of the input image
Isz = size(I);

% tangent image
IT = zeros(Isz);
% curvature image
IC = zeros(Isz);

% for each pixel
for Idx = 1:numel(I)
    % if the pixel is in the object
    if I(Idx)
        % get y and x coordinates from the linear idx
        [y,x] = ind2sub(Isz,Idx);
        % get Euclidean distances between this pixel and all midline points
        dist = sqrt((x-Midline(:,1)).^2+(y-Midline(:,2)).^2);
        % find the shortest distance, that will be the point we need
        [minDist,minIdx] = min(dist);
        IT(Idx) = shape_details.tangentAngleDegrees(minIdx);
        IC(Idx) = shape_details.curvature(minIdx);
    end
end

%% Show the image with overlaid curvature boundary line

%% The code below was originally part of demo.m 
% (written by Dr. Meghan Driscoll and included with curvature.m on the MathWorks File Exchange)

%figure();imshow(Icurv)
imshow2(Icurv)
hold on
X = shape_details.XY(:,1);
Y = shape_details.XY(:,2);
Z = zeros(size(X));
C = shape_details.curvature'*1;
cmap = jet;
colormap(cmap);
cb = colorbar;  % Add a colorbar
cb.Label.String = 'Curvature';
surf([X(:) X(:)], [Y(:) Y(:)], [Z(:) Z(:)], [C C], ...  % Reshape and replicate data
            'FaceColor', 'none', ...    % Don't bother filling faces with color
            'EdgeColor', 'interp', ...  % Use interpolated color for edges
            'LineWidth', 10);
% end of code originally found in demo.m

boundary_plot = plot(shape_details.XY(:,1),shape_details.XY(:,2),'Marker','o','MarkerFaceColor',[0 0 1],'LineStyle','none','MarkerSize',3);

set(gca,'Units','Normalized');
set(gca,'OuterPosition',[0 0 1 1]);

hold off

pause(0.5)

% using the same strategy above, lets also visualize the tangents
%figure();imshow(Icurv)
imshow2(Icurv)
hold on
X = shape_details.XY(:,1);
Y = shape_details.XY(:,2);
Z = zeros(size(X));
C = shape_details.tangentAngleDegrees';
surf([X(:) X(:)], [Y(:) Y(:)], [Z(:) Z(:)], [C C], ...  % Reshape and replicate data
'FaceColor', 'none', ...    % Don't bother filling faces with color
'EdgeColor', 'interp', ...  % Use interpolated color for edges
'LineWidth', 10);
cmap = hsv;
colormap(cmap);
cb2 = colorbar;  % Add a colorbar
cb2.Label.String = 'Tangent Angle (°)';

boundary_plot2 = plot(shape_details.XY(:,1),shape_details.XY(:,2),'Marker','o','MarkerFaceColor',[0 0 0],'LineStyle','none','MarkerSize',3);

set(gca,'Units','Normalized');
set(gca,'OuterPosition',[0 0 1 1]);
set(gca,'CLim',[0 180]);

hold off

pause(0.5)


X = shape_details.XY(:,1);
Y = shape_details.XY(:,2);

[U,V] = pol2cart(deg2rad(shape_details.tangentAngleDegrees),0.5);

% invert direction of V to account for the fact that matlab displays images "upside down"
V = V*-1;

X = X';
Y = Y';

%figure();imshow(Icurv)
imshow2(Icurv)
hold on

quiver(X,Y,U,V,'LineWidth',2,'ShowArrowHead','off','Alignment','center','AutoScale','off');

set(gca,'Units','Normalized');
set(gca,'OuterPosition',[0 0 1 1]);

hold off


end