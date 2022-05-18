function TableOut = GetGroupObjectSummary(source)

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
    
    CurrentGroup = PODSData.CurrentGroup;

    MasterIdx = 1;

    for j = 1:CurrentGroup.nReplicates


        for k = 1:CurrentGroup.Replicate(j).nObjects
            
            PODSDataOut(MasterIdx).GroupIdx = PODSData.CurrentGroupIndex;
            PODSDataOut(MasterIdx).GroupName = CurrentGroup.GroupName;
            PODSDataOut(MasterIdx).ImageIdx = j;
            PODSDataOut(MasterIdx).ImageName = CurrentGroup.Replicate(j).pol_shortname;
            PODSDataOut(MasterIdx).ObjectIdx = k;
            PODSDataOut(MasterIdx).ObjectAvgOF =  CurrentGroup.Replicate(j).Object(k).OFAvg;
            PODSDataOut(MasterIdx).SBRatio = CurrentGroup.Replicate(j).Object(k).SBRatio;
            PODSDataOut(MasterIdx).Area =  CurrentGroup.Replicate(j).Object(k).Area;
            PODSDataOut(MasterIdx).Perimeter =  CurrentGroup.Replicate(j).Object(k).Perimeter;
            PODSDataOut(MasterIdx).SignalAvg =  CurrentGroup.Replicate(j).Object(k).SignalAverage;
            PODSDataOut(MasterIdx).BGAvg =  CurrentGroup.Replicate(j).Object(k).BGAverage;
            PODSDataOut(MasterIdx).Circularity =  CurrentGroup.Replicate(j).Object(k).Circularity;
            PODSDataOut(MasterIdx).Eccentricity =  CurrentGroup.Replicate(j).Object(k).Eccentricity;
            PODSDataOut(MasterIdx).ConvexArea =  CurrentGroup.Replicate(j).Object(k).ConvexArea;
            PODSDataOut(MasterIdx).MaxFeretDiameter =  CurrentGroup.Replicate(j).Object(k).MaxFeretDiameter;
            PODSDataOut(MasterIdx).MinFeretDiameter =  CurrentGroup.Replicate(j).Object(k).MinFeretDiameter;
            PODSDataOut(MasterIdx).LabelName =  CurrentGroup.Replicate(j).Object(k).LabelName;
            
            MasterIdx = MasterIdx+1;

        end % end objects
        
    end % end images
    
    TableOut = struct2table(PODSDataOut);
    clear PODSDataOut    

end