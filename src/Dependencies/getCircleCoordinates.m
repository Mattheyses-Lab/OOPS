function [x,y] = getCircleCoordinates(centerx,centery,r,extent)
% returns x and y coordinates to a circle or semi-circle with radius r centered at (centerx,centery)
% (extent is the angle in degrees traversed by the radius line around the semi-circle edge)

thetaResolution = 1;

if isempty(extent)
    extent = 360;
end

th = 0:thetaResolution:extent;
x = r * cosd(th) + centerx;
y = r * sind(th) + centery;

end