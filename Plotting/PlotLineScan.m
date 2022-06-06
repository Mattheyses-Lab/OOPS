function LineScanAxes = PlotLineScan(LineScanAxes,ScanLinePosition,Img,RealWorldLims)
% ScanLinePosition: 2x2 array, [x1,y1;x2,y2]
%   (same format given by the Position property of a line drawn with DrawLine())

    umperpixel = RealWorldLims(2)/length(Img);

    x1 = ScanLinePosition(1,1);
    y1 = ScanLinePosition(1,2);
    x2 = ScanLinePosition(2,1);
    y2 = ScanLinePosition(2,2);
    
%     [r, c] = size(Img);
%     
%     % make coords that represent the "left" or "top" edge of each pixel
%     row_coords = linspace(RealWorldLims(1), RealWorldLims(2), r+1);
%     row_coords(end) = [];
%     col_coords = linspace(RealWorldLims(1), RealWorldLims(2), c+1);
%     col_coords(end) = [];
%     
%     xidx =[round(x1) round(x2)];    %in terms of indices
%     yidx =[round(y1) round(y2)];     %in terms of indices
    
    % get real world coords of selected line (x1,y1 to x2,y2)
%     x = col_coords(xidx);
%     y = row_coords(yidx);

    % number of sample points
%    N = 1 + max( max(xidx) - min(xidx), max(yidx) - min(yidx) );
    
    % set new N so that each sample point is spaced by 10 nm
%    N_10nm = round((umperpixel*100)*N)
    
    % split x and y range into N points
    % these are the coordinates of each sample point from (x(1),y(1)) to (x(2),y(2))
%     x_to_interp = linspace(x(1), x(2), N_10nm);
%     y_to_interp = linspace(y(1), y(2), N_10nm);
%         
%     [X, Y] = meshgrid(col_coords, row_coords);
%     profile = interp2(X, Y, Img, x_to_interp, y_to_interp, 'cubic');

    pxdist = sqrt((y2-y1)^2+(x2-x1)^2);
    
    umdist = pxdist*umperpixel;
    
    N_10nm = round((umdist*100));

    umXData = linspace(0,umdist,N_10nm);
    
    LineScanYData = improfile(Img,[x1 x2],[y1 y2],N_10nm,'bicubic');
    
    plot(LineScanAxes,umXData,LineScanYData);
    
    %plot(LineScanAxes,x_to_interp-min(x_to_interp), profile)

end