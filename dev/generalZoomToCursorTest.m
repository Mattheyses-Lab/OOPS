function generalZoomToCursorTest()

    I = im2double(imread("rice.png"));

    Isz = size(I);

    zoomFigH = uifigure("WindowStyle","alwaysontop",...
        "Units","pixels",...
        "Position",[0 0 500 500],...
        "Visible","off",...
        "HandleVisibility","on",...
        "Name","Zoom test");

    panelGrid = uigridlayout(zoomFigH,...
        [1,1],...
        "Padding",[0 0 0 0]);

    panelH = uipanel(panelGrid);

    zoomAxH = uiaxes(panelH,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','zoomAxH',...
        'XTick',[],...
        'YTick',[],...
        'Color','Black');

    % save original values to be restored after calling imshow()
    OriginalPlotBoxAspectRatio = zoomAxH.PlotBoxAspectRatio;
    OriginalTag = zoomAxH.Tag;
    % place placeholder image on axis
    zoomImgH = imshow(I,'Parent',zoomAxH);

    % restore axis defaults that were changed by imshow()
    zoomAxH.YDir = 'reverse';
    zoomAxH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
    zoomAxH.XTick = [];
    zoomAxH.YTick = [];
    zoomAxH.Tag = OriginalTag;
    % create a custom toolbar for the axes
    tb = axtoolbar(zoomAxH,{});
    % clear all of the default interactions
    zoomAxH.Interactions = [];

    % add the toolbar button
    btn = axtoolbarbtn(tb,'state');
    btn.Icon = 'MagnifyingGlassBlackAndYellow.png';
    btn.ValueChangedFcn = @generalZoomToCursor;
    btn.Tag = ['ZoomToCursor',zoomAxH.Tag];
    btn.Tooltip = 'Zoom to cursor';

    % disable default interactivity
    disableDefaultInteractivity(zoomAxH);

    % disable clicks on image
    zoomImgH.HitTest = 'Off';

    % set axes limits based on image size
    set(gca,'XLim',[0.5 Isz(2)+0.5],'YLim',[0.5 Isz(1)+0.5]);

    % center and show the figure
    movegui(zoomFigH,'center')
    zoomFigH.Visible = 'on';

    zoomAxH.Visible = 'on';
    
end