function data = pb_FFC(source,event)
    PODSData = guidata(source);
    cGroupIndex = PODSData.CurrentGroupIndex;
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    Handles = PODSData.Handles;
    FFCData = PODSData.Group(cGroupIndex).FFCData;

    nReplicates = PODSData.Group(cGroupIndex).nReplicates;
    
    Replicate = PODSData.Group(cGroupIndex).Replicate;
    
    for i=1:nReplicates
        
        % divide raw data images by flat-field image
        for j=1:4
            Replicate(i).pol_ffc(:,:,j) = Replicate(i).pol_rawdata(:,:,j)./FFCData.cal_norm(:,:,j);
        end
        % normalize to the max value in the stack
        Replicate(i).pol_ffc_normalizedbystack = Replicate(i).pol_ffc./(max(max(max(Replicate(i).pol_ffc))));
        
    end
    
    PODSData.Group(cGroupIndex).Replicate = Replicate;
    
    Replicate = PODSData.Group(cGroupIndex).Replicate(cImageIndex);
    
    
    % Update flat-field corrected intensity image objects with new data
    Handles.PolFFCImage0.CData = Replicate.pol_ffc_normalizedbystack(:,:,1);
    Handles.PolFFCImage45.CData = Replicate.pol_ffc_normalizedbystack(:,:,2);
    Handles.PolFFCImage90.CData = Replicate.pol_ffc_normalizedbystack(:,:,3);
    Handles.PolFFCImage135.CData = Replicate.pol_ffc_normalizedbystack(:,:,4);
    
    
    % Change tab to FFC tab
    ChangePODSTab(source,'FFC');
    
    % return updated handles to local PODSData
    PODSData.Handles = Handles;
    
    % pass updated PODSData to the gui
    guidata(source,PODSData);
    
    % update the log
    UpdateLog3(source,['Flat-Field Correction Performed for ',num2str(nReplicates),' replicates'],'append');
    UpdateTables(source);    
end