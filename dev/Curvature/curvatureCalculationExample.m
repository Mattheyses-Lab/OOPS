function curvatureCalculationExample()
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    points = [1,5;5,10;10,5];

    point1 = points(1,:);
    point2 = points(2,:);
    point3 = points(3,:);    

    slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
    slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));

    if slope12==Inf || slope12==-Inf || slope12 == 0
        point0 = point2; point2 = point3; point3 = point0;
        slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
        slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));    
    end

    if slope23==Inf || slope23==-Inf
        point0 = point1; point1 = point2; point2 = point0;
        slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
        slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));    
    end

    % if the boundary is flat
    if slope12==slope23  
        pointsCurvature = 0;

    % if the boundary is curved
    else
        % calculate the curvature

        % find x-coordinate by expressing it in terms of the linear equations for the two perpendicular bisectors
        x_center = (slope12*slope23*(point1(1,2)-point3(1,2))+slope23*(point1(1,1)+point2(1,1))...
                   -slope12*(point2(1,1)+point3(1,1)))/(2*(slope23-slope12));
        % find the two midpoints of the chords between points 1 and 2 and points 2 and 3
        midpoint12 = (point1+point2)/2;
        midpoint13 = (point1+point3)/2;

        % find y-coordinate by expressing it in terms of the linear equation of the perpendicular bisector of chord 1-2
        y_center = (-1/slope12)*(x_center-midpoint12(1,1))+midpoint12(1,2);

        % plug in one of the points (point1 here) to find the radius
        radius = sqrt((point1(1,1)-x_center)^2+(point1(1,2)-y_center)^2);

        pointsCurvature = 1/radius;


    end

    % plot the three points connected by a line
    plot(points(:,1),points(:,2),'o','LineStyle','-','Color',[0 0 0],'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0]);

    % hold on for more plots
    hold on

    % plot the center of the circle
    plot(x_center,y_center,'+')

    % plot midpoint between points 1 and 2
    plot(midpoint12(:,1),midpoint12(:,2),'*')

    % plot midpoint between points 1 and 3
    plot(midpoint13(:,1),midpoint13(:,2),'^')

    % plot the circle
    circlePlot = viscircles([x_center,y_center],radius);
    text(x_center,y_center,['(',num2str(x_center),',',num2str(y_center),')'],'Units','Data','VerticalAlignment','top')

    axis square
    axis equal

    % display the coordinates of the circle center
    disp(['Circle center (x,y): (',num2str(x_center),',', num2str(y_center),')']);

    % slopes
    disp(['Slope 1—2: ',num2str(slope12)]);
    disp(['Slope 2—3: ',num2str(slope23)]);

    % radius
    disp(['Radius: ',num2str(radius)]);

    % curvature
    disp(['Curvature: ',num2str(pointsCurvature)]);

end