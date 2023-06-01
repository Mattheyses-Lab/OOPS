function uiaccordion_demo()

    fH = uifigure(...
        "WindowStyle","alwaysontop",...
        "Name","Accordion demo",...
        "Position",[0 0 400 500],...
        "HandleVisibility","on",...
        "Visible","off");

    mainGrid = uigridlayout(fH,[4,1],...
        "RowHeight",{'fit','fit','fit','fit'},...
        "RowSpacing",5,...
        "Scrollable","on",...
        "BackgroundColor",[0 0 0]);


    accordion = uiaccordion2(mainGrid);

    accordion2 = uiaccordion2(mainGrid);

    accordion3 = uiaccordion2(mainGrid);

    accordion4 = uiaccordion2(mainGrid);


    % pane 1 items

    accordion.Pane.RowHeight = {25};
    accordion.Pane.ColumnWidth = {'fit','1x'};
    accordion.Pane.RowSpacing = 5;
    accordion.Pane.ColumnSpacing = 5;

    uilabel(accordion.Pane,"Text","Pane Background Color","FontColor",[0 0 0]);
    uibutton(accordion.Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","PaneBackgroundColor",... % accordion property
        "UserData",accordion); % the accordion

    uilabel(accordion.Pane,"Text","Title Background Color","FontColor",[0 0 0]);
    uibutton(accordion.Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","TitleBackgroundColor",... % accordion property
        "UserData",accordion); % the accordion

    uilabel(accordion.Pane,"Text","Border Color","FontColor",[0 0 0]);
    uibutton(accordion.Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","BorderColor",... % accordion property
        "UserData",accordion); % the accordion

    uilabel(accordion.Pane,"Text","Title Font Color","FontColor",[0 0 0]);
    uibutton(accordion.Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","FontColor",... % accordion property
        "UserData",accordion); % the accordion

    % pane 2 items

    uibutton(accordion2.Pane,"Text","uibutton");

    uilabel(accordion2.Pane,"Text","uilabel","FontColor",[0 0 0]);

    % pane 3 items

    accordion3.Pane.Padding = [0 0 0 0];

    % pane 3 items

    uilistbox(accordion3.Pane);
    hAx = uiaxes(accordion4.Pane);

    x = 0:1:180;
    y = cosd(x);

    plot(hAx,x,y);


    accordion.FontSize = 12;

    accordion2.FontSize = 12;

    accordion2.expand();

    accordion.expand();

    movegui(fH,'center')

    fH.Position(1) = fH.Position(1)-400;

    fH.Visible = "on";

    function setAccordionColors(source,~)
        % get user-selected color from color picker
        chosenColor = uisetcolor();
        % make sure it's valid
        if size(chosenColor,2) == 1
            % if invalid, error uialert box
            uialert(fH,"Invalid color","Error");
        else
            % if valid, set the indicated property to the chose color
            source.UserData.(source.Tag) = chosenColor;
        end
    end

end