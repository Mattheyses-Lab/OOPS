function [] = ZoomToCursor(source,event)
%% ZoomToCursor
%   allows for dynamic zooming/panning in GUI axes
%   all PODSGUI axes using ZoomToCursor will have a custom toolbar state
%   button, clicking will activate ZoomToCursor behavior
%           clicking button again will deactivate
%           clicking within axes will increase zoom through a set number of
%           zoom levels until max zoom is reached
%           double-click will return to default zoom value
%           shift-click will decrease zoom
%-------------------------------------------------------------------------%
% Author: Will Dean
% Organization: University of Alabama at Birmingham
% Group: Mattheyses Lab
% Date: 20210701
%
%
%
% This function uses the same general strategy of zoom2cursor
% (Written by Brett Shoelson, Ph.D. (shoelson@helix.nih.gov,
% shoelson@hotmail.com))

    PODSData = guidata(source);
    Handles = PODSData.Handles;
    Zoom = PODSData.Settings.Zoom;

    % try and delete previous CursorPositionLabel, this is necessary in
    % case the user activates the Toolbar state button (ZoomToCursor) in an
    % axes without first deactivating the button in another axes
    try
        delete(Zoom.DynamicAxes.CursorPositionLabel)
    catch
        % no cursor position label exists for these axes
    end

    % Axes where limits will be changing = Axes that called the callback
    Zoom.DynamicAxes = event.Axes;
    % Get the parent container to place static reference Axes
    Zoom.DynamicAxesParent = Zoom.DynamicAxes.Parent;
    
    switch event.Value
        case 1
            
            pos = Zoom.DynamicAxes.InnerPosition;

            Zoom.StaticAxes = uiaxes(Zoom.DynamicAxesParent,...
                'Units','Pixels',...
                'InnerPosition',pos,...
                'XTick',[],...
                'YTick',[],...
                'XLim',Zoom.DynamicAxes.XLim,...
                'YLim',Zoom.DynamicAxes.YLim,...
                'Tag','StaticReferenceAxes');
            Zoom.StaticAxes.Toolbar.Visible = 'Off';
            %Zoom.DynamicAxesParent.Children = flip(Zoom.DynamicAxesParent.Children);
            
            Zoom.StaticAxes.Visible = 'Off';

            try
                Zoom.DynamicAxes.addprop('CursorPositionLabel');
            catch
                % Property already exists
            end
            % label to display cursor position
            Zoom.DynamicAxes.CursorPositionLabel = uilabel(Zoom.DynamicAxesParent,...
                'Position',[1 1 pos(3) 20],...
                'BackgroundColor','Black',...
                'FontColor','Yellow',...
                'Text','');
            
             
            % get original axes values
            pbarOriginal = Zoom.StaticAxes.PlotBoxAspectRatio;
            tagOriginal = Zoom.StaticAxes.Tag;
            
            
            Zoom.DynamicImage = findobj(Zoom.DynamicAxes,'Type','image');
            % placeholder image in the reference (static) axes
            Zoom.StaticImage = imshow(Zoom.DynamicImage.CData,'Parent',Zoom.StaticAxes);

            % restore axis defaults for consistent display
            Zoom.StaticAxes = restore_axis_defaults(Zoom.StaticAxes,pbarOriginal,tagOriginal);

            Zoom.StaticImage.Visible = 'Off';

            axes(Zoom.StaticAxes);
            
            Zoom.XRange = diff(Zoom.DynamicAxes.XLim);
            Zoom.YRange = diff(Zoom.DynamicAxes.YLim);
            Zoom.ZRange = diff(Zoom.DynamicAxes.ZLim);
            Zoom.XDist = 0.5*Zoom.XRange;
            Zoom.YDist = 0.5*Zoom.YRange;
            Zoom.ZDist = 0.5*Zoom.ZRange;
            Zoom.OldXLim = Zoom.DynamicAxes.XLim;
            Zoom.OldYLim = Zoom.DynamicAxes.YLim;
            Zoom.OldZLim = Zoom.DynamicAxes.ZLim;

            Handles.fH.Pointer = 'crosshair';
            Handles.fH.WindowButtonMotionFcn = @CursorMoving;
            Zoom.DynamicImage.ButtonDownFcn = @ChangeZoomLevel;
            %Zoom.StaticAxes.ButtonDownFcn = @ChangeZoomLevel;
            %Zoom.DynamicAxes.Hittest = 'Off';
            %Zoom.StaticAxes.Hittest = 'Off';
            
        case 0
            Handles.fH.WindowButtonMotionFcn = '';
            
            try
                delete(Zoom.DynamicAxes.CursorPositionLabel)
            end
            try
                delete(Zoom.StaticAxes)
            end
            try
                delete(Zoom.StaticImage)
            end            

            Zoom.DynamicAxes.XLim = Zoom.OldXLim;
            Zoom.DynamicAxes.YLim = Zoom.OldYLim;

             Zoom.XDist = 0.5*Zoom.XRange;
             Zoom.YDist = 0.5*Zoom.YRange;
             Zoom.ZDist = 0.5*Zoom.ZRange;
             Zoom.ZoomLevelIdx = 4;
             Zoom.pct = 0.5;            
            

    end  
    
    PODSData.Settings.Zoom = Zoom;
    PODSData.Handles = Handles;
    
    guidata(source,PODSData);    


