function makeHSVCylinder()

% the number of wedges making up the color cylinder (number of unique hues) 
% (using 72 will plot 5° wedges, 360 for 1° wedges, etc...)
cylinderRes = 360;

% if uneven, make even
if ~iseven(cylinderRes)
    cylinderRes = cylinderRes+1;
end

% resolution for the colors plotted on each face
% if colorRes = 20, each individual face will consist of 10 different color blocks
colorRes = 200;


% testing below, return to above if issue
cylinderRadius = 10;
cylinderHeight = 10;

% size of the missing wedge of the cylinder (in degrees)
missingWedgeSize = 60;


%% hue (H) goes from 0 to 1

% for a true hsv color cylinder without repeating the hue:
% size of hue image = [colorRes,cylinderRes]
% first make a matrix with one extra column, then remove it so we don't repeat any hues
% H = repmat([linspace(0,1,cylinderRes+1)],colorRes,1);
% H = H(:,1:end-1);

% for a color cylinder where each hue is repeated twice (for biaxial data)
H = repmat([linspace(0,1,(cylinderRes/2)+1)],colorRes,1);
H = H(:,1:end-1);
H = repmat(H,1,2);


%% saturation (S)
% goes from 0 at the center of the top face, to one at the edge of the top face, then stays at one along the side faces

S = repmat([linspace(0,1,colorRes/2) ones(1,colorRes/2)].',1,cylinderRes);


%% value (V) 
% all ones for the top face of the cylinder, then 1 to 0 for the sides

V = repmat([ones(1,colorRes/2) linspace(1,0,colorRes/2)].',1,cylinderRes);

%% Create an HSV image

hsvImage = cat(3,H,S,V);
% Convert it to an RGB image
C = hsv2rgb(hsvImage);

% uncomment to show the color image projected onto the cylinder
%imshow2(C)

% Generate X, Y, and Z coordinates for outside cylinder faces
[X, Y, Z] = cylinder(cylinderRadius,cylinderRes);
% add coordinates for the top face
X = [zeros(1, cylinderRes+1); X];
Y = [zeros(1, cylinderRes+1); Y];
Z = cylinderHeight.*Z([2 2 1], :);



% % uncomment to show the full cylinder
% figure;
% surf(X, Y, Z, C, 'FaceColor', 'texturemap', 'EdgeColor', 'none');
% axis equal
% xlabel('x')
% ylabel('y')


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

% (plane 1) plot one plane to fill in half of the missing wedge
% x coordinates
x = linspace(0,X(2,cutoutCylinderIdx),cylinderRadius);
x = repmat(x,cylinderRadius,1);
% y coordinates
y = linspace(0,Y(2,cutoutCylinderIdx),cylinderRadius);
y = repmat(y,cylinderRadius,1);
% z coordinates
z = linspace(0,cylinderHeight,cylinderRadius);
z = z';
z = repmat(z,1,cylinderRadius);
% color data
h = repmat(H(1,cutoutCylinderIdx-1),colorRes/2,colorRes/2);
s = repmat(linspace(0,1,colorRes/2),colorRes/2,1);
v = repmat([linspace(0,1,colorRes/2)].',1,colorRes/2);
c = hsv2rgb(cat(3,h,s,v));
% plot the plane as a surface
surf(x,y,z,c,'FaceColor', 'texturemap', 'EdgeColor','none');


% (plane 2) and now the other plane to finish closing the missing wedge
% x coordinates
x2 = linspace(0,cylinderRadius,cylinderRadius);
x2 = repmat(x2,cylinderRadius,1);
% y coordinates
y2 = zeros(1,cylinderRadius);
y2 = repmat(y2,cylinderRadius,1);
% z coordinates
z2 = linspace(0,cylinderHeight,cylinderRadius);
z2 = z2';
z2 = repmat(z2,1,cylinderRadius);
% color data
h2 = zeros(colorRes/2,colorRes/2);
s2 = repmat(linspace(0,1,colorRes/2),colorRes/2,1);
v2 = repmat([linspace(0,1,colorRes/2)].',1,colorRes/2);
c2 = hsv2rgb(cat(3,h2,s2,v2));
% plot the plane as a surface
surf(x2,y2,z2,c2,'FaceColor', 'texturemap', 'EdgeColor','none');


%% now plot lines on all the sharp edges

outlineColor = [1 1 1];
outlineWidth = 2;

% x and y coordinates for semi-circles on the top and bottom faces of the wedge
[circleX,circleY] = getCircleCoordinates(0,0,cylinderRadius,360-missingWedgeSize);

% plot the two semi-circles
plot(circleX,circleY,'LineWidth',outlineWidth,'Color',outlineColor);
plot3(circleX,circleY,ones(size(circleX))*cylinderHeight,'LineWidth',outlineWidth,'Color',outlineColor);

% plot a vertical line at the inside angle of the wedge
plot3([0,0],[0,0],[0,cylinderHeight],'LineWidth',outlineWidth,'Color',outlineColor);

% plane 1 edges
linex = X(2,cutoutCylinderIdx);
liney = Y(2,cutoutCylinderIdx);
% outer vertical edge
plot3([linex linex],[liney liney],[0 cylinderHeight],'LineWidth',outlineWidth,'Color',outlineColor);
% lower and upper horizontal edges
plot3([0 linex],[0 liney],[0 0],'LineWidth',outlineWidth,'Color',outlineColor);
plot3([0 linex],[0 liney],[cylinderHeight cylinderHeight],'LineWidth',outlineWidth,'Color',outlineColor);

% plane 2 edges
linex = cylinderRadius;
liney = 0;
% outer vertical edge
plot3([linex linex],[liney liney],[0 cylinderHeight],'LineWidth',outlineWidth,'Color',outlineColor);
% lower and upper horizontal edges
plot3([0 linex],[0 liney],[0 0],'LineWidth',outlineWidth,'Color',outlineColor);
plot3([0 linex],[0 liney],[cylinderHeight cylinderHeight],'LineWidth',outlineWidth,'Color',outlineColor);

%% change some fig/ax settings

set(gcf,'Color',[0 0 0]);
set(gca,'Visible','Off');


end