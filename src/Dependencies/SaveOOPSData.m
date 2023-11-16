function TableOut = SaveOOPSData(source)
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
    
    OOPSDataOut = struct(...
        'GroupIdx',0,...
        'GroupName',[],...
        'ImageIdx',0,...
        'ImageName',[],...
        'ObjectIdx',0,...
        'Area',0,...
        'AzimuthAngularDeviation',0,...
        'AzimuthAverage',0,...
        'AzimuthStd',0,...
        'BGAverage',0,...
        'Circularity',0,...
        'ConvexArea',0,...
        'Eccentricity',0,...
        'EquivDiameter',0,...
        'Extent',0,...
        'LabelName','',...
        'MajorAxisLength',0,...
        'MaxFeretDiameter',0,...
        'MidlineLength',0,...
        'MidlineRelativeAzimuth',0,...
        'MinFeretDiameter',0,...
        'MinorAxisLength',0,...
        'NormalRelativeAzimuth',0,...
        'OrderAvg',0,...
        'Perimeter',0,...
        'SBRatio',0,...
        'SignalAverage',0,...
        'Solidity',0,...
        'Tortuosity',0);

    MasterIdx = 1;

    for i = 1:OOPSData.nGroups

        for j = 1:OOPSData.Group(i).nReplicates

            for k = 1:OOPSData.Group(i).Replicate(j).nObjects

                % get the object
                thisObject = OOPSData.Group(i).Replicate(j).Object(k);                

                % add group, image, and object names/idxs to the table
                OOPSDataOut(MasterIdx).GroupIdx = i;
                OOPSDataOut(MasterIdx).GroupName = OOPSData.Group(i).GroupName;
                OOPSDataOut(MasterIdx).ImageIdx = j;
                OOPSDataOut(MasterIdx).ImageName = OOPSData.Group(i).Replicate(j).rawFPMShortName;
                OOPSDataOut(MasterIdx).ObjectIdx = k;

                % add object data to the table for each property
                OOPSDataOut(MasterIdx).Area = thisObject.Area;
                OOPSDataOut(MasterIdx).AzimuthAngularDeviation = thisObject.AzimuthAngularDeviation;
                OOPSDataOut(MasterIdx).AzimuthAverage = thisObject.AzimuthAverage;
                OOPSDataOut(MasterIdx).AzimuthStd = thisObject.AzimuthStd;
                OOPSDataOut(MasterIdx).BGAverage = thisObject.BGAverage;
                OOPSDataOut(MasterIdx).Circularity = thisObject.Circularity;
                OOPSDataOut(MasterIdx).ConvexArea = thisObject.ConvexArea;
                OOPSDataOut(MasterIdx).Eccentricity = thisObject.Eccentricity;
                OOPSDataOut(MasterIdx).EquivDiameter = thisObject.EquivDiameter;
                OOPSDataOut(MasterIdx).Extent = thisObject.Extent;
                OOPSDataOut(MasterIdx).LabelName = thisObject.LabelName;
                OOPSDataOut(MasterIdx).MajorAxisLength = thisObject.MajorAxisLength;
                OOPSDataOut(MasterIdx).MaxFeretDiameter = thisObject.MaxFeretDiameter;
                OOPSDataOut(MasterIdx).MidlineLength = thisObject.MidlineLength;
                OOPSDataOut(MasterIdx).MidlineRelativeAzimuth = thisObject.MidlineRelativeAzimuth;
                OOPSDataOut(MasterIdx).MinFeretDiameter = thisObject.MinFeretDiameter;
                OOPSDataOut(MasterIdx).MinorAxisLength = thisObject.MinorAxisLength;
                OOPSDataOut(MasterIdx).NormalRelativeAzimuth = thisObject.NormalRelativeAzimuth;
                OOPSDataOut(MasterIdx).OrderAvg = thisObject.OrderAvg;
                OOPSDataOut(MasterIdx).Perimeter = thisObject.Perimeter;
                OOPSDataOut(MasterIdx).SBRatio = thisObject.SBRatio;
                OOPSDataOut(MasterIdx).SignalAverage = thisObject.SignalAverage;
                OOPSDataOut(MasterIdx).Solidity = thisObject.Solidity;
                OOPSDataOut(MasterIdx).Tortuosity = thisObject.Tortuosity;

                MasterIdx = MasterIdx+1;

            end % end objects

        end % end images

    end % end groups
    
    TableOut = struct2table(OOPSDataOut);
    clear OOPSDataOut
    
end