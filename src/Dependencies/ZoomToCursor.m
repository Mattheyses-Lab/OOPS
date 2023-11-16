function ZoomToCursor(source,~)
%%  ZoomToCursor allows for dynamic zooming/panning in GUI axes
%
%   NOTES:
%       All OOPSGUI axes using ZoomToCursor will have a custom toolbar state button with the following behavior
%           clicking will activate ZoomToCursor behavior
%           clicking button again will deactivate
%
%       When active:
%           moving the cursor within the axes will shift the view to follow the cursor
%           left-clicking within axes will increase zoom through a set number of zoom levels
%           right-clicking within axes will decrease zoom through a set number of zoom levels
%           double-click will return to default zoom value
%           shift-click will freeze axis limits at current zoom and fix the position
%
%   This function is a heavily modified version of zoom2cursor
%   (Written by Brett Shoelson, Ph.D. (shoelson@helix.nih.gov, shoelson@hotmail.com))
%
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

    % get the GUI data
    OOPSData = guidata(source);
    % get the handles structure
    Handles = OOPSData.Handles;
    % get the zoom settings structure
    Zoom = OOPSData.Settings.Zoom;

    % default freeze status
    freezeState = false;
    % default axes limits
    XLimState = Zoom.OldXLim;
    YLimState = Zoom.OldYLim;

    % if the callback was invoked manually with the Zoom.Restore flag
    if Zoom.Restore
        % then restore the prior freeze ststus and axes limits
        freezeState = Zoom.RestoreProps.freezeState;
        XLimState = Zoom.RestoreProps.XLimState;
        YLimState = Zoom.RestoreProps.YLimState;
    else

        % If ZoomToCursor is already active, check that the axes that called the callback
        %   is the current zoom axes. If so, continue as normal. If not, disable 
        %   zoom on current axes before continuing
        if Zoom.Active
            % get the tag to axes where ZoomToCursor is currently enabled
            CurrentButtonTag = Zoom.CurrentButton.Tag;
            % get the tag of the button that called the callback
            CallingButtonTag = source.Tag;
            % the tag of the ZoomToCursor axes toolbar button is a char array formatted like:
            %   ['ZoomToCursor',ax.Tag]
            %   where ax is the axes containing the button
            % If the axes calling the callback is not the current zoom axes
            if ~strcmp(CurrentButtonTag,CallingButtonTag)
                % before disabling, store whether the axes zoom was frozen
                freezeState = Zoom.Freeze;
                XLimState = Zoom.DynamicAxes.XLim;
                YLimState = Zoom.DynamicAxes.YLim;
                % then disable zoom before continuing
                % use tag to index the Handles structure and change state of button
                Handles.(CurrentButtonTag).Value = 0;
                % call ZoomToCursor with current button to deactivate the zoom
                ZoomToCursor(Handles.(CurrentButtonTag));
                % get the freeze state of the previous zoom axes we just deactivated
            end
        end

    end

    Zoom.Freeze = freezeState;

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

            % add dynamic prop to hold active object boundary
            try
                Zoom.DynamicAxes.addprop('ActiveObjectBoundary');
            catch
                % property already exists
            end
            % placeholder for display of object boundary
            Zoom.DynamicAxes.ActiveObjectBoundary = gobjects(1,1);
            
            % get original axes values
            pbarOriginal = Zoom.StaticAxes.PlotBoxAspectRatio;
            tagOriginal = Zoom.StaticAxes.Tag;
            
            % get the handle to the image that will be changing sizes
            Zoom.DynamicImage = findobj(Zoom.DynamicAxes,'Type','image');
            % placeholder image in the reference (static) axes
            Zoom.StaticImage = imshow(Zoom.DynamicImage.CData,'Parent',Zoom.StaticAxes);

            % restore axis defaults for consistent display
            Zoom.StaticAxes = restore_axis_defaults(Zoom.StaticAxes,pbarOriginal,tagOriginal);

            % hide the static image
            Zoom.StaticImage.Visible = 'Off';

            % make static axes active
            axes(Zoom.StaticAxes);

            % store the old axes limits in the event we need to restore them
            Zoom.OldXLim = Zoom.DynamicAxes.XLim;
            Zoom.OldYLim = Zoom.DynamicAxes.YLim;

            % get the current axes ranges by taking the difference of each axis limit
            Zoom.XRange = diff(Zoom.DynamicAxes.XLim);
            Zoom.YRange = diff(Zoom.DynamicAxes.YLim);

            % account for the possibility of a clicked zoom tb button when
            % another axes was already active and the freeze was on
            if Zoom.Freeze
                Zoom.DynamicAxes.XLim = XLimState;
                Zoom.DynamicAxes.YLim = YLimState;
            end

            Zoom.XDist = Zoom.pct*Zoom.XRange;
            Zoom.YDist = Zoom.pct*Zoom.YRange;

            % store the old 'windowsbuttonmotionfcn' and image 'buttondownfcn' handles
            Zoom.OldWindowButtonMotionFcn = Handles.fH.WindowButtonMotionFcn;
            Zoom.OldImageButtonDownFcn = Zoom.DynamicImage.ButtonDownFcn;

            Handles.fH.Pointer = 'crosshair';
            Handles.fH.WindowButtonMotionFcn = @(o,e) CursorMoving(o,OOPSData);
            Zoom.DynamicImage.ButtonDownFcn = @(o,e) ChangeZoomLevel(o,OOPSData);
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

            % try and delete the object boundary
            try
                ObjectBoundary = findobj(Zoom.DynamicAxes,'Tag','ActiveObjectBoundary');
                delete(ObjectBoundary);
            catch
                warning('Failed to delete active object boundary');
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

    end  
    
    OOPSData.Settings.Zoom = Zoom;
    OOPSData.Handles = Handles;
    

