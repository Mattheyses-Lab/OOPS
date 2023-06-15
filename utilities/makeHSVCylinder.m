function makeHSVCylinder(Options)

arguments
    Options.hueRepeats (1,1) double = 1
    Options.missingWedgeSize (1,1) double = 60
    Options.cylinderRes (1,1) double = 360
    Options.colorRes (1,1) double = 100
    Options.cylinderRadius (1,1) double = 10;
    Options.cylinderHeight (1,1) double = 10;
    Options.outlineColor (1,3) double = [1 1 1]
    Options.outlineWidth (1,1) double = 2
end

% number of times the hue is repeated
hueRepeats = Options.hueRepeats;
% size of the missing wedge (in degrees)
missingWedgeSize = Options.missingWedgeSize;
% the number of hue wedges making up the color cylinder (using 72 will plot 5° wedges, 360 for 1° wedges, etc...)
cylinderRes = Options.cylinderRes;
% if uneven, make even
if ~iseven(cylinderRes)
    cylinderRes = cylinderRes+1;
end
% resolution for the colors plotted on each face
% ex: if colorRes = 20, each individual face will consist of 10 different color blocks
colorRes = Options.colorRes;
% radius of the cylinder
cylinderRadius = Options.cylinderRadius;
% height of the cylinder
cylinderHeight = Options.cylinderHeight;
% color of the lines along sharp edges
outlineColor = Options.outlineColor;
%width of the lines along sharp edges
outlineWidth = Options.outlineWidth;

% the angle of each individual hue wedge
wedgeSize = 360./cylinderRes;

%% hue (H) goes from 0 to 1
% hue is repeated n = hueRepeats times

H = repmat([linspace(0,1,(cylinderRes/hueRepeats)+1)],colorRes*3,1);
H = H(:,1:end-1);
H = repmat(H,1,hueRepeats);

%% saturation (S)
% goes from 0 at the center of the top face, to 1 at the edge of the top face, 
% then stays at 1 along the side faces,
% then stays at 1 along the bottom face

S = repmat([linspace(0,1,colorRes) ones(1,colorRes) ones(1,colorRes)].',1,cylinderRes);

%% value (V) 
% all 1s for the top face of the cylinder, 
% then 1 to 0 for the sides,
% then stays at 0 along the bottom face

V = repmat([ones(1,colorRes) linspace(1,0,colorRes) zeros(1,colorRes)].',1,cylinderRes);

%% Create an HSV image from the H, S, and V arrays, then convert to RGB

hsvImage = cat(3,H,S,V);
C = hsv2rgb(hsvImage);

%% generate the cylinder

% get X, Y, and Z coordinates for outside cylinder faces
[X, Y, Z] = cylinder(cylinderRadius,cylinderRes);
% add coordinates for the top and bottom faces
X = [zeros(1, cylinderRes+1); X; zeros(1, cylinderRes+1)];
Y = [zeros(1, cylinderRes+1); Y; zeros(1, cylinderRes+1)];
Z = [cylinderHeight.*Z([2 2 1], :); zeros(1, cylinderRes+1)];


wedgeRatio = missingWedgeSize/360;
cutoutCylinderIdx = round(cylinderRes*(1-wedgeRatio))+1;

% cylinder with cutout wedge
figure;
surf(X(:,1:cutoutCylinderIdx),...
    Y(:,1:cutoutCylinderIdx),...
    Z(:,1:cutoutCylinderIdx),...
    C(:,1:cutoutCylinderIdx-1,:),...
    'FaceColor','texturemap',...
    'EdgeColor', 'none');
axis equal
hold on

if missingWedgeSize > 0
    % (x,y,z) coordinates of plane 1
    x = repmat(linspace(0,X(2,cutoutCylinderIdx),cylinderRadius),cylinderRadius,1);
    y = repmat(linspace(0,Y(2,cutoutCylinderIdx),cylinderRadius),cylinderRadius,1);
    z = repmat(linspace(0,cylinderHeight,cylinderRadius).',1,cylinderRadius);
    % color data
    c = hsv2rgb(cat(3,...
        repmat(H(1,cutoutCylinderIdx-1),colorRes,colorRes),... % H
        repmat(linspace(0,1,colorRes),colorRes,1),... % S
        repmat([linspace(0,1,colorRes)].',1,colorRes)... % V
        ));
    % plot the plane as a surface
    surf(x,y,z,c,'FaceColor', 'texturemap', 'EdgeColor','none');
    % (x,y,z) coordinates of plane 2
    x2 = repmat(linspace(0,cylinderRadius,cylinderRadius),cylinderRadius,1);
    y2 = repmat(zeros(1,cylinderRadius),cylinderRadius,1);   
    z2 = repmat(linspace(0,cylinderHeight,cylinderRadius).',1,cylinderRadius); 
    % color data
    c2 = hsv2rgb(cat(3,...
        zeros(colorRes,colorRes),... % H
        repmat(linspace(0,1,colorRes),colorRes,1),... % S
        repmat([linspace(0,1,colorRes)].',1,colorRes)... % V
        ));
    % plot the plane as a surface
    surf(x2,y2,z2,c2,'FaceColor', 'texturemap', 'EdgeColor','none');
end

%% now plot lines on all the sharp edges

% x and y coordinates for semi-circles (or circles) on the top and bottom faces of the wedge
circleExtent = wedgeSize*(cutoutCylinderIdx-1);
[circleX,circleY] = getCircleCoordinates(0,0,cylinderRadius,circleExtent);

% plot the two semi-circles (or circles)
plot(circleX,circleY,'LineWidth',outlineWidth,'Color',outlineColor);
plot3(circleX,circleY,ones(size(circleX))*cylinderHeight,'LineWidth',outlineWidth,'Color',outlineColor);

if missingWedgeSize > 0
    % x and y coordinates for the outermost edge of plane 1
    linex = X(2,cutoutCylinderIdx);
    liney = Y(2,cutoutCylinderIdx);
    % starting with the center of the bottom face, 
    % trace a square around plane 1, then trace plane 2 and finish on the center of the top face
    XData = [0 linex; linex linex; linex 0; 0 0; 0 cylinderRadius; cylinderRadius cylinderRadius; cylinderRadius 0];
    YData = [0 liney; liney liney; liney 0; 0 0; 0 0; 0 0; 0 0];
    ZData = [0 0; 0 cylinderHeight; cylinderHeight cylinderHeight; cylinderHeight 0; 0 0; 0 cylinderHeight; cylinderHeight cylinderHeight];
    line(XData,YData,ZData,'LineWidth',outlineWidth,'Color',outlineColor);
end

%% change some fig/ax settings

set(gcf,'Color',[0 0 0]);
set(gca,'Visible','Off');


end