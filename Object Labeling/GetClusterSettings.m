function ClusterSettings = GetClusterSettings(VarList)

ClusterSettings = struct();
ClusterSettings.VarList = {};
ClusterSettings.nClustersMode = 'Manual';
ClusterSettings.nClusters = 3;
ClusterSettings.Criterion = 'CalinskiHarabasz';

% cluster settings figure window
fH_ClusterSettings = uifigure("HandleVisibility","on",...
    "Visible","Off",...
    "CloseRequestFcn",@CloseClusterSettingsFig);
% cluster settings main grid layout object
MainGrid_ClusterSettings = uigridlayout(fH_ClusterSettings,...
    [3,1],...
    'BackgroundColor','Black',...
    'RowHeight',{'1x','fit',20},...
    'ColumnWidth',{'1x'});
% uipanel to hold variable selection checkboxes
VarPanel_ClusterSettings = uipanel(MainGrid_ClusterSettings,...
    'Title','Variables',...
    'BackgroundColor','Black',...
    'ForegroundColor','White');
VarPanel_ClusterSettings.Layout.Row = 1;
% uipanel to hold nCluster selection
nClustersPanel_ClusterSettings = uipanel(MainGrid_ClusterSettings,...
    'Title','Number of clusters (k)',...
    'BackgroundColor','Black',...
    'ForegroundColor','White');
nClustersPanel_ClusterSettings.Layout.Row = 2;

% components to control nCluster selection
nCLustersGrid = uigridlayout(nClustersPanel_ClusterSettings,...
    [2,2],...
    'BackgroundColor','Black');

nClustersManual = uicheckbox(nCLustersGrid,...
    'Text','Manual',...
    'FontColor','White',...
    'ValueChangedFcn',@UpdatenClustersSelection,...
    'Value',1);
nClustersManual.Layout.Row = 1;
nClustersManual.Layout.Column = 1;

nClustersManualEditfield = uieditfield(nCLustersGrid,...
    'numeric',...
    'ValueDisplayFormat','%.0f clusters',...
    'Value',3);
nClustersManualEditfield.Layout.Row = 1;
nClustersManualEditfield.Layout.Column = 2;

nClustersAuto = uicheckbox(nCLustersGrid,...
    'Text','Auto',...
    'FontColor','White',...
    'ValueChangedFcn',@UpdatenClustersSelection,...
    'Value',0);
nClustersAuto.Layout.Row = 2;
nClustersAuto.Layout.Column = 1;

ClusterCriterionDropdown = uidropdown(nCLustersGrid,...
    "Items",{'CalinskiHarabasz','DaviesBouldin','silhouette'},...
    "Enable","Off");
ClusterCriterionDropdown.Layout.Row = 2;
ClusterCriterionDropdown.Layout.Column = 2;

% button to complete settings selection
ContinueButton_ClusterSettings = uibutton(MainGrid_ClusterSettings,...
    'Text','Run k-means clustering',...
    'ButtonPushedFcn',@CloseClusterSettingsFig);

% add uitree checkbox with selection for each variable
VarTreeGrid = uigridlayout(VarPanel_ClusterSettings,...
    [1,1],...
    'BackgroundColor','Black',...
    'Padding',[0 0 0 0]);

VarTree = uitree(VarTreeGrid,'checkbox');
for i = 1:numel(VarList)
    VarCheckNodes(i) = uitreenode(VarTree,...
        'Text',ExpandVariableName(VarList{i}),...
        'NodeData',VarList{i});
end

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

    function UpdatenClustersSelection(source,event)
        switch source.Text
            case 'Manual'
                nClustersAuto.Value = ~(nClustersAuto.Value);
                switch source.Value
                    case 1
                        ClusterSettings.nClustersMode = 'Manual';
                        ClusterCriterionDropdown.Enable = 'Off';
                        nClustersManualEditfield.Enable = 'On';
                    case 0
                        ClusterSettings.nClustersMode = 'Auto';
                        ClusterCriterionDropdown.Enable = 'On';
                        nClustersManualEditfield.Enable = 'Off';
                end
            case 'Auto'
                nClustersManual.Value = ~(nClustersManual.Value);
                switch source.Value
                    case 1
                        ClusterSettings.nClustersMode = 'Auto';
                        nClustersManualEditfield.Enable = 'Off';
                        ClusterCriterionDropdown.Enable = 'On';
                    case 0
                        ClusterSettings.nClustersMode = 'Manual';
                        nClustersManualEditfield.Enable = 'On';
                        ClusterCriterionDropdown.Enable = 'Off';
                end
        end
    end

    function CloseClusterSettingsFig(source,event)
        % gather the output
        if isempty(VarTree.CheckedNodes)
            ClusterSettings.VarList = {};
        else
            [ClusterSettings.VarList{1,1:numel(VarTree.CheckedNodes)}] = deal(VarTree.CheckedNodes.NodeData);
            ClusterSettings.nClusters = nClustersManualEditfield.Value;
            ClusterSettings.Criterion = ClusterCriterionDropdown.Value;
        end
        % if no variables were selected
        if isempty(ClusterSettings.VarList)
            ClusterSettings = [];
        end
        % delete the figure
        delete(fH_ClusterSettings);
    end



end