end

function [] = CursorMoving(~,OOPSData)

    Zoom = OOPSData.Settings.Zoom;
    DynamicAxes = OOPSData.Settings.Zoom.DynamicAxes;
    
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
        posn2 = Zoom.DynamicAxes.CurrentPoint(1,:);
        realx = round(posn2(1,1));
        realy = round(posn2(1,2));

        if ~Zoom.Freeze
            DynamicAxes.XLim = [x1 x2];
            DynamicAxes.YLim = [y1 y2];
        end

        % set the inspection label based on the type of axes we are in and the location of the cursor
        switch DynamicAxes.Tag
            case 'Order'

                try
                    DynamicAxes.CursorPositionLabel.Text = ...
                        [' (X,Y) = (',num2str(realx),...
                        ',',num2str(realy),') | Zoom: ',...
                        num2str(ZoomPct),'%',...
                        ' | Order: ',num2str(OOPSData.CurrentImage(1).OrderImage(realy,realx))];
                catch
                    disp('Warning: Error updating cursor position label')
                end

            case 'AverageIntensity'

                try
                    DynamicAxes.CursorPositionLabel.Text = ...
                        [' (X,Y) = (',num2str(realx),...
                        ',',num2str(realy),') | Zoom: ',...
                        num2str(ZoomPct),'%',...
                        ' | Norm. average intensity: ',num2str(OOPSData.CurrentImage(1).I(realy,realx))];
                catch
                    disp('Warning: Error updating cursor position label')
                end

            case 'Azimuth'

                try
                    DynamicAxes.CursorPositionLabel.Text = ...
                        [' (X,Y) = (',num2str(realx),...
                        ',',num2str(realy),') | Zoom: ',...
                        num2str(ZoomPct),'%',...
                        ' | Azimuth: ',num2str(OOPSData.CurrentImage(1).AzimuthImage(realy,realx)),' radians, '...
                        num2str(rad2deg(OOPSData.CurrentImage(1).AzimuthImage(realy,realx))),' °'];
                catch
                    disp('Warning: Error updating cursor position label')
                end

            case 'Mask'

                % if cursor is on an object
                if OOPSData.CurrentImage(1).bw(realy,realx)
                    % get the idx of the object
                    ObjIdx = OOPSData.CurrentImage(1).L(realy,realx);
                    % display in the label
                    DynamicAxes.CursorPositionLabel.Text = ...
                        [' (X,Y) = (',num2str(realx),',',num2str(realy),...
                        ') | Zoom: ',num2str(ZoomPct),'%',...
                        ' | Object ',num2str(ObjIdx)];

                    % if the cursor has moved to a new object
                    if ObjIdx~=Zoom.ActiveObjectIdx
                        % delete any ActiveObjectBoundary (important in case our objects are "touching" in the mask)
                        delete(findobj(DynamicAxes,'Tag','ActiveObjectBoundary'));
                        % retrieve the new object
                        Object = OOPSData.CurrentImage(1).Object(ObjIdx);
                        % and its boundary
                        Boundary = Object.Boundary;
                        % plot the boundary as a primitive line colored by object label
                        DynamicAxes.ActiveObjectBoundary = line(DynamicAxes,...
                            Boundary(:,2),Boundary(:,1),...
                            'Color',Object.Label.Color,...
                            'Linewidth',2,...
                            'Tag','ActiveObjectBoundary',...
                            'ButtonDownFcn',@SelectSingleObjects);
                        % store the new object idx in the Zoom struct
                        Zoom.ActiveObjectIdx = ObjIdx;
                    end

                else
                    % just display the (x,y) position and zoom level
                    DynamicAxes.CursorPositionLabel.Text = ...
                        [' (X,Y) = (',num2str(realx),',',num2str(realy),...
                        ') | Zoom: ',num2str(ZoomPct),'%',...
                        ' | No object'];
                    % delete the ActiveObjectBoundary
                    ObjectBoundary = findobj(DynamicAxes,'Tag','ActiveObjectBoundary');
                    delete(ObjectBoundary);
                    % set ActiveObjectIdx to NaN, as there is no object under the cursor
                    Zoom.ActiveObjectIdx = NaN;
                end

            case 'CustomStat'

                % get the custom stat associated with the axes
                thisStat = DynamicAxes.UserData;

                try
                    DynamicAxes.CursorPositionLabel.Text = ...
                        [' (X,Y) = (',num2str(realx),...
                        ',',num2str(realy),') | Zoom: ',...
                        num2str(ZoomPct),'%',...
                        ' | ',thisStat.StatisticDisplayName,': ',num2str(OOPSData.CurrentImage(1).([thisStat.StatisticName,'Image'])(realy,realx))];
                catch
                    disp('Warning: Error updating cursor position label')
                end

            otherwise

                try
                    DynamicAxes.CursorPositionLabel.Text = [' (X,Y) = (',num2str(realx),...
                        ',',num2str(realy),') | Zoom: ',...
                        num2str(ZoomPct),'%',...
                        ' | Value: ',num2str(Zoom.StaticImage.CData(realy,realx,:))];
                catch
                    disp('Warning: Error updating cursor position label')
                end

        end
        
        OOPSData.Handles.fH.Pointer = 'crosshair';

    else

        OOPSData.Handles.fH.Pointer = 'arrow';

        %DynamicAxes.CursorPositionLabel.Text = sprintf('x = %3.0f;  y = %3.0f',0,0);
        DynamicAxes.CursorPositionLabel.Text = ' (X,Y) = (0,0)';
        
        if ~Zoom.Freeze
            DynamicAxes.XLim = Zoom.OldXLim;
            DynamicAxes.YLim = Zoom.OldYLim;
        end
        
    end

    OOPSData.Settings.Zoom = Zoom;

    %drawnow
end

function [] = ChangeZoomLevel(source,OOPSData)
    %OOPSData = guidata(source);
    
    Zoom = OOPSData.Settings.Zoom;

    switch OOPSData.Handles.fH.SelectionType
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

    OOPSData.Settings.Zoom = Zoom;   
    
    if ~strcmp(OOPSData.Handles.fH.SelectionType,'extend')
        CursorMoving(source,OOPSData);
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