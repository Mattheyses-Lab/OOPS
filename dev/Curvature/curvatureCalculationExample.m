function curvatureCalculationExample()

    points = [1,1;5.5,5.5;10,3];

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
        slope12*slope23*(point1(1,2)-point3(1,2))
        slope23*(point1(1,1)+point2(1,1))
        % calculate the curvature
        x_center = (slope12*slope23*(point1(1,2)-point3(1,2))+slope23*(point1(1,1)+point2(1,1))...
                   -slope12*(point2(1,1)+point3(1,1)))/(2*(slope23-slope12));
        midpoint12 = (point1+point2)/2
        midpoint13 = (point1+point3)/2

        y_center = (-1/slope12)*(x_center-midpoint12(1,1))+midpoint12(1,2);

        % should this be point2?
        pointsCurvature = 1/sqrt((point1(1,1)-x_center)^2+(point1(1,2)-y_center)^2);


        radius = sqrt((point2(1,1)-x_center)^2+(point2(1,2)-y_center)^2)
        radius2 = sqrt((point1(1,1)-x_center)^2+(point1(1,2)-y_center)^2)


    end

    % plot the three points connected by a line
    plot(points(:,1),points(:,2),'o','LineStyle','-','Color',[0 0 0],'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0]);

    % hold on for more plots
    hold on

    % display the coordinates of the circle center
    disp(['Circle center (x,y): (',num2str(x_center),',', num2str(y_center),')']);

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


end