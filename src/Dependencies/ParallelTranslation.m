function [x3,x4,y3,y4] = ParallelTranslation(x1,x2,y1,y2,d)
% performs parallel translation of line segment with points (x1,y1),(x2,y2),
%   where d is the orthogonal distance between the input and output segments

    % length of the line segment (distance between points)
    r = sqrt((x2-x1)^2+(y2-y1)^2);
    % determine the value by which to shift x and y coordinates
    deltax = (d/r)*(y1-y2);
    deltay = (d/r)*(x2-x1);
    % get the new coordinates by applying x and y shifts
    x3 = x1+deltax;
    y3 = y1+deltay;
    x4 = x2+deltax;
    y4 = y2+deltay;
end