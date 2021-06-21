function PlotViolins(source,event)
    PODSData = guidata(source);
    
    nGroups = PODSData.nGroups;
    
    xdata = [];
    ydata = [];
    
    
    % for each group
    for i = 1:nGroups
        % current group
        cGroup = PODSData.Group(i);
        % n images in group
        nImages = cGroup.nReplicates;
        % for each image in group
        for j = 1:nImages
            % current replicate
            cReplicate = cGroup.Replicate(j);
            
            ydata = [ydata,cReplicate.Object.OFAvg];
        end
        % start index
        idx1 = size(xdata,2)+1;
        % end index
        idx2 = size(ydata,2);
        
        
        for ii = idx1:idx2
            xdata{ii} = cGroup.GroupName;
        end

    end
    
    ydata = ydata';
    xdata = xdata';
    
    
    figure(2);
    
    
    violinplt = violinplot(ydata,xdata);
    
    
    

end