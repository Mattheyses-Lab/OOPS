function colorOut = colorPicker()
%%  COLORPICKER Opens a GUI to interactively choose a color
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

    % default output
    colorOut = [];

    % main figure
    fH = uifigure("HandleVisibility","on",...
        "WindowStyle","modal",...
        "Name","Color Picker",...
        "Position",[0 0 500 500],...
        "Visible","off",...
        "Interruptible","on",...
        "BusyAction","queue",...
        "CloseRequestFcn",@collectOutputs);

    % gridlayout manager to hold the colorbarWidget and example image
    mainGrid = uigridlayout(fH,[2,2],...
        "ColumnWidth",{'1x','1x'},...
        "RowHeight",{'1x',20},...
        "Padding",[5 5 5 5],...
        "RowSpacing",5,...
        "ColumnSpacing",5,...
        "BackgroundColor",[0 0 0]);

    % create a colorPickerWidget object and place it in the grid
    hcolorPicker = colorPickerWidget(mainGrid);
    hcolorPicker.Layout.Row = 1;
    hcolorPicker.Layout.Column = [1 2];

    % create buttons to...
    % continue
    continueButton = uibutton(mainGrid,...
        "BackgroundColor",[1 1 1],...
        "ButtonPushedFcn",@collectOutputs,...
        "Text","Continue",...
        "FontColor",[0 0 0],...
        "Tag","continue");
    continueButton.Layout.Row = 2;
    continueButton.Layout.Column = 1;
    % or cancel
    cancelButton = uibutton(mainGrid,...
        "BackgroundColor",[1 1 1],...
        "ButtonPushedFcn",@collectOutputs,...
        "Text","Cancel",...
        "FontColor",[0 0 0],...
        "Tag","cancel");
    cancelButton.Layout.Row = 2;
    cancelButton.Layout.Column = 2;


    % move gui to the center and make it visible
    movegui(fH,'center');
    % draw
    drawnow
    % make visible
    fH.Visible = 'On';

    % wait until figure closed to continue
    waitfor(fH)

    function collectOutputs(source,~)
        switch source.Tag
            case 'continue'
                colorOut = hcolorPicker.currentColor;
            otherwise
                colorOut = [];
        end
        delete(fH)
    end

end