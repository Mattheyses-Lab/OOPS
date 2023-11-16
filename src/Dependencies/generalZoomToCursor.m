function generalZoomToCursor(source,~)
%% ZoomToCursor  
%
%   allows for dynamic zooming/panning in axes containing an image
%   all OOPSGUI axes using ZoomToCursor will have a custom toolbar state
%   button, clicking will activate ZoomToCursor behavior
%           clicking button again will deactivate
%           clicking within axes will increase zoom through a set number of
%           zoom levels until max zoom is reached
%           double-click will return to default zoom value
%           shift-click will freeze axis limits at current zoom
%-------------------------------------------------------------------------%
%
%
% This function is a heavily modified version of zoom2cursor
% (Written by Brett Shoelson, Ph.D. (shoelson@helix.nih.gov,
% shoelson@hotmail.com))
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

    
    % get handle to the ancestor figure
    AncestorFigure = ancestor(source,'figure');

    % get handle to the ancestor axes
    DynamicAxes = ancestor(source,'axes');

    % get list of axes properties
    axProperties = fieldnames(DynamicAxes);

    % check if Zoom data is not already a property
    if ~ismember('Zoom',axProperties)
        Zoom = struct('XRange',0,...
            'YRange',0,...
            'ZRange',0,...
            'XDist',0,...
            'YDist',0,...
            'OldXLim',[0 1],...
            'OldYLim',[0 1],...
            'pct',1,...
            'ZoomLevels',[1/20 1/15 1/10 1/5 1/3 1/2 1/1.5 1/1.25 1],...
            'ZoomLevelIdx',9,...
            'OldWindowButtonMotionFcn','',...
            'OldImageButtonDownFcn','',...
            'Active',false,...
            'Freeze',false,...
            'Restore',false,...
            'RestoreProps',[],...
            'CurrentButton',[],...
            'StaticAxes',[],...
            'StaticImage',[],...
            'DynamicAxesParent',[],...
            'AncestorFigure',[]);
        DynamicAxes.addprop('Zoom');
        DynamicAxes.Zoom = Zoom;
    else
        % get the zoom settings structure
        Zoom = DynamicAxes.Zoom;
    end

    % default freeze status
    freezeState = false;

    Zoom.Freeze = freezeState;

    % try and delete previous CursorPositionLabel, this is necessary in
    % case the user activates the Toolbar state button (ZoomToCursor) in an
    % axes without first deactivating the button in another axes

    try
        delete(DynamicAxes.CursorPositionLabel)
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
            % Get the parent container to place static reference Axes
            Zoom.DynamicAxesParent = DynamicAxes.Parent;
            % get the ancestor figure
            Zoom.AncestorFigure = AncestorFigure;
            % Determine the positioning of the axes that called the callback
            pos = DynamicAxes.InnerPosition;
            % Build new axes with same position and limits
            Zoom.StaticAxes = uiaxes(Zoom.DynamicAxesParent,...
                'Units','Normalized',...
                'InnerPosition',pos,...
                'XTick',[],...
                'YTick',[],...
                'XLim',DynamicAxes.XLim,...
                'YLim',DynamicAxes.YLim,...
                'Tag','StaticReferenceAxes');
            Zoom.StaticAxes.Toolbar.Visible = 'Off';
            % Hide the static axes
            Zoom.StaticAxes.Visible = 'Off';
            try
                DynamicAxes.addprop('CursorPositionLabel');
            catch
                % property already exists
            end
            % label to display cursor position
            DynamicAxes.CursorPositionLabel = uilabel(Zoom.DynamicAxesParent,...
                'Position',[1 1 Zoom.DynamicAxesParent.Position(3) 20],...
                'BackgroundColor','Black',...
                'FontColor','Yellow',...
                'Text','');
            
            % get original axes values
            pbarOriginal = Zoom.StaticAxes.PlotBoxAspectRatio;
            tagOriginal = Zoom.StaticAxes.Tag;
            
            % get the handle to the image that will be changing sizes
            Zoom.DynamicImage = findobj(DynamicAxes,'Type','image');
            % placeholder image in the reference (static) axes
            Zoom.StaticImage = imshow(Zoom.DynamicImage.CData,'Parent',Zoom.StaticAxes);

            % restore axis defaults for consistent display
            Zoom.StaticAxes = restore_axis_defaults(Zoom.StaticAxes,pbarOriginal,tagOriginal);

            % hide the static image
            Zoom.StaticImage.Visible = 'Off';

            % make static axes active
            axes(Zoom.StaticAxes);

            % store the old axes limits in the event we need to restore them
            Zoom.OldXLim = DynamicAxes.XLim;
            Zoom.OldYLim = DynamicAxes.YLim;

            % get the current axes ranges by taking the difference of each axis limit
            Zoom.XRange = diff(DynamicAxes.XLim);
            Zoom.YRange = diff(DynamicAxes.YLim);

            Zoom.XDist = Zoom.pct*Zoom.XRange;
            Zoom.YDist = Zoom.pct*Zoom.YRange;

            % store the old 'windowsbuttonmotionfcn' and image 'buttondownfcn' handles
            Zoom.OldWindowButtonMotionFcn = Zoom.AncestorFigure.WindowButtonMotionFcn;
            Zoom.OldImageButtonDownFcn = Zoom.DynamicImage.ButtonDownFcn;

            Zoom.AncestorFigure.Pointer = 'crosshair';
            Zoom.AncestorFigure.WindowButtonMotionFcn = @(o,e) CursorMoving(o,DynamicAxes);
            Zoom.DynamicImage.ButtonDownFcn = @(o,e) ChangeZoomLevel(o,DynamicAxes);
            Zoom.DynamicImage.HitTest = 'On';
            
        case 0 % off
            Zoom.Active = false;
            Zoom.AncestorFigure.WindowButtonMotionFcn = Zoom.OldWindowButtonMotionFcn;
            Zoom.DynamicImage.ButtonDownFcn = Zoom.OldImageButtonDownFcn;
            Zoom.AncestorFigure.Pointer = 'arrow';
            
            Zoom.DynamicImage.HitTest = 'Off';
            
            try
                delete(DynamicAxes.CursorPositionLabel)
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
            DynamicAxes.XLim = Zoom.OldXLim;
            DynamicAxes.YLim = Zoom.OldYLim;

    end  
    
    DynamicAxes.Zoom = Zoom;
    

