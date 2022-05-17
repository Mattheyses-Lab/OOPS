function PlotObjects(source,event)

    PODSData = guidata(source);   

    nGroups = PODSData.nGroups;

    XVar = '';
    XName = '';
    YVar = '';
    YName = '';
    
    ss = PODSData.Settings.ScreenSize;
    % center point (x,y) of screen
    center = [ss(3)/2,ss(4)/2];

%% Data Selection
    sz = [center(1)-250 center(2)-200 500 400];    

    SelectionFig = uifigure('Name','Select Variables',...
                            'Menubar','None',...
                            'Position',sz,...
                            'HandleVisibility','On');
    
    XSelectBox = uilistbox(SelectionFig,...
        'Items', {'Object Average Order Factor', 'Local Signal to Background', 'Area', 'Perimeter', 'Circularity', 'Average Coloc Intensity', 'ROI Pearsons'},...
        'ItemsData', {'OFAvg','SBRatio','Area','Perimeter','Circularity','AvgColocIntensity','ROIPearsons'},...
        'Position',[50 50 195 300],...
        'Tag','XSelectBox');
    XSelectLabel = uilabel(SelectionFig,'Position',[50 350 195 20],'Text','X Axis Variable','HorizontalAlignment','Center');
    
    YSelectBox = uilistbox(SelectionFig,...
        'Items', {'Object Average Order Factor', 'Local Signal to Background', 'Area', 'Perimeter', 'Circularity' 'Average Coloc Intensity', 'ROI Pearsons'},...
        'ItemsData', {'OFAvg','SBRatio','Area','Perimeter','Circularity','AvgColocIntensity','ROIPearsons'},...
        'Position',[255 50 195 300],...
        'Tag','YSelectBox');
    YSelectLabel = uilabel(SelectionFig,'Position',[255 350 195 20],'Text','Y Axis Variable','HorizontalAlignment','Center');

    Btn = uibutton(SelectionFig,'Push','Text','Continue','Position',[50 20 400 20],'ButtonPushedFcn',@MoveOn);
    
    function [] = MoveOn(source,event)
        XVar = XSelectBox.Value;
        YVar = YSelectBox.Value;
        XName = ExpandVariableName(XVar);
        YName = ExpandVariableName(YVar);
        close(SelectionFig)
    end
    
    % wait for deletion of SelectionFig (when data selection is complete)
    waitfor(SelectionFig)
    
%% Data Plotting    
    
    sz = [center(1)-500 center(2)-500 1000 1000];
    
    PlotFig = uifigure('Name','Data Plot',...
        'Menubar','none',...
        'Position',sz,...
        'HandleVisibility','On');

    %c = RandomColorSet(nGroups);
    
    ax = uiaxes('Parent',PlotFig,...
        'Units','Normalized',...
        'OuterPosition',[0.1 0.1 0.8 0.8],...
        'NextPlot','add');

    ax.Title.String = [YName,' vs ',XName];
    ax.XLabel.String = XName;
    ax.YLabel.String = YName;

    hold on

    for i = 1:nGroups
        
        try
            ObjectData = CombineObjectData(PODSData.Group(i),XVar,YVar);
            scatter(ax,ObjectData(:,1),ObjectData(:,2),...
                'MarkerFaceColor','flat',...
                'DisplayName',PODSData.Group(i).GroupName,...
                'MarkerFaceAlpha',0.5,...
                'MarkerEdgeAlpha',0.5);            
        catch
            UpdateLog3(source,['ERROR: No object data found for Group: ',PODSData.Group(i).GroupName],'append');
        end
        
    end
    lgd = legend(ax);
    hold off

end