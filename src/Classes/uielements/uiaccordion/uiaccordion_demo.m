function accordion = uiaccordion_demo()
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

    fH = uifigure(...
        "WindowStyle","alwaysontop",...
        "Name","uiaccordion demo",...
        "HandleVisibility","on");

    accordionGrid = uigridlayout(fH,[1,1]);

    % create the accordion
    accordion = uiaccordion(accordionGrid);

    %% ACCORDION ITEM 1

    % add first accordion item
    accordion.addItem("Title","Accordion item properties");
    % set size and spacing of pane grid
    accordion.Items(1).Pane.RowHeight = {25,25,25,25,25};
    accordion.Items(1).Pane.ColumnWidth = {'fit','1x'};
    accordion.Items(1).Pane.RowSpacing = 5;
    accordion.Items(1).Pane.ColumnSpacing = 5;
    % create label and numeric editfield for each property
    % Pane Background Color
    uilabel(accordion.Items(1).Pane,"Text","Pane Background Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","PaneBackgroundColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion
    % Title Background Color
    uilabel(accordion.Items(1).Pane,"Text","Title Background Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","TitleBackgroundColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion
    % Border Color
    uilabel(accordion.Items(1).Pane,"Text","Border Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","BorderColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion
    % Title Font Color
    uilabel(accordion.Items(1).Pane,"Text","Title Font Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","FontColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion
    % Border Width
    uilabel(accordion.Items(1).Pane,"Text","Border Width","FontColor",[0 0 0]);
    uieditfield(...
        accordion.Items(1).Pane,...
        "numeric",...
        "ValueChangedFcn",@borderWidthChanged,...
        "Value",1,...
        "UserData",accordion.Items(1));
    % Expanded Border Width
    uilabel(accordion.Items(1).Pane,"Text","Expanded Border Width","FontColor",[0 0 0]);
    uieditfield(...
        accordion.Items(1).Pane,...
        "numeric",...
        "ValueChangedFcn",@expandedBorderWidthChanged,...
        "Value",1,...
        "UserData",accordion.Items(1));
   
    %% ACCORDION ITEM 2

    accordion.addItem("Title","Plot type");

    accordion.Items(2).Pane.Padding = [0 0 0 0];

    % cell array of function handles
    funHandles = {...
        @(x,a,b,c) a.*cosd(x-b)+c,...
        @(x,a,b,c) a.*(cosd(x-b).^2)+c,...
        @(x,a,b,c) a.*sind(x-b)+c,...
        @(x,a,b,c) a.*(sind(x-b).^2)+c};

    % uilistbox to select plot type
    plotTypeListBox = uilistbox(...
        accordion.Items(2).Pane,...
        "Items",{'$Y=A\cos(\theta-B)+C$','$Y=A\cos^2(\theta-B)+C$','$Y=A\sin(\theta-B)+C$','$Y=A\sin^2(\theta-B)+C$'},...
        "ItemsData",funHandles,...
        "ValueChangedFcn",@updatePlot...
        );

    % create an interpreter style and add it to the listbox
    style1 = uistyle("Interpreter",'latex');
    addStyle(plotTypeListBox,style1)


    %% ACCORDION ITEM 3
    accordion.addItem("Title","Plot parameters");
    % set size and spacing of pane grid
    accordion.Items(3).Pane.RowHeight = {25,25,25};
    accordion.Items(3).Pane.ColumnWidth = {'fit','1x'};
    accordion.Items(3).Pane.RowSpacing = 5;
    accordion.Items(3).Pane.ColumnSpacing = 5;
    % create label and numeric editfield for each parameter
    % A
    uilabel(accordion.Items(3).Pane,"Text","A","FontColor",[0 0 0]);
    A_editfield = uieditfield(...
        accordion.Items(3).Pane,...
        "numeric",...
        "ValueChangedFcn",@updatePlot,...
        "Value",1);
    % B
    uilabel(accordion.Items(3).Pane,"Text","B","FontColor",[0 0 0]);
    B_editfield = uieditfield(...
        accordion.Items(3).Pane,...
        "numeric",...
        "ValueChangedFcn",@updatePlot);
    % C
    uilabel(accordion.Items(3).Pane,"Text","C","FontColor",[0 0 0]);
    C_editfield = uieditfield(...
        accordion.Items(3).Pane,...
        "numeric",...
        "ValueChangedFcn",@updatePlot);

    % add another accordion item to show plot
    accordion.addItem("Title","Plot");

    hAx = uiaxes(accordion.Items(4).Pane);
    hAx.XLim = [0 360];
    hAx.Title.Interpreter = "latex";
    hAx.Title.String = "$Y=A\cos^2(\theta-B)+C$";
    hAx.XAxis.TickLabelFormat = '%g\\circ';
    hAx.XLabel.Interpreter = "latex";
    hAx.XLabel.String = "$\theta$";
    hAx.YLabel.Interpreter = "latex";
    hAx.YLabel.String = "$Y$";
    hAx.XTick = 0:45:360;

    x = 0:360;
    y = cosd(x);

    hPlot = plot(hAx,x,y);



    % expand the first accordion item
    accordion.Items(1).expand();
    % move gui to screen center
    movegui(fH,'center')
    % then shift 400 px to the left
    fH.Position(1) = fH.Position(1)-400;
    % make the figure visible
    fH.Visible = "on";

    % color change callback
    function setAccordionColors(source,~)
        % get user-selected color from color picker
        chosenColor = uisetcolor();
        % make sure it's valid
        if size(chosenColor,2) == 1
            % if invalid, error uialert box
            uialert(fH,"Invalid color","Error");
        else
            % if valid, set the indicated property to the chosen color
            source.UserData.(source.Tag) = chosenColor;
        end
    end

    % plot update callback
    function updatePlot(~,~)

        A = A_editfield.Value;
        B = B_editfield.Value;
        C = C_editfield.Value;

        hAx.Title.String = plotTypeListBox.Items{plotTypeListBox.ValueIndex};
        hPlot.YData = plotTypeListBox.Value(0:360,A,B,C);

    end

    function borderWidthChanged(source,~)
        source.UserData.BorderWidth = source.Value;
    end

    function expandedBorderWidthChanged(source,~)
        source.UserData.ExpandedBorderWidth = source.Value;
    end


end