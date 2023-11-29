function ScreenSize = GetMaximizedScreenSize()
%% GetMaximizedScreenSize  Determine the currently drawable screen size.
%
%   Necessary workaround because the value given by get(0,'MonitorPositions') does not account for launcher bars
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

%% get screen width and height using Java commands

toolkit = java.awt.Toolkit.getDefaultToolkit();
ss = toolkit.getScreenSize;
screenWidth = ss.width;
screenHeight = ss.height;

%% get display scaling factor

% get screen size from MATLAB graphics root object
matlabScreenSize = get(0,"ScreenSize");

% get scaling factor by comparing Java and matlab screen widths
scaleFactor = matlabScreenSize(3)/screenWidth;

%% get full screen size

% adjust screen width and height
ScreenSize = [1 1 screenWidth*scaleFactor screenHeight*scaleFactor];

%% get screen inset sizes

jframe = javax.swing.JFrame;
insets = toolkit.getScreenInsets(jframe.getGraphicsConfiguration());

%% rescale screen inset sizes

leftInset = insets.left*scaleFactor;
rightInset = insets.right*scaleFactor;
bottomInset = insets.bottom*scaleFactor;
topInset = insets.top*scaleFactor;

%% get title bar height

fTemp = figure('Menu','none','ToolBar','none','Visible','off');
titleBarHeight = fTemp.OuterPosition(4) - fTemp.InnerPosition(4) + fTemp.OuterPosition(2) - fTemp.InnerPosition(2);
delete(fTemp);

%% get the final usable screen size, adjusting for title bar and insets

ScreenSize = ScreenSize + ...
    [leftInset, bottomInset, -leftInset-rightInset, -titleBarHeight-bottomInset-topInset];

end