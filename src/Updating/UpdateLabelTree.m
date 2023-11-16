function UpdateLabelTree(source)
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

    % the main data structure
    OOPSData = guidata(source);

    % delete existing label tree nodes
    delete(OOPSData.Handles.LabelTree.Children);
    
    % build new nodes
    for i = 1:numel(OOPSData.Settings.ObjectLabels)
        uitreenode(OOPSData.Handles.LabelTree,...
            'Text',OOPSData.Settings.ObjectLabels(i).Name,...
            'NodeData',OOPSData.Settings.ObjectLabels(i),...
            'ContextMenu',OOPSData.Handles.LabelContextMenu,...
            'Icon',makeRGBColorSquare(OOPSData.Settings.ObjectLabels(i).Color,5));
    end

end