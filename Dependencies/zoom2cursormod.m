function zoom2cursormod(source)
% FUNCTION ZOOM2CURSOR
%
% zoom2cursor, without arguments, will activate the current axis, create a text box showing the
% current position of the mouse pointer (similar to pixval), and automatically zoom the image to the
% location of the cursor  as it is moved. The zoomed display dynamically scrolls with the motion of the cursor.
%
% By default, the function zooms to 50% of the image in the axis.
%
% BUTTON CLICKS:
% Left-clicking will zoom in further, and right-clicking will zoom out.
% Shift-clicking (or simultaneously clicking the left and right mouse buttons) at any point
% will display the original (un-zoomed) image, as will moving the
% cursor outside of the current axis. The zoom percentage is restored when the mouse is moved.
% Double-clicking zooms out to the original image, modifying the zoom percentage.
%
% Tested under R12.1 and R13.
%
% Written by Brett Shoelson, Ph.D. (shoelson@helix.nih.gov, shoelson@hotmail.com)
% 12/26/02
% 2/16/03; Rev 2: Program is more robust; fixes a bug when window is resized.
%                 Incremental increase/decrease in zoom percent (on mouseclick) has been reduced.
%                 Also: Now works with images, surfaces, lines (and thus plots), and patches (rather than just images)



Handles = guidata(source);


currfig = Handles.fH;

figure(currfig);
%zoomparams.currax = findobj(currfig,'type','axes');
zoomparams.currax = Handles.ax;

%Precedence: Images, surfaces, lines, patches
%Are there any images in the current axes?
%zoomparams.currobj = axH.Image;

zoomparams.pct = 0.5; %Default value

zoomparams.currobj = Handles.Image;

zoomparams.objtype = 'image';


zoomparams.bdfcnold = zoomparams.currobj.ButtonDownFcn;
zoomparams.baold = zoomparams.currobj.BusyAction;
zoomparams.oldpointer = currfig.Pointer;
currfig.Pointer = 'crosshair';
axes(zoomparams.currax);

currax = zoomparams.currax;

% make copy of current axis
zoomparams.refax = copyobj(zoomparams.currax,Handles.Panel1);

% For simplicity, I store the bdfunction in both the current axis AND the current object. For images, it makes sense to
% store it in the object (since the object covers the axis). For other objects (like lines), storing in the object forces
% a click directly on the line/point, but storing in the axis only means a click on the line does not trigger the callback.
warning off; %I turn this off because of the annoying (but erroneous)"Unrecognized OpenGL" message.
zoomparams.currax.ButtonDownFcn = @bdfcn;
zoomparams.currax.BusyAction = 'queue';

zoomparams.currobj.ButtonDownFcn = @bdfcn;
zoomparams.currobj.BusyAction = 'queue';

set(findobj(zoomparams.refax,'type','children'),'HandleVisibility','On');
zoomparams.refax.Visible = 'off';
axes(zoomparams.refax);
cla;

zoomparams.oldaxunits = zoomparams.currax.Units;
zoomparams.ydir = zoomparams.currax.YDir;

zoomparams.oldxlim = zoomparams.currax.XLim;
zoomparams.oldylim = zoomparams.currax.YLim;
zoomparams.oldzlim = zoomparams.currax.ZLim;
%zoomparams.dbold = currfig.doublebuffer;
zoomparams.xrange = diff(zoomparams.oldxlim);
zoomparams.yrange = diff(zoomparams.oldylim);
zoomparams.zrange = diff(zoomparams.oldzlim);
zoomparams.xdist = zoomparams.pct*zoomparams.xrange;
zoomparams.ydist = zoomparams.pct*zoomparams.yrange;
zoomparams.zdist = zoomparams.pct*zoomparams.zrange;
zoomparams.oldwbmf = currfig.WindowButtonMotionFcn;


currfig.addprop('zoomfcnhandle');
currfig.zoomfcnhandle = @zoomfcn;
currfig.addprop('bdfcnhandle');
currfig.bdfcnhandle = @bdfcn;

%% Stuck Here


currfig.WindowButtonMotionFcn = @zoomfcn;
endbutton = uibutton(Handles.Panel1,'Push','Text','X','Position',[5 5 100 20],'ButtonPushedFcn',@endfcn);
    
%zoomparams.dispbox1 = uicontrol('style','frame','backgroundcolor','k','units','normalized','position',[0.0475 0 0.35 0.065]);
if ~strcmp(zoomparams.objtype,'surface')
    msgstr = sprintf('x = %3.0f;  y = %3.0f',0,0);
else
    msgstr = sprintf('x = %3.0f;  y = %3.0f; z = %3.0f',0,0,0);
end
zoomparams.dispbox2 = uilabel(Handles.Panel1,'BackgroundColor','Black','FontColor','Yellow',...
	'Position',[105 5 200 20],'Text',msgstr,...
    'HorizontalAlignment','Left');


Handles.zoomparams = zoomparams;
Handles.Image = zoomparams.currobj;
Handles.ax = zoomparams.currax;
Handles.fH = currfig;
Handles.dispbox2 = zoomparams.dispbox2;


guidata(source,Handles);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = zoomfcn(source,event)
Handles = guidata(source);
zoomparams = Handles.zoomparams;

posn = zoomparams.refax.CurrentPoint;
posn = posn(1,:);

x = posn(1,1);
y = posn(1,2);
z = posn(1,3);

