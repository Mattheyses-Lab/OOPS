function uiaccordion_demo()

    fH = uifigure(...
        "WindowStyle","alwaysontop",...
        "Name","uiaccordion demo",...
        "HandleVisibility","on");

    accordionGrid = uigridlayout(fH,[1,1]);


    % works
    accordion = uiaccordion(accordionGrid);

    % add 4 accordion items
    accordion.addItem();
    accordion.addItem();
    accordion.addItem();
    accordion.addItem();


    % pane 1 items

    accordion.Items(1).Pane.RowHeight = {25};
    accordion.Items(1).Pane.ColumnWidth = {'fit','1x'};
    accordion.Items(1).Pane.RowSpacing = 5;
    accordion.Items(1).Pane.ColumnSpacing = 5;

    uilabel(accordion.Items(1).Pane,"Text","Pane Background Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","PaneBackgroundColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion

    uilabel(accordion.Items(1).Pane,"Text","Title Background Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","TitleBackgroundColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion

    uilabel(accordion.Items(1).Pane,"Text","Border Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","BorderColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion

    uilabel(accordion.Items(1).Pane,"Text","Title Font Color","FontColor",[0 0 0]);
    uibutton(accordion.Items(1).Pane,...
        "Text","Choose",...
        "ButtonPushedFcn",@setAccordionColors,...
        "Tag","FontColor",... % accordion property
        "UserData",accordion.Items(1)); % the accordion

    % pane 2 items

    uibutton(accordion.Items(2).Pane,"Text","uibutton");

    uilabel(accordion.Items(2).Pane,"Text","uilabel","FontColor",[0 0 0]);

    % pane 3 items

    accordion.Items(3).Pane.Padding = [0 0 0 0];

    % pane 3 items

    uilistbox(accordion.Items(3).Pane);

    % pane 4 items


    hAx = uiaxes(accordion.Items(4).Pane);

    x = 0:1:180;
    y = cosd(x);

    plot(hAx,x,y);


    accordion.Items(1).FontSize = 12;

    accordion.Items(2).FontSize = 12;

    accordion.Items(2).expand();

    accordion.Items(1).expand();

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