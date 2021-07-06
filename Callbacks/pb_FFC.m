function data = pb_FFC(source,event)
    PODSData = guidata(source);
    cGroupIndex = PODSData.CurrentGroupIndex;
    
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    cReplicate = PODSData.Group(cGroupIndex).Replicate;
    
    % get FFCData and Handles structures
    FFCData = PODSData.Group(cGroupIndex).FFCData;
    Handles = PODSData.Handles;
    
    % number of input files to process
    n2Process = length(cImageIndex);
    
    if n2Process > 1
        first = cImageIndex(1);
        last = cImageIndex(end);
    else
        first = cImageIndex;
        last = cImageIndex;
    end
    
    for i=first:last
        
        % divide raw data images by flat-field image
        for ii=1:4
            cReplicate(i).pol_ffc(:,:,ii) = cReplicate(i).pol_rawdata(:,:,ii)./FFCData.cal_norm(:,:,ii);
        end

        cReplicate(i).FFCDone = 1;
        
    end
    
    PODSData.Group(cGroupIndex).Replicate = cReplicate;
    
    fReplicate = PODSData.Group(cGroupIndex).Replicate(cImageIndex(1));
    
    
    % Update flat-field corrected intensity image objects with new data
    Handles.PolFFCImage0.CData = fReplicate.pol_ffc_normalizedbystack(:,:,1);
    Handles.PolFFCImage45.CData = fReplicate.pol_ffc_normalizedbystack(:,:,2);
    Handles.PolFFCImage90.CData = fReplicate.pol_ffc_normalizedbystack(:,:,3);
    Handles.PolFFCImage135.CData = fReplicate.pol_ffc_normalizedbystack(:,:,4);
    
    


    
    % return updated handles to local PODSData
    PODSData.Handles = Handles;
    % pass updated PODSData to the gui
    guidata(source,PODSData);
    
    % Change tab to FFC tab   
    ChangePODSTab(source,'FFC');    
    
    % update the log and tables
    UpdateLog3(source,['Flat-Field Correction Performed for ',num2str(n2Process),' replicates'],'append');
    UpdateTables(source);    
end