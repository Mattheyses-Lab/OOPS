function [] = UpdateSummaryDisplay(source,varargin)

    PODSData = guidata(source);

    % check if we really need to update to prevent unnecessary overhead
    % varargin{1} = {'Project','Image',...}
    if ~isempty(varargin)
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
                groupTable = cGroup.GroupSummaryDisplayTable;
                PODSData.Handles.GroupSummaryTable.Data = groupTable;
                PODSData.Handles.GroupSummaryTable.ColumnName = {};
                PODSData.Handles.GroupSummaryTable.RowName = {};
            else
                PODSData.Handles.AppInfoPanel.Title = 'No group found';
                PODSData.Handles.GroupSummaryTable.Data = [];
                PODSData.Handles.GroupSummaryTableGrid.Visible = 'off';
                return
            end

        case 'Image'

            cImage = PODSData.CurrentImage;

            if ~isempty(cImage)
                imageTable = cImage(1).ImageSummaryDisplayTable;
                PODSData.Handles.ImageSummaryTable.Data = imageTable;
                PODSData.Handles.ImageSummaryTable.ColumnName = {};
                PODSData.Handles.ImageSummaryTable.RowName = {};
            else
                PODSData.Handles.AppInfoPanel.Title = 'No image found';
                PODSData.Handles.ImageSummaryTable.Data = [];
                PODSData.Handles.ImageSummaryTableGrid.Visible = 'off';
                return
            end  

        case 'Object'

            cObject = PODSData.CurrentObject;

            if ~isempty(cObject)
                objectTable = cObject.ObjectSummaryDisplayTable;
                PODSData.Handles.ObjectSummaryTable.Data = objectTable;
                PODSData.Handles.ObjectSummaryTable.ColumnName = {};
                PODSData.Handles.ObjectSummaryTable.RowName = {};
            else
                PODSData.Handles.AppInfoPanel.Title = 'No object found';
                PODSData.Handles.ObjectSummaryTable.Data = [];
                PODSData.Handles.ObjectSummaryTableGrid.Visible = 'off';
                return
            end

    end

end