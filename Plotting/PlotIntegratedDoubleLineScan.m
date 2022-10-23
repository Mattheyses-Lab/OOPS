function LineScanAxes = PlotIntegratedDoubleLineScan(LineScanAxes,ScanLinePosition,Img1,Img2,RealWorldLims)
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
    ParallelLines = [ParallelLines;ParallelLines];

    umperpixel = RealWorldLims(2)/length(Img1);
    pxdist = sqrt((y2-y1)^2+(x2-x1)^2);
    umdist = pxdist*umperpixel;
    N_10nm = round((umdist*100));

    umXData = linspace(0,umdist,N_10nm);

    LineScanYData = cell(scanwidth*2,1);
    LineScanYData{1} = zeros(1,N_10nm);

    parfor i = 1:scanwidth*2

        if i <= scanwidth
            LineScanYData{i} = improfile(Img1,ParallelLines{i}(:,1),ParallelLines{i}(:,2),N_10nm,'bicubic')';
        else
            LineScanYData{i} = improfile(Img2,ParallelLines{i}(:,1),ParallelLines{i}(:,2),N_10nm,'bicubic')';
        end

    end

    IntegratedLineScan1 = sum(cell2mat(LineScanYData(1:scanwidth)),1);
    IntegratedLineScan2 = sum(cell2mat(LineScanYData(scanwidth+1:end)),1);

    set(0,'CurrentFigure',LineScanAxes.Parent);
    set(gcf,'CurrentAxes',LineScanAxes);
    plot(umXData,Scale0To1(IntegratedLineScan1),'Color','Green','LineWidth',2);
    hold on
    plot(umXData,Scale0To1(IntegratedLineScan2),'Color','Magenta','LineWidth',2);
    hold off    

    drawnow nocallbacks

end