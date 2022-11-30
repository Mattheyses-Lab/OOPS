function ClusterSettings = GetClusterSettings(VarList)

ClusterSettings = struct();
ClusterSettings.VarList = VarList;
ClusterSettings.nClustersMode = 'Manual';
ClusterSettings.nClusters = 3;
ClusterSettings.Criterion = 'CalinskiHarabasz';

nClustersMode = 'Manual';

% cluster settings figure window
fH_ClusterSettings = uifigure("HandleVisibility","on","Visible","Off");
% cluster settings main grid layout object
MainGrid_ClusterSettings = uigridlayout(fH_ClusterSettings,[3,1],'BackgroundColor','Black');
MainGrid_ClusterSettings.RowHeight = {'fit','fit',20};
MainGrid_ClusterSettings.ColumnWidth = {'fit'};
% uipanel to hold variable selection checkboxes
VarPanel_ClusterSettings = uipanel(MainGrid_ClusterSettings,'Title','Variables','BackgroundColor','Black','ForegroundColor','White');
VarPanel_ClusterSettings.Layout.Row = 1;
% uipanel to hold nCluster selection
nClustersPanel_ClusterSettings = uipanel(MainGrid_ClusterSettings,'Title','Number of clusters (k)','BackgroundColor','Black','ForegroundColor','White');
nClustersPanel_ClusterSettings.Layout.Row = 2;
% components to control nCluster selection
nCLustersGrid = uigridlayout(nClustersPanel_ClusterSettings,[2,2],'BackgroundColor','Black');
nClustersManual = uicheckbox(nCLustersGrid,...
    'Text','Manual',...
    'FontColor','White',...
    'ValueChangedFcn',@UpdatenClustersSelection,...
    'Value',1);
nClustersManual.Layout.Row = 1;
nClustersManual.Layout.Column = 1;
nClustersManualEditfield = uieditfield(nCLustersGrid,...
    'numeric','ValueDisplayFormat',...
    '%.0f clusters',...
    'Value',3);
nClustersManualEditfield.Layout.Row = 1;
nClustersManualEditfield.Layout.Column = 2;
nClustersAuto = uicheckbox(nCLustersGrid,...
    'Text','Auto',...
    'FontColor','White',...
    'ValueChangedFcn',@UpdatenClustersSelection,...
    'Value',0);
nCLustersAuto.Layout.Row = 2;
nCLustersAuto.Layout.Column = 1;
ClusterCriterionDropdown = uidropdown(nCLustersGrid,...
    "Items",{'CalinskiHarabasz','DaviesBouldin','silhouette'},...
    "Enable","Off");
ClusterCriterionDropdown.Layout.Row = 2;
ClusterCriterionDropdown.Layout.Column = 2;

% button to complete settings selection
ContinueButton_ClusterSettings = uibutton(MainGrid_ClusterSettings,...
    'Text','Run k-means clustering',...
    'ButtonPushedFcn',@CloseClusterSettingsFig);

% add checkbox for each variable
nVars = numel(VarList);
VarGrid = uigridlayout(VarPanel_ClusterSettings,[nVars,1],'BackgroundColor','Black');
for i = 1:nVars
    VarCheckBoxes(i) = uicheckbox(VarGrid,'Text',ExpandVariableName(VarList{i}),'FontColor','White');
end

% call drawnow and pause for rendering
drawnow
pause(0.5)

% determine appropriate size for figure
temp = VarPanel_ClusterSettings.Position(4)+nClustersPanel_ClusterSettings.Position(4)+20+40
temp2 = VarPanel_ClusterSettings.Position(3)+20;
fH_ClusterSettings.InnerPosition(4) = temp;
fH_ClusterSettings.InnerPosition(3) = temp2;

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
        VarSelectionArray = [VarCheckBoxes(:).Value];
        ClusterSettings.VarList = VarList(VarSelectionArray);
        ClusterSettings.nClusters = nClustersManualEditfield.Value;
        ClusterSettings.Criterion = ClusterCriterionDropdown.Value;
        close(fH_ClusterSettings);
    end

end