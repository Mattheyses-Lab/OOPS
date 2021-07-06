function PlotViolins(source,event)

    PODSData = guidata(source);   

    nGroups = PODSData.nGroups;
    
    x = [];
    y = [];
    
    ss = PODSData.Settings.ScreenSize;
    % center point (x,y) of screen
    center = [ss(3)/2,ss(4)/2];
    
    sz = [center(1)-500 center(2)-500 1000 1000];   
    
    switch source.Text
        case 'Violin'
            
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

                    y = [y,cReplicate.Object.OFAvg];
                end
                % start index
                idx1 = size(x,2)+1;
                % end index
                idx2 = size(y,2);


                for ii = idx1:idx2
                    x{ii} = cGroup.GroupName;
                end

            end

            y = y';
            x = x';


            figure(2);


            violinplt = violinplot(y,x);
            


    end % end of main switch block  

end % end function