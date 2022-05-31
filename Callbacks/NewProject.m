    function [] = NewProject(source,event)
        
        PODSData = guidata(source);
        
        nGroups = 1;
        %nChannels = 1;
        
        % get screensize to set gui position
        ss = PODSData.Settings.ScreenSize;
        % center point (x,y) of screen
        center = [ss(3)/2,ss(4)/2];

        % position of the first window
        sz = [center(1)-250 center(2)-80 500 160];

        % draw figure window
        newproject = uifigure('Name','New Project',...
                              'Menubar','none',...
                              'Position',sz);

        % editbox to set project name                  
        ProjectNameBox = uieditfield('Parent',newproject,...
                                     'Position',[200 110 250 20],...
                                     'Value',PODSData.ProjectName);
        ProjectNameBoxTitle = uilabel('Parent',newproject,...
                                      'Position',[50 110 100 20],...
                                      'Text','Project Name');                        

        % editfield to set n groups                          
        NumGroupsBox = uieditfield('Parent',newproject,...
                                   'Position',[200 70 250 20],...
                                   'Value','1');
        NumGroupsBoxTitle = uilabel('Parent',newproject,...
                                    'Position',[50 70 100 20],...
                                    'Text','Number of Groups');                                
                                
        % pushbutton - deletes the current window and moves to setting group names                        
        pbCont2NameGroups = uibutton(newproject,...
                                    'Push',...
                                    'Text','Continue',...
                                    'Position',[200 30 100 20],...
                                    'ButtonPushedFcn',@Cont2NameGroups);
                                
        drawnow
        
        % wait until figure is deleted                       
        waitfor(newproject)                                
         
        % height of next window will be based on user-selected number of groups (same width)
        fig_height = 50+40*(nGroups-1)+40+30; % 30=bottom margin,50=top margin plus title bar,40=space between rows,
        sz = [center(1)-250 center(2)-fig_height/2 500 fig_height];
        
        % draw figure window for user to set group names
        fHSetGroupNames = uifigure('Name','Set Group Names',...
                                   'Menubar','none',...
                                   'Position',sz);        

        for i = 1:nGroups
            GroupNamesBox(i) = uieditfield(fHSetGroupNames,...
                'Position',[200 fig_height-50-40*(i-1) 250 20],...
                'Value',['Untitled Group ' num2str(i)],...
                'Tag',num2str(i));
            GroupNamesBoxTitle(i) = uilabel(fHSetGroupNames,...
                'Position',[50 fig_height-50-40*(i-1) 100 20],...
                'Text',['Group ',num2str(i),' Name:']);
        end        

        pbReturnToPODS = uibutton(fHSetGroupNames,...
                                  'Push',...
                                  'Text','Return to PODS',...
                                  'Position',[200 30 100 20],...
                                  'ButtonPushedFcn',@ReturnToPODS);
                              
        waitfor(fHSetGroupNames)                      

        % update main GUI with data
        PODSData.Handles.GroupListBox.Items = PODSData.GroupNames;
        PODSData.Handles.GroupListBox.ItemsData = [1:PODSData.nGroups];
        %PODSData.GroupNames = GroupNames;
        PODSData.CurrentGroupIndex = 1;
        guidata(source,PODSData);
        UpdateLog3(source,['Started new project, "', PODSData.ProjectName,'", with ',num2str(PODSData.nGroups),' groups'],'append')
        UpdateTables(source);
        UpdateListBoxes(source);
        
%% Nested callbacks for NewProject

        function [] = Cont2NameGroups(source,event)
            PODSData.ProjectName = ProjectNameBox.Value;
            nGroups = str2num(NumGroupsBox.Value);
            %nChannels = str2num(NumChannelsBox.Value);
            delete(newproject)
        end

        %% Set names and return to Main Window
        function [] = ReturnToPODS(source,event)
            for I = 1:nGroups
                %PODSData.Group(I,J) = PODSGroup(GroupNamesBox(I).Value,ChannelNamesBox(J).Value,J,PODSData.Settings,I);
                PODSData.MakeNewGroup(GroupNamesBox(I).Value,I);
            end
            delete(fHSetGroupNames)
        end   
    
    
    
    

    end