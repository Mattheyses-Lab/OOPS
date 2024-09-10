function ScatterPlotSettingsChanged(source,~,doFullUpdate)
%%  SCATTERPLOTSETTINGSCHANGED Callbacks for various components controlling appearance of the ScatterPlot
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

    % get the main data structure
    OOPSData = guidata(source);

    % the name of the property we are changing is specified by the 'Tag' property of the component invoking the callback
    propName = source.Tag;

    % set the value of the property to to the new value of the component
    OOPSData.Settings.ScatterPlotSettings.(propName) = source.Value;

    % enable/disable certain components if necessary
    
    % if propName has the form 'XColorMode', where X is the name of the property it controls
    if endsWith(propName,'ColorMode')
        % split the character vector using 'ColorMode' as the delimeter
        newStr = split(propName,'ColorMode');
        % get the name of the associated property
        prefix = newStr{1};

        if ~isempty(prefix)
            % the colorpicker component controlled by the color mode dropdown (and its uilabel)
            hColorpicker = OOPSData.Handles.(['ScatterPlot',prefix,'ColorDropdown']);
            hColorpickerLabel = OOPSData.Handles.(['ScatterPlot',prefix,'ColorDropdownLabel']);
            % all color modes will be either "auto" or "Custom"
            switch source.Value
                case "auto"
                    % deactivate the custom colorpicker
                    hColorpicker.Enable = false;
                    hColorpickerLabel.Enable = false;
                case "Custom"
                    % activate the custom colorpicker (and its label)
                    hColorpicker.Enable = true;
                    hColorpickerLabel.Enable = true;
                    % update scatter plot settings with the custom color associated with the colorpicker using its 'Tag'
                    OOPSData.Settings.ScatterPlotSettings.(hColorpicker.Tag) = hColorpicker.Value;
                    % set the corresponding property of the scatter plot
                    OOPSData.Handles.GroupScatterPlot.(hColorpicker.Tag) = hColorpicker.Value;
            end
        end

    end

    if doFullUpdate
        % update the whole plot
        UpdateGroupScatterPlot(source);
    else
        % only update the specified property
        OOPSData.Handles.GroupScatterPlot.(propName) = source.Value;
    end

end