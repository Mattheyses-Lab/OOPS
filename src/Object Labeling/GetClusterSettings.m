function ClusterSettings = GetClusterSettings(variableList)

ClusterSettings = struct();
ClusterSettings.variableList = {};
ClusterSettings.nClustersMode = 'Manual';
ClusterSettings.nClusters = 3;
ClusterSettings.Criterion = 'CalinskiHarabasz';
ClusterSettings.DistanceMetric = 'sqeuclidean';
ClusterSettings.NormalizationMethod = 'zscore';

%% main window and grid

fH_ClusterSettings = uifigure("HandleVisibility","on",...
    "Visible","Off",...
    "CloseRequestFcn",@CloseClusterSettingsFig,...
    "Name",'k-means clustering options');

MainGrid_ClusterSettings = uigridlayout(fH_ClusterSettings,...
    [3,1],...
    'BackgroundColor','Black',...
    'RowHeight',{'1x','fit',20},...
    'ColumnWidth',{'1x'});

%% variable selection

% uipanel to hold variable selection checkboxes
variablePanel = uipanel(MainGrid_ClusterSettings,...
    'Title','Variables',...
    'BackgroundColor','Black',...
    'ForegroundColor','White');
variablePanel.Layout.Row = 1;

% add uitree checkbox with selection for each variable
variableTreeGrid = uigridlayout(variablePanel,...
    [1,1],...
    'BackgroundColor','Black',...
    'Padding',[0 0 0 0]);

variableTree = uitree(variableTreeGrid,'checkbox');
for i = 1:numel(variableList)
    VarCheckNodes(i) = uitreenode(variableTree,...
        'Text',ExpandVariableName(variableList{i}),...
        'NodeData',variableList{i});
end

%% options panel and grid

% options panel
optionsPanel = uipanel(MainGrid_ClusterSettings,...
    'Title','Options',...
    'BackgroundColor','Black',...
    'ForegroundColor','White');
optionsPanel.Layout.Row = 2;

% options grid inside the panel
optionsGrid = uigridlayout(optionsPanel,...
    [6,2],...
    "ColumnWidth",{'1x','fit'},...
    "RowHeight",20,...
    "RowSpacing",5,...
    "BackgroundColor",[0 0 0]);

%% Mode for determining k

nClustersModeLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","k selection mode",...
    "FontColor",[1 1 1]);
nClustersModeLabel.Layout.Row = 1;
nClustersModeLabel.Layout.Column = 1;

nClustersModeDropdown = uidropdown(...
    "Parent",optionsGrid,...
    "Items",{'Auto','Manual'},...
    "Value",'Manual',...
    "ValueChangedFcn",@nClustersModeChanged);
nClustersModeDropdown.Layout.Row = 1;
nClustersModeDropdown.Layout.Column = 2;

%% k (manual)

nClustersLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","k",...
    "FontColor",[1 1 1]);
nClustersLabel.Layout.Row = 2;
nClustersLabel.Layout.Column = 1;

nClustersEditfield = uieditfield(optionsGrid,...
    "numeric",...
    "Value",3,...
    "Limits",[1 15]);
nClustersEditfield.Layout.Row = 2;
nClustersEditfield.Layout.Column = 2;

%% Cluster criterion for auto k

ClusterCriterionLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","Criterion",...
    "FontColor",[1 1 1]);
ClusterCriterionLabel.Layout.Row = 3;
ClusterCriterionLabel.Layout.Column = 1;

ClusterCriterionDropdown = uidropdown(...
    "Parent",optionsGrid,...
    "Items",{'CalinskiHarabasz','DaviesBouldin','silhouette'},...
    "Enable","Off");
ClusterCriterionDropdown.Layout.Row = 3;
ClusterCriterionDropdown.Layout.Column = 2;

%% Distance metric

DistanceMetricLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","Distance metric",...
    "FontColor",[1 1 1]);
DistanceMetricLabel.Layout.Row = 4;
DistanceMetricLabel.Layout.Column = 1;

DistanceMetricDropdown = uidropdown(...
    "Parent",optionsGrid,...
    "Items",{'sqeuclidean','cosine','cityblock'},...
    "Value",'sqeuclidean');
DistanceMetricDropdown.Layout.Row = 4;
DistanceMetricDropdown.Layout.Column = 2;

%% Normalization method

NormalizationMethodLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","Normalization method",...
    "FontColor",[1 1 1]);
NormalizationMethodLabel.Layout.Row = 5;
NormalizationMethodLabel.Layout.Column = 1;

NormalizationMethodDropdown = uidropdown(...
    "Parent",optionsGrid,...
    "Items",{'z-score','none'},...
    "ItemsData",{'zscore','none'},...
    "Value",'zscore');
NormalizationMethodDropdown.Layout.Row = 5;
NormalizationMethodDropdown.Layout.Column = 2;

%% Display evalutation results

DisplayEvaluationLabel = uilabel(...
    "Parent",optionsGrid,...
    "Text","Display evalutation",...
    "FontColor",[1 1 1]);
DisplayEvaluationLabel.Layout.Row = 6;
DisplayEvaluationLabel.Layout.Column = 1;

DisplayEvaluationDropdown = uidropdown(...
    "Parent",optionsGrid,...
    "Items",{'yes','no'},...
    "ItemsData",{true,false},...
    "Value",false);
DisplayEvaluationDropdown.Layout.Row = 6;
DisplayEvaluationDropdown.Layout.Column = 2;

%% continue button

% button to complete settings selection
ContinueButton_ClusterSettings = uibutton(MainGrid_ClusterSettings,...
    'Text','Run k-means clustering',...
    'ButtonPushedFcn',@CloseClusterSettingsFig);

% call drawnow and pause briefly
drawnow
pause(0.5)

% set figure height and width
fH_ClusterSettings.InnerPosition(4) = 600;
fH_ClusterSettings.InnerPosition(3) = 300;

% move figure window to the center of the display
movegui(fH_ClusterSettings,'center');

% turn figure visibility on
fH_ClusterSettings.Visible = "On";

waitfor(fH_ClusterSettings)

    function nClustersModeChanged(source,~)
        switch source.Value
            case 'Auto'
                ClusterCriterionDropdown.Enable = 'on';
                nClustersEditfield.Enable = 'off';
            case 'Manual'
                ClusterCriterionDropdown.Enable = 'off';
                nClustersEditfield.Enable = 'on';
        end
    end

    function CloseClusterSettingsFig(~,~)
        % gather the output
        if isempty(variableTree.CheckedNodes)
            ClusterSettings.variableList = {};
        else
            [ClusterSettings.variableList{1,1:numel(variableTree.CheckedNodes)}] = deal(variableTree.CheckedNodes.NodeData);
            ClusterSettings.nClusters = nClustersEditfield.Value;
            ClusterSettings.Criterion = ClusterCriterionDropdown.Value;
            ClusterSettings.DistanceMetric = DistanceMetricDropdown.Value;
            ClusterSettings.nClustersMode = nClustersModeDropdown.Value;
            ClusterSettings.NormalizationMethod = NormalizationMethodDropdown.Value;
            ClusterSettings.DisplayEvaluation = DisplayEvaluationDropdown.Value;
        end
        % if no variables were selected
        if isempty(ClusterSettings.variableList)
            ClusterSettings = [];
        end
        % delete the figure
        delete(fH_ClusterSettings);
    end

end