function NewProject2(source,~)
        
        % get the GUI data structure
        PODSData = guidata(source);
        % get the project name and number groups
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
        % check for valid project name and n groups
        if isnan(nGroups)||isempty(projectTitle)
            error('Invalid input')
        end

        % set the project name
        PODSData.ProjectName = projectTitle;


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
        % check for valid group names
        if any(isempty(Outputs))
            error('Invalid input')
        end
        % create new groups for each of the user-defined group names
        for i = 1:nGroups
            PODSData.AddNewGroup(Outputs{i,1});
        end
        % update
        PODSData.CurrentGroupIndex = 1;
        UpdateLog3(source,['Started new project, "', PODSData.ProjectName,'", with ',num2str(PODSData.nGroups),' groups'],'append')
        UpdateSummaryDisplay(source,{'Project','Group'});
        UpdateGroupTree(source);
        UpdateImageTree(source);
    
    end