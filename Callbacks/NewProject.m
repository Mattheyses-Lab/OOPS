    function [] = NewProject(source,event)
        
        PODSData = guidata(source);
        % get screensize to set gui position
        ss = PODSData.Settings.ScreenSize;
        % center point (x,y) of screen
        center = [ss(3)/2,ss(4)/2];
        % get number of current groups
        nGroups = PODSData.nGroups;
        % get current group names
        GroupNames = {};
        [GroupNames{1:nGroups,1}] = deal(PODSData.Group.GroupName);
        

        sz = [center(1)-250 center(2)-250 500 500];

        newproject = uifigure('Name','New Project',...
                              'Menubar','none',...
                              'Position',sz);

        ProjectNameBox = uieditfield('Parent',newproject,...
                                     'Position',[200 450 250 20],...
                                     'Value',PODSData.ProjectName,...
                                     'ValueChangedFcn',@SetProjectName);
        ProjectNameBoxTitle = uilabel('Parent',newproject,...
                                      'Position',[50 450 100 20],...
                                      'Text','Project Name');                        
                                                     
        NumGroupsBox = uieditfield('Parent',newproject,...
                                   'Position',[200 410 250 20],...
                                   'Value',num2str(nGroups),...
                                   'ValueChangedFcn',@SetNumGroups);                        
        NumGroupsBoxTitle = uilabel('Parent',newproject,...
                                    'Position',[50 410 100 20],...
                                    'Text','Number of Groups');
                        
        pbReturnToPODS = uibutton(newproject,...
                                  'Push',...
                                  'Text','Return to PODS',...
                                  'Position',[200 30 100 20],...
                                  'ButtonPushedFcn',@ReturnToPODS);
                            
        hGroupNamesPanel = uipanel('Parent',newproject,...
                                   'Position',[25 80 450 300],...
                                   'Scrollable','on');
                              
        
        GroupNamesBox(1) = uieditfield('Parent',hGroupNamesPanel,...
                                       'Position',[175 300-40*1 250 20],...
                                       'Value',GroupNames{1},...
                                       'ValueChangedFcn',@SetGroupNames,...
                                       'Tag',num2str(1));
        GroupNamesBoxTitle(1) = uilabel('Parent',hGroupNamesPanel,...
                                        'Position',[25 300-40*1 100 20],...
                                        'Text',['Group ',num2str(1),' Name:']);

        
        
        % wait until figure is deleted                       
        waitfor(newproject)
        % update main GUI with data
        PODSData.Handles.GroupListBox.Items = GroupNames;
        PODSData.Handles.GroupListBox.ItemsData = [1:PODSData.nGroups];
        PODSData.GroupNames = GroupNames;
        PODSData.CurrentGroupIndex = 1;
        guidata(source,PODSData);
        UpdateLog3(source,['Started new project, "', PODSData.ProjectName,'", with ',num2str(PODSData.nGroups),' groups'],'append')
        UpdateTables(source);
        
        
%% Nested callbacks for NewProject
        %% Set Project Name
        function [] = SetProjectName(source,event)
            new_project_name = source.Value;
            PODSData.ProjectName = new_project_name;
        end
        %% Set Number of Groups                       
        function [] = SetNumGroups(source,event)
            OldNumGroups = PODSData.nGroups;
            NewNumGroups = str2num(source.Value);
            %PODSData.nGroups = NewNumGroups;

            delete(GroupNamesBox(:))
            delete(GroupNamesBoxTitle(:))
            
            GroupNames = {};
            [GroupNames{1:OldNumGroups,1}] = deal(PODSData.Group.GroupName);            
            
            for i = 1:NewNumGroups
                GroupNames{i,1} = ['Untitled Group ',num2str(i)];
            end
            
            for i = 1:NewNumGroups
                PODSData.Group(i) = PODSGroup();
        
                GroupNamesBox(i) = uieditfield('Parent',hGroupNamesPanel,...
                    'Position',[175 300-40*i 250 20],...
                    'Value',GroupNames{i},...
                    'ValueChangedFcn',@SetGroupNames,...
                    'Tag',num2str(i));
                GroupNamesBoxTitle(i) = uilabel('Parent',hGroupNamesPanel,...
                    'Position',[25 300-40*i 100 20],...
                    'Text',['Group ',num2str(i),' Name:']);
            end
        end                                                   
        %% Set Group Names
        function [] = SetGroupNames(source,event)
            GroupIndex = str2num(source.Tag);
            NewGroupName = source.Value;
            GroupNames{GroupIndex} = NewGroupName;
            PODSData.Group(GroupIndex).GroupName = NewGroupName;
        end
        %% Return to Main Window
        function [] = ReturnToPODS(source,event)
            delete(newproject)
        end

    end