function [] = UpdateSummaryDisplay(source,varargin)

    OOPSData = guidata(source);

    dataOnly = false;

    % check if we really need to update to prevent unnecessary overhead
    % varargin{1} = {'Project','Image',...}
    if ~isempty(varargin)
        if any(ismember('DataOnly',varargin{1}))
            dataOnly = true;
        end
        % if no choices match currently selected display type, don't update
        if ~any(ismember(varargin{1},OOPSData.Settings.SummaryDisplayType))
            return
        end
    end

    % set the title of the summary panel
    OOPSData.Handles.AppInfoPanel.Title = [OOPSData.Settings.SummaryDisplayType,' summary'];
    % hide grid layout managers for all summary tables
    set(findobj(OOPSData.Handles.AppInfoPanel.Children(),'type','uigridlayout'),'Visible','off');
    % show the grid layout manager for the summary type that is active
    OOPSData.Handles.([OOPSData.Settings.SummaryDisplayType,'SummaryTableGrid']).Visible = 'on';

    switch OOPSData.Settings.SummaryDisplayType

        case 'Project'

            projectTable = OOPSData.ProjectSummaryDisplayTable;
            OOPSData.Handles.ProjectSummaryTable.Data = projectTable;
            OOPSData.Handles.ProjectSummaryTable.ColumnName = {};
            OOPSData.Handles.ProjectSummaryTable.RowName = {};

            % first remove all styles
            removeStyle(OOPSData.Handles.ProjectSummaryTable);

            % color cell based on selected GUI background color
            % get row and col coordinates to the cell corresponding to 'GUI background color'
            [r,c] = find(ismember(projectTable.Variables,'GUI background color'));
            % create an icon color style for the cell
            s = uistyle('Icon',makeRGBColorSquare(OOPSData.Settings.GUIBackgroundColor,1));
            % add the style to the table
            addStyle(OOPSData.Handles.ProjectSummaryTable,s,'cell',[r,c+1]);

            % color cell based on selected GUI foreground color
            % get row and col coordinates to the cell corresponding to 'GUI background color'
            [r,c] = find(ismember(projectTable.Variables,'GUI foreground color'));
            % create an icon color style for the cell
            s = uistyle('Icon',makeRGBColorSquare(OOPSData.Settings.GUIForegroundColor,1));
            % add the style to the table
            addStyle(OOPSData.Handles.ProjectSummaryTable,s,'cell',[r,c+1]);

            % color cell based on selected GUI foreground color
            % get row and col coordinates to the cell corresponding to 'GUI background color'
            [r,c] = find(ismember(projectTable.Variables,'GUI highlight color'));
            % create an icon color style for the cell
            s = uistyle('Icon',makeRGBColorSquare(OOPSData.Settings.GUIHighlightColor,1));
            % add the style to the table
            addStyle(OOPSData.Handles.ProjectSummaryTable,s,'cell',[r,c+1]);

        case 'Group'

            cGroup = OOPSData.CurrentGroup;

            if ~isempty(cGroup)

                % get the data for the group table
                groupTable = cGroup.GroupSummaryDisplayTable;

                % create an alignment style to make sure all text is left aligned
                sAlignment = uistyle("HorizontalAlignment","left");

                % create styles for cells with missing (NaN) values
                sMissing = uistyle("BackgroundColor",[1 0.6 0.6],"FontColor",[1 1 1]);
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
                OOPSData.Handles.GroupSummaryTable.Data = groupTable;
                % remove column and row names
                OOPSData.Handles.GroupSummaryTable.ColumnName = {};
                OOPSData.Handles.GroupSummaryTable.RowName = {};

                % first remove all styles
                removeStyle(OOPSData.Handles.GroupSummaryTable);
                % make sure all text is aligned left
                addStyle(OOPSData.Handles.GroupSummaryTable,sAlignment,'column',2);
                % add the styles to true or false cells
                addStyle(OOPSData.Handles.GroupSummaryTable,sFail,'cell',[rFalse,cFalse]);
                addStyle(OOPSData.Handles.GroupSummaryTable,sPass,'cell',[rTrue,cTrue]);
                % add the style to missing cells
                addStyle(OOPSData.Handles.GroupSummaryTable,sMissing,'cell',[rMissing,cMissing]);

            else
                OOPSData.Handles.AppInfoPanel.Title = 'No group found';
                OOPSData.Handles.GroupSummaryTable.Data = [];
                OOPSData.Handles.GroupSummaryTableGrid.Visible = 'off';
                return
            end

        case 'Image'

            cImage = OOPSData.CurrentImage;

            if ~isempty(cImage)

                imageTable = cImage(1).ImageSummaryDisplayTable;

                % add the table data to the uitable
                OOPSData.Handles.ImageSummaryTable.Data = imageTable;
                % remove column and row names
                OOPSData.Handles.ImageSummaryTable.ColumnName = {};
                OOPSData.Handles.ImageSummaryTable.RowName = {};

                if dataOnly
                    return
                end

                % create an alignment style to ensure all text is left-aligned
                sAlignment = uistyle("HorizontalAlignment","left");
                % create styles for cells with missing (NaN) values
                sMissing = uistyle("BackgroundColor",[1 0.6 0.6],"FontColor",[1 1 1]);
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

                % first remove all styles
                removeStyle(OOPSData.Handles.ImageSummaryTable);
                % make sure all text is aligned left
                addStyle(OOPSData.Handles.ImageSummaryTable,sAlignment,'column',2);
                % add the styles to true or false cells
                addStyle(OOPSData.Handles.ImageSummaryTable,sFail,'cell',[rFalse,cFalse]);
                addStyle(OOPSData.Handles.ImageSummaryTable,sPass,'cell',[rTrue,cTrue]);
                % add the style to missing cells
                addStyle(OOPSData.Handles.ImageSummaryTable,sMissing,'cell',[rMissing,cMissing]);

            else
                OOPSData.Handles.AppInfoPanel.Title = 'No image found';
                OOPSData.Handles.ImageSummaryTable.Data = [];
                OOPSData.Handles.ImageSummaryTableGrid.Visible = 'off';
                return
            end  

        case 'Object'

            cObject = OOPSData.CurrentObject;

            if ~isempty(cObject)

                objectTable = cObject.ObjectSummaryDisplayTable;

                % create an alignment style to make sure all text is left aligned
                sAlignment = uistyle("HorizontalAlignment","left");

                % create styles for cells with missing (NaN) values
                sMissing = uistyle("BackgroundColor",[1 0.6 0.6],"FontColor",[1 1 1]);
                % find indices to the missing values
                [rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), objectTable.Object));
                cMissing = cMissing + 1;

                % get row and col coordinates to the cell corresponding to 'GUI background color'
                %[rLabel,cLabel] = find(ismember(objectTable.Variables,'Label'));
                [rLabel,cLabel] = find(cellfun(@(x) strcmp(x,'Label'), objectTable.Variables));
                % create an icon color style for the cell
                sLabel = uistyle('Icon',cObject.LabelColorSquare);

                % add the table data to the uitable
                OOPSData.Handles.ObjectSummaryTable.Data = objectTable;
                % remove column and row names
                OOPSData.Handles.ObjectSummaryTable.ColumnName = {};
                OOPSData.Handles.ObjectSummaryTable.RowName = {};

                % first remove all styles
                removeStyle(OOPSData.Handles.ObjectSummaryTable);
                % make sure all text is aligned left
                addStyle(OOPSData.Handles.ObjectSummaryTable,sAlignment,'column',2);
                % add the style to missing cells
                addStyle(OOPSData.Handles.ObjectSummaryTable,sMissing,'cell',[rMissing,cMissing]);
                % add label color square icon to object label cell
                addStyle(OOPSData.Handles.ObjectSummaryTable,sLabel,'cell',[rLabel,cLabel+1]);
                % end testing

            else
                OOPSData.Handles.AppInfoPanel.Title = 'No object found';
                OOPSData.Handles.ObjectSummaryTable.Data = [];
                OOPSData.Handles.ObjectSummaryTableGrid.Visible = 'off';
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