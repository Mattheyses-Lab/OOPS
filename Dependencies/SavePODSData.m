function TableOut = SavePODSData(source)

    PODSData = guidata(source);
    
    PODSDataOut = struct('GroupIdx',0,...
                         'GroupName',[],...
                         'ImageIdx',0,...
                         'ImageName',[],...
                         'ObjectIdx',0,...
                         'ObjectAvgOF',0,...
                         'SBRatio',0,...
                         'Area',0,...
                         'Perimeter',0,...
                         'SignalAvg',0,...
                         'BGAvg',0,...
                         'Circularity',0,...
                         'Eccentricity',0,...
                         'ConvexArea',0,...
                         'MaxFeretDiameter',0,...
                         'MinFeretDiameter',0,...
                         'LabelName','');


    MasterIdx = 1;
               
    for i = 1:PODSData.nGroups
        for j = 1:PODSData.Group(i).nReplicates
            for k = 1:PODSData.Group(i).Replicate(j).nObjects
                PODSDataOut(MasterIdx).GroupIdx = i;
                PODSDataOut(MasterIdx).GroupName = PODSData.Group(i).GroupName;
                PODSDataOut(MasterIdx).ImageIdx = j;
                PODSDataOut(MasterIdx).ImageName = PODSData.Group(i).Replicate(j).pol_shortname;
                PODSDataOut(MasterIdx).ObjectIdx = k;
                PODSDataOut(MasterIdx).ObjectAvgOF =  PODSData.Group(i).Replicate(j).Object(k).OFAvg;
                PODSDataOut(MasterIdx).SBRatio = PODSData.Group(i).Replicate(j).Object(k).SBRatio;
                PODSDataOut(MasterIdx).Area =  PODSData.Group(i).Replicate(j).Object(k).Area;
                PODSDataOut(MasterIdx).Perimeter =  PODSData.Group(i).Replicate(j).Object(k).Perimeter;
                PODSDataOut(MasterIdx).SignalAvg =  PODSData.Group(i).Replicate(j).Object(k).SignalAverage;
                PODSDataOut(MasterIdx).BGAvg =  PODSData.Group(i).Replicate(j).Object(k).BGAverage;
                PODSDataOut(MasterIdx).Circularity =  PODSData.Group(i).Replicate(j).Object(k).Circularity;
                PODSDataOut(MasterIdx).Eccentricity =  PODSData.Group(i).Replicate(j).Object(k).Eccentricity;
                PODSDataOut(MasterIdx).ConvexArea =  PODSData.Group(i).Replicate(j).Object(k).ConvexArea;
                PODSDataOut(MasterIdx).MaxFeretDiameter =  PODSData.Group(i).Replicate(j).Object(k).MaxFeretDiameter;
                PODSDataOut(MasterIdx).MinFeretDiameter =  PODSData.Group(i).Replicate(j).Object(k).MinFeretDiameter;
                PODSDataOut(MasterIdx).LabelName =  PODSData.Group(i).Replicate(j).Object(k).LabelName;                
                MasterIdx = MasterIdx+1;
            end % end objects
        end % end images
    end % end groups
    
    TableOut = struct2table(PODSDataOut);
    clear PODSDataOut
    
end