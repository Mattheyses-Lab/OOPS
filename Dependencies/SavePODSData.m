function TableOut = SavePODSData(source,event)

    PODSData = guidata(source);
    
    PODSDataOut = struct('GroupIdx',0,...
                         'GroupName',[],...
                         'ImageIdx',0,...
                         'ImageName',[],...
                         'ObjectIdx',0,...
                         'ObjectAvgOF',0,...
                         'SBRatio',0,...
                         'Area',0,...
                         'Perimeter',0);
    
    MasterIdx = 1;
    AllOFPerGroup = {};
               
    for i = 1:PODSData.nGroups
        
        allgroupdata = [];
        
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
                
                MasterIdx = MasterIdx+1;
                
                allgroupdata(1,end+1) = PODSData.Group(i).Replicate(j).Object(k).OFAvg;
                
            end % end objects
        end % end images
        
        AllOFPerGroup{i} = allgroupdata;
        clear allgroupdata
        
    end % end groups
    
    save('AllOFPerGroup.mat','AllOFPerGroup');
    
    TableOut = struct2table(PODSDataOut);
    clear PODSDataOut
    
end