end

function [] = CursorMoving(source,event)

    PODSData = guidata(source);
    fH = PODSData.Handles.fH;

    Zoom = PODSData.Settings.Zoom;
    DynamicAxes = PODSData.Settings.Zoom.DynamicAxes;
    
    posn = Zoom.StaticAxes.CurrentPoint(1,:);

    x = posn(1,1);
    y = posn(1,2);
    z = posn(1,3);
    
    % x and y are already in expressed in proper pixel coordinates
    x1 = min(max(1,x-0.5*Zoom.XDist),Zoom.XRange-Zoom.XDist) + 0.5;
    y1 = min(max(1,y-0.5*Zoom.YDist),Zoom.YRange-Zoom.YDist) + 0.5;
    z1 = min(max(1,z-0.5*Zoom.ZDist),Zoom.ZRange-Zoom.ZDist) + 0.5;
    x2 = x1 + Zoom.XDist;
    y2 = y1 + Zoom.YDist;
    z2 = z1 + Zoom.ZDist;
    
    % if cursor is still within axes limits
    if x >= Zoom.OldXLim(1) & x <= Zoom.OldXLim(2) & ...
            y >= Zoom.OldYLim(1) & y <= Zoom.OldYLim(2) & ...
        z >= Zoom.OldZLim(1) & z <= Zoom.OldZLim(2)

        ZoomPct = round((Zoom.XRange/Zoom.XDist)*100);
        posn2 = Zoom.DynamicAxes.CurrentPoint(1,:);
        realx = posn2(1,1);
        realy = posn2(1,2);

        DynamicAxes.CursorPositionLabel.Text = [' (X,Y) = (',num2str(round(realx)),...
                                                ',',num2str(round(realy)),') | Zoom: ',...
                                                num2str(ZoomPct),'%',...
                                                ' | Value: ',num2str(Zoom.StaticImage.CData(round(realy),round(realx)))];
        DynamicAxes.XLim = [x1 x2];
        DynamicAxes.YLim = [y1 y2];
        
        PODSData.Handles.fH.Pointer = 'crosshair';

    else

        DynamicAxes.CursorPositionLabel.Text = sprintf('x = %3.0f;  y = %3.0f',0,0);
        DynamicAxes.XLim = Zoom.OldXLim;
        DynamicAxes.YLim = Zoom.OldYLim;
        
        PODSData.Handles.fH.Pointer = 'arrow';

    end    
    Zoom.DynamicAxes = DynamicAxes;
    PODSData.Settings.Zoom = Zoom;
    
    guidata(fH,PODSData);
end

function [] = ChangeZoomLevel(source,event)
    PODSData = guidata(source);
    
    Zoom = PODSData.Settings.Zoom;
    %DynamicAxes = PODSData.Settings.Zoom.DynamicAxes;

    switch PODSData.Handles.fH.SelectionType
        case 'normal'
            if Zoom.ZoomLevelIdx == 1
                Zoom.ZoomLevelIdx = 7;
            else
                Zoom.ZoomLevelIdx = Zoom.ZoomLevelIdx - 1;
            end

            Zoom.pct = Zoom.ZoomLevels(Zoom.ZoomLevelIdx);
            
        case 'alt'

            if Zoom.ZoomLevelIdx == 7
                Zoom.ZoomLevelIdx = 1;
            else
                Zoom.ZoomLevelIdx = Zoom.ZoomLevelIdx + 1;
            end

            Zoom.pct = Zoom.ZoomLevels(Zoom.ZoomLevelIdx);

        case 'extend'
            Zoom.DynamicAxes.XLim = Zoom.OldXLim;
            Zoom.DynamicAxes.YLim = Zoom.OldXLim;
            Zoom.DynamicAxes.ZLim = Zoom.OldZLim;
        case 'open'
            Zoom.pct = 1;
    end
    
    Zoom.XDist = Zoom.pct*Zoom.XRange;
    Zoom.YDist = Zoom.pct*Zoom.YRange;
    Zoom.ZDist = Zoom.pct*Zoom.ZRange;

    PODSData.Settings.Zoom = Zoom;
    guidata(source,PODSData);    
    
     if ~strcmp(PODSData.Handles.fH.SelectionType,'extend')
         CursorMoving(source,event);
     end
end

function [axH] = restore_axis_defaults(axH,OriginalPlotBoxAspectRatio,OriginalTag)
        % restore axis defaults that were changed by imshow()
        axH.YDir = 'Reverse';
        axH.PlotBoxAspectRatioMode = 'manual';
        %axH.DataAspectRatioMode = 'auto';
        axH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
        axH.XTick = [];
        axH.YTick = [];
        axH.Tag = OriginalTag;

end