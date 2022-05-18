function [] = UpdateTables(source)

    PODSData = guidata(source);
    cGroupIndex = PODSData.CurrentGroupIndex;
    cGroup = PODSData.CurrentGroup;
    
    
    % in case no images exist for current group
    try
        cReplicate = PODSData.CurrentImage(1);
    catch
        PODSData.Handles.ProjectDataTable.Text = {['Load some data to see summary...']};
        return
    end
    
    if cReplicate.nObjects == 0
 
        PODSData.Handles.ProjectDataTable.Text = {['<b>Project Overview</b>'];...
                                         [PODSData.ProjectName];...
                                         ['Number of Groups:     ', num2str(PODSData.nGroups)];...
                                         ['Input File Type:      ', PODSData.Settings.InputFileType];...
                                         ['Current Tab:          ', PODSData.Settings.CurrentTab];...
                                         ['Previous Tab:         ', PODSData.Settings.PreviousTab];...
                                         ['                      '];...
                                         ['<b>Group Summary</b>'];...
                                         [cGroup.GroupName];...
                                         ['Number of Replicates: ', num2str(cGroup.nReplicates)];...
                                         ['Group Image Avg OF:   ', num2str(cGroup.OFAvg)];,...
                                         ['Total Objects:        ', num2str(cGroup.TotalObjects)];,...
                                         ['                      '];...
                                         ['<b>Replicate Summary</b>'];...
                                         [cReplicate.pol_shortname];...
                                         ['Dimensions:           ', cReplicate.Dimensions];...
                                         ['<b>Masking</b>'];...
                                         ['Mask Threshold:       ', num2str(cReplicate.level)];...
                                         ['Threshold Adjusted:   ', Logical2String(cReplicate.ThresholdAdjusted)];...
                                         ['Number of Objects:    ', num2str(cReplicate.nObjects)];...
                                         ['<b>Order Factor Results</b>'];...
                                         ['Avg Pixel OF:         ', num2str(cReplicate.OFAvg)];...
                                         ['<b>Status</b>'];...
                                         ['Files Loaded:         ', Logical2String(cReplicate.FilesLoaded)];...
                                         ['FFC Performed:        ', Logical2String(cReplicate.FFCDone)];...
                                         ['Mask Generated:       ', Logical2String(cReplicate.MaskDone)];...
                                         ['Objects Detected:     ', Logical2String(cReplicate.ObjectDetectionDone)];...
                                         ['OF Calculated:        ', Logical2String(cReplicate.OFDone)];...
                                         ['Local SB Calculated:  ', Logical2String(cReplicate.LocalSBDone)]};
        return
    end
    
    try
        cObject = cReplicate.CurrentObject;
    catch
        
    PODSData.Handles.ProjectDataTable.Text = {['<b>Project Overview</b>'];...
                                     [PODSData.ProjectName];...
                                     ['Number of Groups:     ', num2str(PODSData.nGroups)];...
                                     ['Input File Type:      ', PODSData.Settings.InputFileType];...
                                     ['Current Tab:          ', PODSData.Settings.CurrentTab];...
                                     ['Previous Tab:         ', PODSData.Settings.PreviousTab];...
                                     ['                      '];...
                                     ['<b>Group Summary</b>'];...
                                     [cGroup.GroupName];...
                                     ['Number of Replicates: ', num2str(cGroup.nReplicates)];...
                                     ['Group Image Avg OF:   ', num2str(cGroup.OFAvg)];,...
                                     ['Total Objects:        ', num2str(cGroup.TotalObjects)];,...
                                     ['                      '];...
                                     ['<b>Replicate Summary</b>'];...
                                     [cReplicate.pol_shortname];...
                                     ['Dimensions:           ', cReplicate.Dimensions];...
                                     ['<b>Masking</b>'];...
                                     ['Mask Threshold:       ', num2str(cReplicate.level)];...
                                     ['Threshold Adjusted:   ', Logical2String(cReplicate.ThresholdAdjusted)];...
                                     ['Number of Objects:    ', num2str(cReplicate.nObjects)];...
                                     ['<b>Order Factor Results</b>'];...
                                     ['Avg Pixel OF:         ', num2str(cReplicate.OFAvg)];...
                                     ['<b>Status</b>'];...
                                     ['Files Loaded:         ', Logical2String(cReplicate.FilesLoaded)];...
                                     ['FFC Performed:        ', Logical2String(cReplicate.FFCDone)];...
                                     ['Mask Generated:       ', Logical2String(cReplicate.MaskDone)];...
                                     ['Objects Detected:     ', Logical2String(cReplicate.ObjectDetectionDone)];...
                                     ['OF Calculated:        ', Logical2String(cReplicate.OFDone)];...
                                     ['Local SB Calculated:  ', Logical2String(cReplicate.LocalSBDone)]};
        return
    end   
    
    

    PODSData.Handles.ProjectDataTable.Text = {['<b>Project Overview</b>'];...
                                     [PODSData.ProjectName];...
                                     ['Number of Groups:     ', num2str(PODSData.nGroups)];...
                                     ['Input File Type:      ', PODSData.Settings.InputFileType];...
                                     ['Current Tab:          ', PODSData.Settings.CurrentTab];...
                                     ['Previous Tab:         ', PODSData.Settings.PreviousTab];...
                                     ['                      '];...
                                     ['<b>Group Summary</b>'];...
                                     [cGroup.GroupName];...
                                     ['Number of Replicates: ', num2str(cGroup.nReplicates)];...
                                     ['Group Image Avg OF:   ', num2str(cGroup.OFAvg)];,...
                                     ['Total Objects:        ', num2str(cGroup.TotalObjects)];,...
                                     ['                      '];...
                                     ['<b>Replicate Summary</b>'];...
                                     [cReplicate.pol_shortname];...
                                     ['Dimensions:           ', cReplicate.Dimensions];...
                                     ['<b>Masking</b>'];...
                                     ['Mask Threshold:       ', num2str(cReplicate.level)];...
                                     ['Threshold Adjusted:   ', Logical2String(cReplicate.ThresholdAdjusted)];...
                                     ['Number of Objects:    ', num2str(cReplicate.nObjects)];...
                                     ['<b>Order Factor Results</b>'];...
                                     ['Avg Pixel OF:         ', num2str(cReplicate.OFAvg)];...
                                     ['<b>Status</b>'];...
                                     ['Files Loaded:         ', Logical2String(cReplicate.FilesLoaded)];...
                                     ['FFC Performed:        ', Logical2String(cReplicate.FFCDone)];...
                                     ['Mask Generated:       ', Logical2String(cReplicate.MaskDone)];...
                                     ['Objects Detected:     ', Logical2String(cReplicate.ObjectDetectionDone)];...
                                     ['OF Calculated:        ', Logical2String(cReplicate.OFDone)];...
                                     ['Local SB Calculated:  ', Logical2String(cReplicate.LocalSBDone)];...
                                     ['                      '];...
                                     ['<b>Object Summary</b>'];...
                                     [cObject.Name];...
                                     ['Average OF:           ', num2str(cObject.OFAvg)];...
                                     ['Pixel Area:           ', num2str(cObject.Area)];...
                                     ['Permieter:            ', num2str(cObject.Perimeter)];...
                                     ['Average Signal:       ', num2str(cObject.SignalAverage)];...
                                     ['Background Average:   ', num2str(cObject.BGAverage)];...
                                     ['Signal-Background:    ', num2str(cObject.SBRatio)];...
                                     ['Original Idx:         ', num2str(cObject.OriginalIdx)]};

end