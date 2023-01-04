function [] = ZoomToCursor(source,~)
%% ZoomToCursor
%   allows for dynamic zooming/panning in GUI axes
%   all PODSGUI axes using ZoomToCursor will have a custom toolbar state
%   button, clicking will activate ZoomToCursor behavior
%           clicking button again will deactivate
%           clicking within axes will increase zoom through a set number of
%           zoom levels until max zoom is reached
%           double-click will return to default zoom value
%           shift-click will freeze axis limits at current zoom
%-------------------------------------------------------------------------%
% Author: Will Dean
% Organization: University of Alabama at Birmingham
% Group: Mattheyses Lab
% Date: 20210701
%
%
%
% This function is a modified version of zoom2cursor
% (Written by Brett Shoelson, Ph.D. (shoelson@helix.nih.gov,
% shoelson@hotmail.com))

    PODSData = guidata(source);
    
    Handles = PODSData.Handles;
    
    Zoom = PODSData.Settings.Zoom;

    % If ZoomToCursor is already active, check that the axes that called the callback
    %   is the current zoom axes. If so, continue as normal. If not, disable 
    %   zoom on current axes before continuing
    if Zoom.Active
        % get the tag to axes where ZoomToCursor is currently enabled
        CurrentButtonTag = Zoom.CurrentButton.Tag;
        % get the tag of the button that called the callback
        CallingButtonTag = source.Tag;
        % the tag of the ZoomToCursor axes toolbar button is formatted like:
        %   ['ZoomToCursor',ax.Tag]
        %   where ax is the axes containing the button

        % If the axes calling the callback is not the current zoom axes
        if ~strcmp(CurrentButtonTag,CallingButtonTag)
            % then disable zoom before continuing
            % use tag to index the Handles structure and change state of button
            Handles.(CurrentButtonTag).Value = 0;
            % call ZoomToCursor with current button to deactivate the zoom
            ZoomToCursor(Handles.(CurrentButtonTag));
        end
        
    end

    Zoom.Freeze = false;

    % try and delete previous CursorPositionLabel, this is necessary in
    % case the user activates the Toolbar state button (ZoomToCursor) in an
    % axes without first deactivating the button in another axes

    try
        delete(Zoom.DynamicAxes.CursorPositionLabel)
    catch
        % no cursor position label exists for these axes
    end
    
    % check if ZoomToCursor button was pressed on or off
    switch source.Value
        case 1 % on
            % set status as active
            Zoom.Active = true;
            % set current zoom button, obj that called the callback
            Zoom.CurrentButton = source;
            % Get axes where limits will be changing, ancestor axes of button
            Zoom.DynamicAxes = ancestor(source,'Axes');
            % Get the parent container to place static reference Axes
            Zoom.DynamicAxesParent = Zoom.DynamicAxes.Parent;
            % Determine the positioning of the axes that called the callback
            pos = Zoom.DynamicAxes.InnerPosition;
            % Build new axes with same position and limits
            Zoom.StaticAxes = uiaxes(Zoom.DynamicAxesParent,...
                'Units','Normalized',...
                'InnerPosition',pos,...
                'XTick',[],...
                'YTick',[],...
                'XLim',Zoom.DynamicAxes.XLim,...
                'YLim',Zoom.DynamicAxes.YLim,...
                'Tag','StaticReferenceAxes');
            Zoom.StaticAxes.Toolbar.Visible = 'Off';
            % Hide the static axes
            Zoom.StaticAxes.Visible = 'Off';

            try
                Zoom.DynamicAxes.addprop('CursorPositionLabel');
            catch
                % property already exists
            end
            % label to display cursor position
            Zoom.DynamicAxes.CursorPositionLabel = uilabel(Zoom.DynamicAxesParent,...
                'Position',[1 1 Zoom.DynamicAxesParent.Position(3) 20],...
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
%             Zoom.XDist = 0.5*Zoom.XRange;
%             Zoom.YDist = 0.5*Zoom.YRange;
%             Zoom.ZDist = 0.5*Zoom.ZRange;
            Zoom.XDist = Zoom.pct*Zoom.XRange;
            Zoom.YDist = Zoom.pct*Zoom.YRange;
            Zoom.ZDist = Zoom.pct*Zoom.ZRange;


            Zoom.OldXLim = Zoom.DynamicAxes.XLim;
            Zoom.OldYLim = Zoom.DynamicAxes.YLim;
            Zoom.OldZLim = Zoom.DynamicAxes.ZLim;

            Zoom.OldWindowButtonMotionFcn = Handles.fH.WindowButtonMotionFcn;
            Zoom.OldImageButtonDownFcn = Zoom.DynamicImage.ButtonDownFcn;

            Handles.fH.Pointer = 'crosshair';
            Handles.fH.WindowButtonMotionFcn = @(o,e) CursorMoving(o,PODSData);
            Zoom.DynamicImage.ButtonDownFcn = @(o,e) ChangeZoomLevel(o,PODSData);
            Zoom.DynamicImage.HitTest = 'On';
            
        case 0 % off
            Zoom.Active = false;
            Handles.fH.WindowButtonMotionFcn = Zoom.OldWindowButtonMotionFcn;
            Zoom.DynamicImage.ButtonDownFcn = Zoom.OldImageButtonDownFcn;
            Handles.fH.Pointer = 'arrow';
            
            Zoom.DynamicImage.HitTest = 'Off';
            
            try
                delete(Zoom.DynamicAxes.CursorPositionLabel)
            catch
                error('Failed to delete cursor label');
            end
            try
                delete(Zoom.StaticAxes)
            catch
                error('Failed to delete static axes');
            end
            try
                delete(Zoom.StaticImage)
            catch
                error('Failed to delete static image');
            end            

            % reset original axes limits
            Zoom.DynamicAxes.XLim = Zoom.OldXLim;
            Zoom.DynamicAxes.YLim = Zoom.OldYLim;

%             %% TESTING BELOW - RESET ALPHA DATA
%             Zoom.DynamicImage.AlphaData = 1;
%             %% END TEST

            % reset original zoom levels
            Zoom.XDist = 0.5*Zoom.XRange;
            Zoom.YDist = 0.5*Zoom.YRange;
            Zoom.ZDist = 0.5*Zoom.ZRange;
            Zoom.ZoomLevelIdx = 6;
            Zoom.pct = Zoom.ZoomLevels(Zoom.ZoomLevelIdx);
    end  
    
    PODSData.Settings.Zoom = Zoom;
    PODSData.Handles = Handles;
    
    %guidata(source,PODSData);    

end

function [] = CursorMoving(~,PODSData)

    %PODSData = guidata(source);

    Zoom = PODSData.Settings.Zoom;
    DynamicAxes = PODSData.Settings.Zoom.DynamicAxes;
    
    posn = Zoom.StaticAxes.CurrentPoint(1,:);

    x = posn(1,1);
    y = posn(1,2);
    z = posn(1,3);
    
%     % x and y are already in expressed in proper pixel coordinates
%     x1 = min(max(1,x-0.5*Zoom.XDist),Zoom.XRange-Zoom.XDist) + 0.5;
%     y1 = min(max(1,y-0.5*Zoom.YDist),Zoom.YRange-Zoom.YDist) + 0.5;
%     z1 = min(max(1,z-0.5*Zoom.ZDist),Zoom.ZRange-Zoom.ZDist) + 0.5;

    % 0 instead of one works better to be able to go over all pixel values
    % x and y are already in expressed in proper pixel coordinates
    x1 = min(max(0,x-0.5*Zoom.XDist),Zoom.XRange-Zoom.XDist) + 0.5;
    y1 = min(max(0,y-0.5*Zoom.YDist),Zoom.YRange-Zoom.YDist) + 0.5;
    z1 = min(max(0,z-0.5*Zoom.ZDist),Zoom.ZRange-Zoom.ZDist) + 0.5;
    x2 = x1 + Zoom.XDist;
    y2 = y1 + Zoom.YDist;
    z2 = z1 + Zoom.ZDist;
    
    % if cursor is still within axes limits
    if x >= Zoom.OldXLim(1) && x <= Zoom.OldXLim(2) && ...
            y >= Zoom.OldYLim(1) && y <= Zoom.OldYLim(2) && ...
        z >= Zoom.OldZLim(1) && z <= Zoom.OldZLim(2)

        ZoomPct = round((Zoom.XRange/Zoom.XDist)*100);
        posn2 = Zoom.DynamicAxes.CurrentPoint(1,:);
        realx = posn2(1,1);
        realy = posn2(1,2);

        if ~Zoom.Freeze
            DynamicAxes.XLim = [x1 x2];
            DynamicAxes.YLim = [y1 y2];
        end

        try
            DynamicAxes.CursorPositionLabel.Text = [' (X,Y) = (',num2str(round(realx)),...
                ',',num2str(round(realy)),') | Zoom: ',...
                num2str(ZoomPct),'%',...
                ' | Value: ',num2str(Zoom.StaticImage.CData(round(realy),round(realx),:))];
        catch
            disp('Warning: Error updating cursor position label')
        end
        
        PODSData.Handles.fH.Pointer = 'crosshair';

    else

        PODSData.Handles.fH.Pointer = 'arrow';

        DynamicAxes.CursorPositionLabel.Text = sprintf('x = %3.0f;  y = %3.0f',0,0);
        
        if ~Zoom.Freeze
            DynamicAxes.XLim = Zoom.OldXLim;
            DynamicAxes.YLim = Zoom.OldYLim;
        end
        
    end

    PODSData.Settings.Zoom = Zoom;

    %drawnow
end

function [] = ChangeZoomLevel(source,PODSData)
    %PODSData = guidata(source);
    
    Zoom = PODSData.Settings.Zoom;

    switch PODSData.Handles.fH.SelectionType
        case 'normal'
            % click
            % increases zoom level until maximum is reached
            if Zoom.ZoomLevelIdx == 1
                Zoom.ZoomLevelIdx = length(Zoom.ZoomLevels);
            else
                Zoom.ZoomLevelIdx = Zoom.ZoomLevelIdx - 1;
            end

            Zoom.pct = Zoom.ZoomLevels(Zoom.ZoomLevelIdx);
            
        case 'alt'
            % ctrl-click or right-click
            % decreases zoom level until minimum (1X) is reached
            if Zoom.ZoomLevelIdx == length(Zoom.ZoomLevels)
                Zoom.ZoomLevelIdx = 1;
            else
                Zoom.ZoomLevelIdx = Zoom.ZoomLevelIdx + 1;
            end

            Zoom.pct = Zoom.ZoomLevels(Zoom.ZoomLevelIdx);

        case 'extend'
            % shift-click
            %   freezes current view
            if Zoom.Freeze
                Zoom.Freeze = false;
            else
                Zoom.Freeze = true;
            end

        case 'open'
            % double click
            %   shows default zoom
            Zoom.pct = 1;
    end
    
    Zoom.XDist = Zoom.pct*Zoom.XRange;
    Zoom.YDist = Zoom.pct*Zoom.YRange;
    Zoom.ZDist = Zoom.pct*Zoom.ZRange;

    PODSData.Settings.Zoom = Zoom;   
    
     if ~strcmp(PODSData.Handles.fH.SelectionType,'extend')
         CursorMoving(source,PODSData);
     end
end

function [axH] = restore_axis_defaults(axH,OriginalPlotBoxAspectRatio,OriginalTag)
        % restore axis defaults that were changed by imshow()
        axH.YDir = 'Reverse';
        axH.PlotBoxAspectRatioMode = 'manual';
        axH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
        axH.XTick = [];
        axH.YTick = [];
        axH.Tag = OriginalTag;
end