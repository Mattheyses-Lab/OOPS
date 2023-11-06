function ScatterPlotMatrixSettings = getScatterPlotMatrixSettings(variableList,variableListLong)

ScatterPlotMatrixSettings = struct();
ScatterPlotMatrixSettings.variableList = {};
ScatterPlotMatrixSettings.ColorMode = 'Group';
ScatterPlotMatrixSettings.DiagonalDisplay = 'variable';


%% main window and grid

fH_ScatterPlotMatrixSettings = uifigure("HandleVisibility","on",...
    "Visible","Off",...
    "CloseRequestFcn",@CloseScatterPlotMatrixSettingsFig,...
    "Name","Scatterplot matrix options");

mainGrid = uigridlayout(fH_ScatterPlotMatrixSettings,...
    [3,1],...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'BackgroundColor',[0 0 0],...
    'RowHeight',{'1x','fit',20},...
    'ColumnWidth',{'1x'});

%% variable selection

% uipanel to hold variable selection checkboxes
variablePanel = uipanel(mainGrid,...
    'Title','Variables',...
    'BackgroundColor','Black',...
    'ForegroundColor','White');
variablePanel.Layout.Row = 1;

% add uitree checkbox with selection for each variable
variableTreeGrid = uigridlayout(variablePanel,...
    [1,1],...
    'BackgroundColor','Black',...
    'Padding',[0 0 0 0]);

variableTree = uitree(variableTreeGrid,'checkbox',...
    'BackgroundColor',[0 0 0],...
    'FontColor',[1 1 1]);
for i = 1:numel(variableList)
    VarCheckNodes(i) = uitreenode(variableTree,...
        'Text',variableListLong{i},...
        'NodeData',variableList{i});
end

%% options panel and grid

% options panel
optionsPanel = uipanel(mainGrid,...
    'Title','Options',...
    'BackgroundColor','Black',...
    'ForegroundColor','White');
optionsPanel.Layout.Row = 2;

% options grid inside the panel
optionsGrid = uigridlayout(optionsPanel,...
    [2,2],...
    "ColumnWidth",{'fit','1x'},...
    "RowHeight",20,...
    "RowSpacing",5,...
    "BackgroundColor",[0 0 0]);

%% Scatter plot color mode

ColorModeLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","Color mode",...
    "FontColor",[1 1 1]);
ColorModeLabel.Layout.Row = 1;
ColorModeLabel.Layout.Column = 1;

ColorModeDropdown = uidropdown(...
    "Parent",optionsGrid,...
    "Items",{'Group','Label'},...
    "Value",'Group');
ColorModeDropdown.Layout.Row = 1;
ColorModeDropdown.Layout.Column = 2;

%% Diagonal display

DiagonalDisplayLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","Diagonal display",...
    "FontColor",[1 1 1]);
DiagonalDisplayLabel.Layout.Row = 2;
DiagonalDisplayLabel.Layout.Column = 1;

DiagonalDisplayDropdown = uidropdown(...
    "Parent",optionsGrid,...
    "Items",{'Variable names','Grouped histogram outlines','Grouped histograms'},...
    "ItemsData",{'variable','stairs','grpbars'},...
    "Value",'variable');
DiagonalDisplayDropdown.Layout.Row = 2;
DiagonalDisplayDropdown.Layout.Column = 2;

%% continue button

% button to complete settings selection
ContinueButton_ScatterPlotMatrixSettings = uibutton(mainGrid,...
    'Text','Plot scatterplot matrix',...
    'ButtonPushedFcn',@CloseScatterPlotMatrixSettingsFig);

%% cleanup before starting

% call drawnow and pause briefly
drawnow
pause(0.5)

% set figure height and width
fH_ScatterPlotMatrixSettings.InnerPosition(4) = 600;
fH_ScatterPlotMatrixSettings.InnerPosition(3) = 300;

% move figure window to the center of the display
movegui(fH_ScatterPlotMatrixSettings,'center');

% turn figure visibility on
fH_ScatterPlotMatrixSettings.Visible = "On";

% wait until the figure is closed to continue
waitfor(fH_ScatterPlotMatrixSettings)

%% nested callbacks

    function CloseScatterPlotMatrixSettingsFig(~,~)
        % gather the output
        if isempty(variableTree.CheckedNodes)
            ScatterPlotMatrixSettings.variableList = {};
        else
            [ScatterPlotMatrixSettings.variableList{1,1:numel(variableTree.CheckedNodes)}] = deal(variableTree.CheckedNodes.NodeData);
            ScatterPlotMatrixSettings.ColorMode = ColorModeDropdown.Value;
            ScatterPlotMatrixSettings.DiagonalDisplay = DiagonalDisplayDropdown.Value;
        end
        % if 1 or fewer variables were selected
        if isempty(ScatterPlotMatrixSettings.variableList)
            ScatterPlotMatrixSettings = [];
        elseif size(ScatterPlotMatrixSettings.variableList,2) <= 1
            ScatterPlotMatrixSettings = [];
        end
        % delete the figure
        delete(fH_ScatterPlotMatrixSettings);
    end

end