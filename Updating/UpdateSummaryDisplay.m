function [] = UpdateSummaryDisplay(source,varargin)

    PODSData = guidata(source);

    dataOnly = false;

    % check if we really need to update to prevent unnecessary overhead
    % varargin{1} = {'Project','Image',...}
    if ~isempty(varargin)
        if any(ismember('DataOnly',varargin{1}))
            dataOnly = true;
        end
        % if no choices match currently selected display type, don't update
        if ~any(ismember(varargin{1},PODSData.Settings.SummaryDisplayType))
            return
        end
    end

    % set the title of the summary panel
    PODSData.Handles.AppInfoPanel.Title = [PODSData.Settings.SummaryDisplayType,' summary'];
    % hide grid layout managers for all summary tables
    set(findobj(PODSData.Handles.AppInfoPanel.Children(),'type','uigridlayout'),'Visible','off');
    % show the grid layout manager for the summary type that is active
    PODSData.Handles.([PODSData.Settings.SummaryDisplayType,'SummaryTableGrid']).Visible = 'on';

    switch PODSData.Settings.SummaryDisplayType

        case 'Project'

            projectTable = PODSData.ProjectSummaryDisplayTable;
            PODSData.Handles.ProjectSummaryTable.Data = projectTable;
            PODSData.Handles.ProjectSummaryTable.ColumnName = {};
            PODSData.Handles.ProjectSummaryTable.RowName = {};

            % testing adding styles to cells

            % first remove all styles
            removeStyle(PODSData.Handles.ProjectSummaryTable);

            % color cell based on selected GUI background color
            % get row and col coordinates to the cell corresponding to 'GUI background color'
            [r,c] = find(ismember(projectTable.Variables,'GUI background color'));
            % create an icon color style for the cell
            s = uistyle('Icon',makeRGBColorSquare(PODSData.Settings.GUIBackgroundColor,1));
            % add the style to the table
            addStyle(PODSData.Handles.ProjectSummaryTable,s,'cell',[r,c+1]);

            % color cell based on selected GUI foreground color
            % get row and col coordinates to the cell corresponding to 'GUI background color'
            [r,c] = find(ismember(projectTable.Variables,'GUI foreground color'));
            % create an icon color style for the cell
            s = uistyle('Icon',makeRGBColorSquare(PODSData.Settings.GUIForegroundColor,1));
            % add the style to the table
            addStyle(PODSData.Handles.ProjectSummaryTable,s,'cell',[r,c+1]);

            % color cell based on selected GUI foreground color
            % get row and col coordinates to the cell corresponding to 'GUI background color'
            [r,c] = find(ismember(projectTable.Variables,'GUI highlight color'));
            % create an icon color style for the cell
            s = uistyle('Icon',makeRGBColorSquare(PODSData.Settings.GUIHighlightColor,1));
            % add the style to the table
            addStyle(PODSData.Handles.ProjectSummaryTable,s,'cell',[r,c+1]);

            % end testing


        case 'Group'

            cGroup = PODSData.CurrentGroup;

            if ~isempty(cGroup)
                % groupTable = cGroup.GroupSummaryDisplayTable;
                % PODSData.Handles.GroupSummaryTable.Data = groupTable;
                % PODSData.Handles.GroupSummaryTable.ColumnName = {};
                % PODSData.Handles.GroupSummaryTable.RowName = {};
                % 
                % % first remove all styles
                % removeStyle(PODSData.Handles.GroupSummaryTable);
                % 
                % % create styles for cells with missing (NaN) values
                % sMissing = uistyle("BackgroundColor",[1 0 0],"FontColor",[1 1 1]);
                % % find indices to the missing values
                % [rMissing,cMissing] = find(ismember(groupTable.Variables,'NaN'));
                % % add the style to missing cells
                % addStyle(PODSData.Handles.GroupSummaryTable,sMissing,'cell',[rMissing,cMissing]);
                % 
                % % create separate styles for cells that are 'True' or 'False'
                % sPass = uistyle("Icon","success","IconAlignment","rightmargin");
                % sFail = uistyle("Icon","error","IconAlignment","rightmargin");
                % % find the cells that are 'True' or 'False'
                % [rFalse,cFalse] = find(ismember(groupTable.Variables,'False'));
                % [rTrue,cTrue] = find(ismember(groupTable.Variables,'True'));
                % % add the styles to corresponding cells
                % addStyle(PODSData.Handles.GroupSummaryTable,sFail,'cell',[rFalse,cFalse]);
                % addStyle(PODSData.Handles.GroupSummaryTable,sPass,'cell',[rTrue,cTrue]);


                % get the data for the group table
                groupTable = cGroup.GroupSummaryDisplayTable;

                % create an alignment style to make sure all text is left aligned
                sAlignment = uistyle("HorizontalAlignment","left");

                % create styles for cells with missing (NaN) values
                sMissing = uistyle("BackgroundColor",[1 0 0],"FontColor",[1 1 1]);
                % find indices to the missing values
                [rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), groupTable.Group));
                % [rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), imageTable.Image));
                cMissing = cMissing + 1;

                % create styles for cells that are 'True' or 'False'
                sPass = uistyle("Icon","success","IconAlignment","rightmargin");
                sFail = uistyle("Icon","error","IconAlignment","rightmargin");
                % find the cells that are 'True' or 'False'
                [rFalse,cFalse] = find(cellfun(@isLogicalFalse,groupTable.Group));
                cFalse = cFalse + 1;
                [rTrue,cTrue] = find(cellfun(@isLogicalTrue,groupTable.Group));
                cTrue = cTrue + 1;

                % now adjust the table for display
                [groupTable.Group(rTrue)] = {'True'};
                [groupTable.Group(rFalse)] = {'False'};

                % add the table data to the uitable
                PODSData.Handles.GroupSummaryTable.Data = groupTable;
                % remove column and row names
                PODSData.Handles.GroupSummaryTable.ColumnName = {};
                PODSData.Handles.GroupSummaryTable.RowName = {};

                % first remove all styles
                removeStyle(PODSData.Handles.GroupSummaryTable);
                % make sure all text is aligned left
                addStyle(PODSData.Handles.GroupSummaryTable,sAlignment,'column',2);
                % add the styles to true or false cells
                addStyle(PODSData.Handles.GroupSummaryTable,sFail,'cell',[rFalse,cFalse]);
                addStyle(PODSData.Handles.GroupSummaryTable,sPass,'cell',[rTrue,cTrue]);
                % add the style to missing cells
                addStyle(PODSData.Handles.GroupSummaryTable,sMissing,'cell',[rMissing,cMissing]);

            else
                PODSData.Handles.AppInfoPanel.Title = 'No group found';
                PODSData.Handles.GroupSummaryTable.Data = [];
                PODSData.Handles.GroupSummaryTableGrid.Visible = 'off';
                return
            end

        case 'Image'

            cImage = PODSData.CurrentImage;

            if ~isempty(cImage)
                % imageTable = cImage(1).ImageSummaryDisplayTable;
                % PODSData.Handles.ImageSummaryTable.Data = imageTable;
                % PODSData.Handles.ImageSummaryTable.ColumnName = {};
                % PODSData.Handles.ImageSummaryTable.RowName = {};


                % testing below - when table data is not a cell array of cell arrays

                imageTable = cImage(1).ImageSummaryDisplayTable;

                % add the table data to the uitable
                PODSData.Handles.ImageSummaryTable.Data = imageTable;
                % remove column and row names
                PODSData.Handles.ImageSummaryTable.ColumnName = {};
                PODSData.Handles.ImageSummaryTable.RowName = {};

                if dataOnly
                    return
                end


                % if dataOnly
                %     % add the table data to the uitable
                %     PODSData.Handles.ImageSummaryTable.Data = imageTable;
                %     % remove column and row names
                %     PODSData.Handles.ImageSummaryTable.ColumnName = {};
                %     PODSData.Handles.ImageSummaryTable.RowName = {};
                %     return
                % end

                % create an alignment style to ensure all text is left-aligned
                sAlignment = uistyle("HorizontalAlignment","left");
                % create styles for cells with missing (NaN) values
                sMissing = uistyle("BackgroundColor",[1 0 0],"FontColor",[1 1 1]);
                % create separate styles for cells that are 'True' or 'False'
                sPass = uistyle("Icon","success","IconAlignment","rightmargin");
                sFail = uistyle("Icon","error","IconAlignment","rightmargin");

                % find indices to the missing values
                [rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), imageTable.Image));
                cMissing = cMissing + 1;

                % find the cells with char vectors ['True'] or ['False']
                [rFalse,cFalse] = find(cellfun(@(x) strcmp(x,'False'), imageTable.Image));
                cFalse = cFalse + 1;
                [rTrue,cTrue] = find(cellfun(@(x) strcmp(x,'True'), imageTable.Image));
                cTrue = cTrue + 1;


                % % add the table data to the uitable
                % PODSData.Handles.ImageSummaryTable.Data = imageTable;
                % % remove column and row names
                % PODSData.Handles.ImageSummaryTable.ColumnName = {};
                % PODSData.Handles.ImageSummaryTable.RowName = {};

                % first remove all styles
                removeStyle(PODSData.Handles.ImageSummaryTable);
                % make sure all text is aligned left
                addStyle(PODSData.Handles.ImageSummaryTable,sAlignment,'column',2);
                % add the styles to true or false cells
                addStyle(PODSData.Handles.ImageSummaryTable,sFail,'cell',[rFalse,cFalse]);
                addStyle(PODSData.Handles.ImageSummaryTable,sPass,'cell',[rTrue,cTrue]);
                % add the style to missing cells
                addStyle(PODSData.Handles.ImageSummaryTable,sMissing,'cell',[rMissing,cMissing]);

            else
                PODSData.Handles.AppInfoPanel.Title = 'No image found';
                PODSData.Handles.ImageSummaryTable.Data = [];
                PODSData.Handles.ImageSummaryTableGrid.Visible = 'off';
                return
            end  

        case 'Object'

            cObject = PODSData.CurrentObject;

            if ~isempty(cObject)
                % objectTable = cObject.ObjectSummaryDisplayTable;
                % PODSData.Handles.ObjectSummaryTable.Data = objectTable;
                % PODSData.Handles.ObjectSummaryTable.ColumnName = {};
                % PODSData.Handles.ObjectSummaryTable.RowName = {};

                objectTable = cObject.ObjectSummaryDisplayTable;

                % create an alignment style to make sure all text is left aligned
                sAlignment = uistyle("HorizontalAlignment","left");

                % create styles for cells with missing (NaN) values
                sMissing = uistyle("BackgroundColor",[1 0 0],"FontColor",[1 1 1]);
                % find indices to the missing values
                [rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), objectTable.Object));
                cMissing = cMissing + 1;

                % get row and col coordinates to the cell corresponding to 'GUI background color'
                %[rLabel,cLabel] = find(ismember(objectTable.Variables,'Label'));
                [rLabel,cLabel] = find(cellfun(@(x) strcmp(x,'Label'), objectTable.Variables));
                % create an icon color style for the cell
                sLabel = uistyle('Icon',cObject.LabelColorSquare);

                % add the table data to the uitable
                PODSData.Handles.ObjectSummaryTable.Data = objectTable;
                % remove column and row names
                PODSData.Handles.ObjectSummaryTable.ColumnName = {};
                PODSData.Handles.ObjectSummaryTable.RowName = {};

                % first remove all styles
                removeStyle(PODSData.Handles.ObjectSummaryTable);
                % make sure all text is aligned left
                addStyle(PODSData.Handles.ObjectSummaryTable,sAlignment,'column',2);
                % add the style to missing cells
                addStyle(PODSData.Handles.ObjectSummaryTable,sMissing,'cell',[rMissing,cMissing]);
                % add label color square icon to object label cell
                addStyle(PODSData.Handles.ObjectSummaryTable,sLabel,'cell',[rLabel,cLabel+1]);
                % end testing


            else
                PODSData.Handles.AppInfoPanel.Title = 'No object found';
                PODSData.Handles.ObjectSummaryTable.Data = [];
                PODSData.Handles.ObjectSummaryTableGrid.Visible = 'off';
                return
            end

    end


    function answer = isLogicalTrue(x)
        answer = false;
        if ~islogical(x)
            return
        end
        if x
            answer = true;
        end
        % if ~islogical(x); answer=false; elseif x; answer=true; end
    end

    function answer = isLogicalFalse(x)
        answer = false;
        if ~islogical(x)
            return
        end
        if ~x
            answer = true;
        end
        % if ~islogical(x); answer=false; elseif ~x; answer=true; end
    end




end