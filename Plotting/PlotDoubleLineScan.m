function LineScanAxes = PlotDoubleLineScan(LineScanAxes,ScanLinePosition,Img1,Img2,RealWorldLims)
% ScanLinePosition: 2x2 array, [x1,y1;x2,y2]
%   (same format given by the Position property of a line drawn with DrawLine())

    umperpixel = RealWorldLims(2)/length(Img1);

    x1 = ScanLinePosition(1,1);
    y1 = ScanLinePosition(1,2);
    x2 = ScanLinePosition(2,1);
    y2 = ScanLinePosition(2,2);

    pxdist = sqrt((y2-y1)^2+(x2-x1)^2);
    
    umdist = pxdist*umperpixel;
    
    N_10nm = round((umdist*100));

    umXData = linspace(0,umdist,N_10nm);
    
    LineScanYData1 = improfile(Img1,[x1 x2],[y1 y2],N_10nm,'bicubic');
    LineScanYData2 = improfile(Img2,[x1 x2],[y1 y2],N_10nm,'bicubic');
    plot(LineScanAxes,umXData,LineScanYData1);
    LineScanAxes.NextPlot = 'Add';
    plot(LineScanAxes,umXData,LineScanYData2);
    LineScanAxes.NextPlot = 'Replace';

end