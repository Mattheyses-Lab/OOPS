function UpdateSummaryDisplay(source,varargin)
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

OOPSData = guidata(source);

dataOnly = false;

% check if we really need to update to prevent unnecessary overhead
% ex: if varargin{1} = {'Project','Group'}, only update if selected summary display type is 'Project' or 'Group'
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

OOPSData.Handles.ProjectSummaryTableGrid.Visible = 'on';
OOPSData.Handles.ProjectSummaryPanelGrid.Visible = 'on';

switch OOPSData.Settings.SummaryDisplayType

    case 'Project'

        % get the data for the project table
        projectTable = OOPSData.ProjectSummaryDisplayTable;

        % add the table data to the uitable
        OOPSData.Handles.ProjectSummaryTable.Data = projectTable;
        % remove column and row names
        OOPSData.Handles.ProjectSummaryTable.ColumnName = {};
        OOPSData.Handles.ProjectSummaryTable.RowName = {};

        % create styles for cells that are 'True' or 'False'
        sPass = uistyle("Icon","success","IconAlignment","rightmargin");
        sFail = uistyle("Icon","error","IconAlignment","rightmargin");

        % find the cells with char vectors 'True' or 'False'
        [rFalse,cFalse] = find(cellfun(@(x) strcmp(x,'False'), projectTable.Project));
        cFalse = cFalse + 1;
        [rTrue,cTrue] = find(cellfun(@(x) strcmp(x,'True'), projectTable.Project));
        cTrue = cTrue + 1;

        % remove all styles
        removeStyle(OOPSData.Handles.ProjectSummaryTable);
        % add the styles to true or false cells
        addStyle(OOPSData.Handles.ProjectSummaryTable,sFail,'cell',[rFalse,cFalse]);
        addStyle(OOPSData.Handles.ProjectSummaryTable,sPass,'cell',[rTrue,cTrue]);

    case 'Group'

        cGroup = OOPSData.CurrentGroup;

        if ~isempty(cGroup)

            % get the data for the group table
            groupTable = cGroup.GroupSummaryDisplayTable;

            % add the table data to the uitable
            OOPSData.Handles.ProjectSummaryTable.Data = groupTable;
            % remove column and row names
            OOPSData.Handles.ProjectSummaryTable.ColumnName = {};
            OOPSData.Handles.ProjectSummaryTable.RowName = {};

            % create an alignment style to make sure all text is left aligned
            sAlignment = uistyle("HorizontalAlignment","left");
            % create styles for cells with missing (NaN) values
            sMissing = uistyle("BackgroundColor",[1 0.6 0.6],"FontColor",[1 1 1]);
            % create styles for cells that are 'True' or 'False'
            sPass = uistyle("Icon","success","IconAlignment","rightmargin");
            sFail = uistyle("Icon","error","IconAlignment","rightmargin");

            % find indices to the missing values
            [rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), groupTable.Group));
            cMissing = cMissing + 1;

            % find the cells with char vectors 'True' or 'False'
            [rFalse,cFalse] = find(cellfun(@(x) strcmp(x,'False'), groupTable.Group));
            cFalse = cFalse + 1;
            [rTrue,cTrue] = find(cellfun(@(x) strcmp(x,'True'), groupTable.Group));
            cTrue = cTrue + 1;

            % first remove all styles
            removeStyle(OOPSData.Handles.ProjectSummaryTable);
            % make sure all text is aligned left
            addStyle(OOPSData.Handles.ProjectSummaryTable,sAlignment,'column',2);
            % add the styles to true or false cells
            addStyle(OOPSData.Handles.ProjectSummaryTable,sFail,'cell',[rFalse,cFalse]);
            addStyle(OOPSData.Handles.ProjectSummaryTable,sPass,'cell',[rTrue,cTrue]);
            % add the style to missing cells
            addStyle(OOPSData.Handles.ProjectSummaryTable,sMissing,'cell',[rMissing,cMissing]);

        else
            OOPSData.Handles.AppInfoPanel.Title = 'No group found';
            OOPSData.Handles.ProjectSummaryTable.Data = [];
            OOPSData.Handles.ProjectSummaryTableGrid.Visible = 'off';
            return
        end

    case 'Image'

        % current image selection
        cImage = OOPSData.CurrentImage;

        if ~isempty(cImage)

            % only use the first image in the selection
            cImage = cImage(1);

            % get the data for the image table
            imageTable = cImage.ImageSummaryDisplayTable;

            % add the table data to the uitable
            OOPSData.Handles.ProjectSummaryTable.Data = imageTable;
            % remove column and row names
            OOPSData.Handles.ProjectSummaryTable.ColumnName = {};
            OOPSData.Handles.ProjectSummaryTable.RowName = {};

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
            % create style for cells with a warning (in case threshold is adjusted)
            sWarning = uistyle('Icon',"warning","IconAlignment","rightmargin");

            % if threshold adjusted, store idx to Mask threshold cell
            if cImage.ThresholdAdjusted
                % get row and col coordinates to the cell corresponding to 'Mask threshold'
                [rWarning,cWarning] = find(ismember(imageTable.Row,'Mask threshold'));
                % add one to col idx to get the cell containing the value
                cWarning = cWarning+1;
            end

            % find indices to the missing values
            [rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), imageTable.Image));
            cMissing = cMissing + 1;

            % find the cells with char vectors 'True' or 'False'
            [rFalse,cFalse] = find(cellfun(@(x) strcmp(x,'False'), imageTable.Image));
            cFalse = cFalse + 1;
            [rTrue,cTrue] = find(cellfun(@(x) strcmp(x,'True'), imageTable.Image));
            cTrue = cTrue + 1;

            % first remove all styles
            removeStyle(OOPSData.Handles.ProjectSummaryTable);
            % make sure all text is aligned left
            addStyle(OOPSData.Handles.ProjectSummaryTable,sAlignment,'column',2);
            % add the styles to true or false cells
            addStyle(OOPSData.Handles.ProjectSummaryTable,sFail,'cell',[rFalse,cFalse]);
            addStyle(OOPSData.Handles.ProjectSummaryTable,sPass,'cell',[rTrue,cTrue]);
            % add the style to missing cells
            addStyle(OOPSData.Handles.ProjectSummaryTable,sMissing,'cell',[rMissing,cMissing]);

            % if threshold adjusted, add warning style to Mask threshold value cell
            if cImage.ThresholdAdjusted
                % add the style to warning cells
                addStyle(OOPSData.Handles.ProjectSummaryTable,sWarning,'cell',[rWarning,cWarning]);
            end

        else
            OOPSData.Handles.AppInfoPanel.Title = 'No image found';
            OOPSData.Handles.ProjectSummaryTable.Data = [];
            OOPSData.Handles.ProjectSummaryTableGrid.Visible = 'off';
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
            %[rMissing,cMissing] = find(cellfun(@(x) all(ismissing(x)), objectTable.Object));
            [rMissing,cMissing] = find(cellfun(@(x) contains(x,'NaN'), objectTable.Object));
            objectTable.Object(rMissing) = {'NaN'};
            cMissing = cMissing + 1;

            % create an icon color style for the cell
            sLabel = uistyle('Icon',cObject.LabelColorSquare);                
            % get row and col coordinates to the cell corresponding to 'Label'
            [rLabel,cLabel] = find(cellfun(@(x) strcmp(x,'Label'), objectTable.Variables));
            cLabel = cLabel + 1;

            % add the table data to the uitable
            OOPSData.Handles.ProjectSummaryTable.Data = objectTable;
            % remove column and row names
            OOPSData.Handles.ProjectSummaryTable.ColumnName = {};
            OOPSData.Handles.ProjectSummaryTable.RowName = {};

            % first remove all styles
            removeStyle(OOPSData.Handles.ProjectSummaryTable);
            % make sure all text is aligned left
            addStyle(OOPSData.Handles.ProjectSummaryTable,sAlignment,'column',2);
            % add the style to missing cells
            addStyle(OOPSData.Handles.ProjectSummaryTable,sMissing,'cell',[rMissing,cMissing]);
            % add label color square icon to object label cell
            addStyle(OOPSData.Handles.ProjectSummaryTable,sLabel,'cell',[rLabel,cLabel]);
        else
            OOPSData.Handles.AppInfoPanel.Title = 'No object found';
            OOPSData.Handles.ProjectSummaryTable.Data = [];
            OOPSData.Handles.ProjectSummaryTableGrid.Visible = 'off';
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
    end
    
    function answer = isLogicalFalse(x)
        answer = false;
        if ~islogical(x)
            return
        end
        if ~x
            answer = true;
        end
    end

end