function [] = AxesCustomToolbar()

    im = zeros(1024,1024);
    
    for i = 1:1024
        im(i,1:1024) = linspace(0,1,1024);
    end

    load('/Users/will/UAB/Mattheyses Lab/Software/PODSv2/Test Data Set/Dsg2-GFP-IA_Go-Treated_20210215_040.mat','-mat','data');
    im = data.I;
    
    % get monitor positions to determine figure size
    MonitorPosition = get(0, 'MonitorPositions');
    % get size of main monitor
    MP1 = MonitorPosition(1,1:4);    


    fH = uifigure('Name','Axes Toolbar Test',...
                 'NumberTitle','off',...
                 'Units','Pixels',...
                 'Position',MP1,...
                 'Visible','On',...
                 'HandleVisibility','On',...
                 'Color','Blue');

    pos = fH.Position;
    
    % width and height of the large plots
    width = round(pos(3)*0.400);
    height = width;
    height_norm = height/pos(4);
    width_norm = width/pos(3);             
               
    Panel1 = uipanel(fH,'Position',[100 100 width height],'BorderType','line','BackGroundColor','Black','tag','Panel1');
    
    width = Panel1.InnerPosition(3);
    height = width;
    
    
    ax = uiaxes('Parent',Panel1,...
                'Units','Pixels',...
                'InnerPosition',[1 1 width height],...
                'XTick',[],...
                'YTick',[],...
                'XLim',[1,1024],...
                'YLim',[1,1024]); 
            
            
    pbarOriginal = ax.PlotBoxAspectRatio;
    tagOriginal = ax.Tag; 

    ImgH = imshow(im,'Parent',ax);
    
    ax = restore_axis_defaults(ax,pbarOriginal,tagOriginal);
    
    tb = axtoolbar(ax,{});
    
    btn = axtoolbarbtn(tb,'state');
    btn.Icon = 'TestIcon.png';
    btn.Tooltip = 'Zoom to Cursor';
    btn.ValueChangedFcn = @TestCallback;
    
    Handles = guihandles;    
    
    Handles.pct = 0.5;
    
    % max box size
    Handles.xrange = diff(ax.XLim);
    Handles.yrange = diff(ax.YLim);
    Handles.zrange = diff(ax.ZLim);
    
    % size of zoom box
    Handles.xdist = Handles.pct*Handles.xrange;
    Handles.ydist = Handles.pct*Handles.yrange;
    Handles.zdist = Handles.pct*Handles.zrange;
    
    % old axis limits
    Handles.oldxlim = ax.XLim;
    Handles.oldylim = ax.YLim;
    Handles.oldzlim = ax.ZLim;
    
    Handles.ax = ax;
    Handles.Image = ImgH;
    Handles.Panel1 = Panel1;
    Handles.tb = tb;
    Handles.fH = fH;
    Handles.Height = height;
    Handles.Width = width;
    Handles.im = im;
    
    guidata(fH,Handles);
end

function [] = TestCallback(source,event)
    Handles = guidata(source);
        
    CurrentAxes = Handles.fH.CurrentAxes;
    fH = Handles.fH;
    
    ax = Handles.ax;
    
    switch event.Value
        case 1
            Handles.RefAxes = uiaxes(Handles.Panel1,...
                'Units','Pixels',...
                'InnerPosition',[1 1 Handles.Width Handles.Height],...
                'XTick',[],...
                'YTick',[],...
                'XLim',[1,1024],...
                'YLim',[1,1024]);
            Handles.RefAxes.Toolbar.Visible = 'Off';
            Handles.Panel1.Children = flip(Handles.Panel1.Children);

            Handles.RefAxes.Visible = 'Off';

            Handles.CursorPositionLabel = uilabel(Handles.Panel1,...
                'Position',[10 10 200 20],...
                'BackgroundColor','Black',...
                'FontColor','Yellow');
            
             
            % get original axis values
            pbarOriginal = Handles.RefAxes.PlotBoxAspectRatio;
            tagOriginal = Handles.RefAxes.Tag; 
            
            ImgH = imshow(zeros(1024,1024),'Parent',Handles.RefAxes);

            Handles.RefAxes = restore_axis_defaults(Handles.RefAxes,pbarOriginal,tagOriginal);

            ImgH.Visible = 'Off';

            axes(Handles.RefAxes);

            fH.WindowButtonMotionFcn = @CursorMoving;
            
        case 0
            fH.WindowButtonMotionFcn = '';
            try
                delete(Handles.CursorPositionLabel)
            end
            try
                delete(Handles.RefAxes)
            end
            ax.XLim = Handles.oldxlim;
            ax.YLim = Handles.oldylim;
            Handles.ax = ax;
            Handles.fH = fH;
            guidata(source,Handles);
    end            
    
    Handles.fH = fH;
    
    guidata(source,Handles);
end


function [] = CursorMoving(source,event)

    Handles = guidata(source);
    
    ax = Handles.fH.CurrentAxes;
    
    posn = ax.CurrentPoint;
    posn = posn(1,:);

    x = posn(1,1);
    y = posn(1,2);
    z = posn(1,3);
    
    % x and y are already in expressed in proper pixel coordinates
    x1 = min(max(1,x-0.5*Handles.xdist),Handles.xrange-Handles.xdist) + 0.5;
    y1 = min(max(1,y-0.5*Handles.ydist),Handles.yrange-Handles.ydist) + 0.5;
    z1 = min(max(1,z-0.5*Handles.zdist),Handles.zrange-Handles.zdist) + 0.5;
    x2 = x1 + Handles.xdist;
    y2 = y1 + Handles.ydist;
    z2 = z1 + Handles.zdist;
    
    if x >= Handles.oldxlim(1) & x <= Handles.oldxlim(2) & ...
            y >= Handles.oldylim(1) & y <= Handles.oldylim(2) & ...
        z >= Handles.oldzlim(1) & z <= Handles.oldzlim(2)

        Handles.CursorPositionLabel.Text = sprintf('x = %3.2f;  y = %3.2f',x,y);
        Handles.ax.XLim = [x1 x2];
        Handles.ax.YLim = [y1 y2];

    else

        Handles.CursorPositionLabel.Text = sprintf('x = %3.0f;  y = %3.0f',0,0);
        Handles.ax.XLim = Handles.oldxlim;
        Handles.ax.YLim = Handles.oldylim;

    end    

    
    guidata(source,Handles);



end

function [axH] = restore_axis_defaults(axH,OriginalPlotBoxAspectRatio,OriginalTag)
        % restore axis defaults that were changed by imshow()
        axH.YDir = 'reverse';
        axH.PlotBoxAspectRatioMode = 'manual';
        %axH.DataAspectRatioMode = 'auto';
        axH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
        axH.XTick = [];
        axH.YTick = [];
        axH.Tag = OriginalTag;

end





