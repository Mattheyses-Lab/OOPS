function [x,y] = getCircleCoordinates(centerx,centery,r,extent)
% returns x and y coordinates to a circle or semi-circle with radius r centered at (centerx,centery)
% (extent is the angle in degrees traversed by the radius line around the semi-circle edge)

% hold on
% th = 0:pi/50:2*pi;
% xunit = r * cos(th) + x;
% yunit = r * sin(th) + y;
% h = plot(xunit, yunit);
% hold off

if isempty(extent)
    extent = 2*pi;
end

th = 0:1:extent;
x = r * cosd(th) + centerx;
y = r * sind(th) + centery;

end