switch zoomparams.objtype
    case 'image'
        % x and y are already in expressed in proper pixel coordinates
        x1 = min(max(1,x-0.5*zoomparams.xdist),zoomparams.xrange-zoomparams.xdist) + 0.5;
        y1 = min(max(1,y-0.5*zoomparams.ydist),zoomparams.yrange-zoomparams.ydist) + 0.5;
        z1 = min(max(1,z-0.5*zoomparams.zdist),zoomparams.zrange-zoomparams.zdist) + 0.5;
        x2 = x1 + zoomparams.xdist;
        y2 = y1 + zoomparams.ydist;
        z2 = z1 + zoomparams.zdist;
    case {'line','surface','patch'}
        % x, y and z are in normalized units; must be converted
        x = zoomparams.oldxlim(1) + x*zoomparams.xrange;
        y = zoomparams.oldylim(1) + y*zoomparams.yrange;
        z = zoomparams.oldzlim(1) + z*zoomparams.zrange;
        % now change the limits of currax, ensuring that the original limits are not exceeded
        x1 = max(x-zoomparams.xdist/2,zoomparams.oldxlim(1));
        y1 = max(y-zoomparams.ydist/2,zoomparams.oldylim(1));
        z1 = max(z-zoomparams.zdist/2,zoomparams.oldzlim(1));
        x2 = x1+zoomparams.xdist;
        y2 = y1+zoomparams.ydist;
        z2 = z1+zoomparams.zdist;
        % if new limits are out of range, adjust them:
        if x2 > zoomparams.oldxlim(2)
            x2 = zoomparams.oldxlim(2);
            x1 = x2 - zoomparams.xdist;
        end
        if y2 > zoomparams.oldylim(2)
            y2 = zoomparams.oldylim(2);
            y1 = y2 - zoomparams.ydist;
        end
        if z2 > zoomparams.oldzlim(2)
            z2 = zoomparams.oldzlim(2);
            z1 = z2 - zoomparams.zdist;
        end

        % now get the x,y positions in currax for display purposes
        posn = zoomparams.currax.CurrentPoint;
        posn = posn(1,:);
        x = posn(1,1);
        y = posn(1,2);
        z = posn(1,3);
end

if x >= zoomparams.oldxlim(1) & x <= zoomparams.oldxlim(2) & ...
        y >= zoomparams.oldylim(1) & y <= zoomparams.oldylim(2) & ...
    z >= zoomparams.oldzlim(1) & z <= zoomparams.oldzlim(2)
    if strcmp(zoomparams.objtype,'surface')
        zoomparams.dispbox2.Text = sprintf('x = %3.2f;  y = %3.2f; z = %3.2f',x,y,z);
        zoomparams.currax.XLim = [x1 x2];
        zoomparams.currax.YLim = [y1 y2];
        zoomparams.currax.ZLim = [z1 z2];
    else
        zoomparams.dispbox2.Text = sprintf('x = %3.2f;  y = %3.2f',x,y);
        zoomparams.currax.XLim = [x1 x2];
        zoomparams.currax.YLim = [y1 y2];
    end
else
    if strcmp(zoomparams.objtype,'surface')
        zoomparams.dispbox2.Text = sprintf('x = %3.f;  y = %3.0f; z = %3.0f',0,0,0);
        zoomparams.currax.XLim = zoomparams.oldxlim;
        zoomparams.currax.YLim = zoomparams.oldylim;
        zoomparams.currax.ZLim = zoomparams.oldzlim;
    else
        zoomparams.dispbox2.Text = sprintf('x = %3.0f;  y = %3.0f',0,0);
        zoomparams.currax.XLim = zoomparams.oldxlim;
        zoomparams.currax.YLim = zoomparams.oldylim;
    end
end

%Note: up to this point, the only thing that has changed in refax is the currentpoint property

Handles.zoomparams = zoomparams;
Handles.ax = zoomparams.currax;
Handles.dispbox2 = zoomparams.dispbox2;

guidata(source,Handles);


end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function bdfcn(source,event)
    Handles = guidata(source);
    zoomparams = Handles.zoomparams;
    % SelectionType
    % normal: Click left mouse button
    % extend: Shift - click left mouse button or click both left and right mouse buttons
    % alt: Control - click left mouse button or click right mouse button
    % open: Double click any mouse button

    switch get(gcf,'selectiontype')
        case 'normal'
            zoomparams.pct = max(0.01,zoomparams.pct*0.9);
        case 'alt'
            zoomparams.pct = min(1,zoomparams.pct*1.1);
        case 'extend'
            zoomparams.currax.XLim = zoomparams.oldxlim;
            zoomparams.currax.YLim = zoomparams.oldylim;
            zoomparams.currax.ZLim = zoomparams.oldzlim;
        case 'open'
            zoomparams.pct = 1;
    end

    zoomparams.xdist = zoomparams.pct*zoomparams.xrange;
    zoomparams.ydist = zoomparams.pct*zoomparams.yrange;
    zoomparams.zdist = zoomparams.pct*zoomparams.zrange;

    currfig = Handles.fH;
    Handles.zoomparams = zoomparams;
    Handles.currax = zoomparams.currax;
    guidata(source,Handles);

    if ~strcmp(currfig.SelectionType,'extend')
        zoomfcn(source,event);
    end
    
    
    
return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [] = endfcn(source,event)
Handles = guidata(source);
zoomparams = Handles.zoomparams;

zoomparams.fH.WindowButtonMotionFcn = zoomparams.oldwbmf;
zoomparams.curraxunits = zoomparams.oldaxunits;
zoomparams.currax.XLim = zoomparams.oldxlim;
zoomparams.xurrax.YLim = zoomparams.oldylim;
zoomparams.currobj.ButtonDownFcn = zoomparams.bdfcnold;
zoomparams.currobj.BusyAction = zoomparams.baold;
zoomparams.fH.Pointer = zoomparams.oldpointer;
delete(zoomparams.dispbox2);
delete(gcbo);

Handles.zoomparams = zoomparams;
guidata(source,Handles);


end


