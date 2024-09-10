function ObjectIntensityProfileSettingsChanged(source,~)
%%  OBJECTINTENSITYPROFILESETTINGSCHANGED Callbacks for various components controlling 
%   appearance of the object intensity fit plot
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

    % set the value of the property to the new value of the component
    OOPSData.Settings.ObjectIntensityProfileSettings.(propName) = source.Value;

    % update the display
    UpdateObjectIntensityProfile(source);

end