end

function [] = CursorMoving(~,DynamicAxes)

    Zoom = DynamicAxes.Zoom;
    
    posn = Zoom.StaticAxes.CurrentPoint(1,:);

    x = posn(1,1);
    y = posn(1,2);
    
    % 0 instead of one works better to be able to go over all pixel values
    % x and y are already in expressed in proper pixel coordinates
    x1 = min(max(0,x-0.5*Zoom.XDist),Zoom.XRange-Zoom.XDist) + 0.5;
    y1 = min(max(0,y-0.5*Zoom.YDist),Zoom.YRange-Zoom.YDist) + 0.5;

    x2 = x1 + Zoom.XDist;
    y2 = y1 + Zoom.YDist;
    
    % if cursor is still within axes limits
    if x >= Zoom.OldXLim(1) && x <= Zoom.OldXLim(2) && ...
            y >= Zoom.OldYLim(1) && y <= Zoom.OldYLim(2)

        ZoomPct = round((Zoom.XRange/Zoom.XDist)*100);
        posn2 = DynamicAxes.CurrentPoint(1,:);
        realx = round(posn2(1,1));
        realy = round(posn2(1,2));

        if ~Zoom.Freeze
            DynamicAxes.XLim = [x1 x2];
            DynamicAxes.YLim = [y1 y2];
        end

        % set the inspection label based on the type of axes we are in and the location of the cursor
        try
            DynamicAxes.CursorPositionLabel.Text = [' (X,Y) = (',num2str(realx),...
                ',',num2str(realy),') | Zoom: ',...
                num2str(ZoomPct),'%',...
                ' | Value: ',num2str(Zoom.StaticImage.CData(realy,realx,:))];
        catch
            DynamicAxes.CursorPositionLabel.Text = 'Hover over image to pan/zoom';
            %disp('Warning: Error updating cursor position label')
        end
        
        Zoom.AncestorFigure.Pointer = 'crosshair';

    else

        Zoom.AncestorFigure.Pointer = 'arrow';

        DynamicAxes.CursorPositionLabel.Text = sprintf('x = %3.0f;  y = %3.0f',0,0);
        
        if ~Zoom.Freeze
            DynamicAxes.XLim = Zoom.OldXLim;
            DynamicAxes.YLim = Zoom.OldYLim;
        end
        
    end

    DynamicAxes.Zoom = Zoom;

    %drawnow
end

function [] = ChangeZoomLevel(source,DynamicAxes)
    
    Zoom = DynamicAxes.Zoom;

    switch Zoom.AncestorFigure.SelectionType
        case 'normal'
            % click
            % increases zoom level until maximum is reached
            % unless Freeze is on
            if ~Zoom.Freeze
                if Zoom.ZoomLevelIdx == 1
                    Zoom.ZoomLevelIdx = length(Zoom.ZoomLevels);
                else
                    Zoom.ZoomLevelIdx = Zoom.ZoomLevelIdx - 1;
                end
    
                Zoom.pct = Zoom.ZoomLevels(Zoom.ZoomLevelIdx);
            end
            
        case 'alt'
            % ctrl-click or right-click
            % decreases zoom level until minimum (1X) is reached
            % unless freeze is on

            if ~Zoom.Freeze
                if Zoom.ZoomLevelIdx == length(Zoom.ZoomLevels)
                    Zoom.ZoomLevelIdx = 1;
                else
                    Zoom.ZoomLevelIdx = Zoom.ZoomLevelIdx + 1;
                end
    
                Zoom.pct = Zoom.ZoomLevels(Zoom.ZoomLevelIdx);
            end

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
            % unless Freeze is on
            if ~Zoom.Freeze
                Zoom.pct = 1;
            end
    end
    
    Zoom.XDist = Zoom.pct*Zoom.XRange;
    Zoom.YDist = Zoom.pct*Zoom.YRange;

    DynamicAxes.Zoom = Zoom;   
    
    if ~strcmp(Zoom.AncestorFigure.SelectionType,'extend')
        CursorMoving(source,DynamicAxes);
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
