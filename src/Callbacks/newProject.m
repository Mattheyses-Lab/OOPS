function newProject(source,~)
        
    % get the GUI data structure
    OOPSData = guidata(source);

    % get the project name and number of groups
    Outputs = SimpleFormFig('New project',...
        {'Project title',...
        'Number of groups'},...
        [1 1 1],...
        [0 0 0]);

    % if user selected 'cancel'
    if ~iscell(Outputs)
        return
    end

    % store them
    projectTitle = Outputs{1};
    nGroups = str2double(Outputs{2});

    try
        % check for valid project name
        if isempty(projectTitle)
            error('Invalid title')
        end
        % check for valid number of groups
        if isnan(nGroups)
            error('Invalid number of groups')
        end
    catch ME
        msg = ME.message;
        uialert(OOPSData.Handles.fH,msg,'Error');
        return
    end

    % if groups already exist, delete them
    if OOPSData.nGroups > 0
        OOPSData.deleteGroups();
    end

    % set the project name
    OOPSData.ProjectName = projectTitle;

    % make group name labels for the dialog box
    groupNamesLabels = cell(nGroups,1);
    for i = 1:nGroups
        groupNamesLabels{i,1} = ['Group ',num2str(i),' name'];
    end
    % get the group names
    Outputs = SimpleFormFig(['Enter group names for ',projectTitle],...
        groupNamesLabels,...
        [1 1 1],...
        [0 0 0]);
    
    % if user selected cancel
    if ~iscell(Outputs)
        return
    end

    try
        % check for valid group names
        if any(cellfun(@(groupName) isempty(groupName),Outputs))
            error('Invalid group names')
        end
    catch ME
        msg = ME.message;
        uialert(OOPSData.Handles.fH,msg,'Error');
        return
    end

    % create new groups for each of the user-defined group names
    for i = 1:nGroups
        OOPSData.AddNewGroup(Outputs{i,1});
    end

    % update
    OOPSData.GUIProjectStarted = true;
    OOPSData.CurrentGroupIndex = 1;
    UpdateLog3(source,['Started new project, "', OOPSData.ProjectName,'", with ',num2str(OOPSData.nGroups),' groups'],'append')
    UpdateSummaryDisplay(source,{'Project','Group'});
    UpdateGroupTree(source);
    UpdateImageTree(source);
    UpdateMenubar(source);

end