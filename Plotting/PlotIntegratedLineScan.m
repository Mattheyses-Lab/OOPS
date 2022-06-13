function LineScanAxes = PlotIntegratedLineScan(LineScanAxes,ScanLinePosition,Img,RealWorldLims)
% ScanLinePosition: 2x2 array, [x1,y1;x2,y2]
%   (same format given by the Position property of a line drawn with DrawLine())

    scanwidth = 9;

    % distance (in lines) on either side of the user-defined line
    nlinesperside = (scanwidth-1)/2;

    x1 = ScanLinePosition(1,1);
    y1 = ScanLinePosition(1,2);
    x2 = ScanLinePosition(2,1);
    y2 = ScanLinePosition(2,2);

    % coordinates of a line at the edge of the scan
    [xend1,xend2,yend1,yend2] = ParallelTranslation(x1,x2,y1,y2,-nlinesperside);

    % the rest of the lines
    ParallelLines = MultiParallelTranslation(xend1,xend2,yend1,yend2,scanwidth);

    umperpixel = RealWorldLims(2)/length(Img);
    pxdist = sqrt((y2-y1)^2+(x2-x1)^2);
    umdist = pxdist*umperpixel;
    N_10nm = round((umdist*100));

    umXData = linspace(0,umdist,N_10nm);

    LineScanYData = cell(scanwidth,1);
    LineScanYData{1} = zeros(1,N_10nm);
    IntegratedLineScan = zeros(1,N_10nm);

    parfor i = 1:scanwidth

        LineScanYData{i} = improfile(Img,ParallelLines{i}(:,1),ParallelLines{i}(:,2),N_10nm,'bilinear')';

        IntegratedLineScan = IntegratedLineScan+LineScanYData{i};

    end

    plot(LineScanAxes,umXData,Scale0To1(IntegratedLineScan),'Color',[0 1 0],'LineWidth',2);

    drawnow nocallbacks

end