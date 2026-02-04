function exportObjectIntensityMontage(source,~)
% exportImages  Exports normalized object intensity stack as a 1x4 montage (RGB)
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

% handle to main data structure
OOPSData = guidata(source);

% currently selected image in the GUI (take the first in case multiple are selected)
cImage = OOPSData.CurrentImage(1);

% currently selected object in the image
cObject = cImage.CurrentObject;

if isempty(cObject)
    uialert(OOPSData.Handles.fH,'No object selected. Please select an object to export.','Error');
    return;
end

% metadata to attach to the files
softwareName = 'Object-Oriented Polarization Software (OOPS)';

%% choose save directory

uialert(OOPSData.Handles.fH,'Choose directory','Select export folder',...
    'Icon','',...
    'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));

uiwait(OOPSData.Handles.fH);

OOPSData.Handles.fH.Visible = 'Off';

try
    pathname = uigetdir('*.mat','Choose directory',OOPSData.Settings.LastDirectory);
catch
    pathname = uigetdir('*.mat','Choose directory');
end

OOPSData.Handles.fH.Visible = 'On';

figure(OOPSData.Handles.fH);

if ~pathname
    uialert(OOPSData.Handles.fH,'Invalid filename...','Error');
    return
else
    OOPSData.Settings.LastDirectory = pathname;
end

if ismac || isunix
    pathSep = '/';
elseif ispc
    pathSep = '\';
end

% name of the exported image
name = sprintf([pathname,pathSep,cImage.rawFPMShortName,'_object-%03d_montage.png'],cObject.SelfIdx);
% print name to log
UpdateLog3(source,name,'append');
% get the image data to export
IOut = cObject.IntensityStackNormMontageRGB;
% write the image data
imwrite(IOut,name,'Software',softwareName);
% update log to indicate completion
UpdateLog3(source,'Done.','append');

end