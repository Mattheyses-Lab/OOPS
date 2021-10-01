function data = pb_FFC(source,event)
    % get main data structure
    PODSData = guidata(source);

    for cReplicate = PODSData.CurrentImage
        try
            cReplicate.FlatFieldCorrection;
        catch
            UpdateLog3(source,['Failed to perform FFC for ',cReplicate.pol_shortname],'append');
            warning(['Failed to perform FFC for ',cReplicate.pol_shortname]);
        end
    end
        
    % normalize the images to the maximum value across the stack
    images = PODSData.CurrentImage(1).pol_ffc_normalizedbystack;

    % Update flat-field corrected intensity image objects with new data
    PODSData.Handles.PolFFCImage0.CData = images(:,:,1);
    PODSData.Handles.PolFFCImage45.CData = images(:,:,2);
    PODSData.Handles.PolFFCImage90.CData = images(:,:,3);
    PODSData.Handles.PolFFCImage135.CData = images(:,:,4);

    if ~strcmp(PODSData.Settings.CurrentTab,'FFC')
        feval(PODSData.Handles.hTabFFC.Callback,PODSData.Handles.hTabFFC,[]);
    end  
    
    % update the log and tables
    UpdateLog3(source,['Flat-Field Correction Performed for ',num2str(length(PODSData.CurrentGroup.CurrentImageIndex)),' replicates'],'append');
    UpdateTables(source);    
end