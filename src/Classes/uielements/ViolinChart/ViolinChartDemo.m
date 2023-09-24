function violinChart = ViolinChartDemo()

    nViolins = 10;

%% generate some data and random datatip info for each marker

    % create set of means between 5 and 10
    mus = randi([5,10],[1,nViolins]);
    % same SD for each dataset
    sigmas = ones(nViolins,1);

    % preallocate data cell
    Data = cell(nViolins,1);

    % define some arbitrary data tips categories (each value multiplied by 1, 2, or 3)
    dataTipLabels = {'1X','2X','3X','4X'};

    % preallocate datatip data cell (one cell per violin)
    dtNames = cell(nViolins,1);
    % preallocate datatip data cell (one cell per violin)
    dtData = cell(nViolins,1);


    % the number of datatip categories
    nDataTipTypes = numel(dataTipLabels);


    
    % for each violin
    for i=1:nViolins
        % create random, normally distributed data
        Data{i} = normrnd(mus(i),sigmas(i),500,1);
        % add datatip names and values for each dataset (we will have one of these cells per violin)
        dtNames{i} = dataTipLabels;
        % cell array of datatip values for each label (we will have one of these cells per violin)
        dataTipValues = cell(1,numel(dtNames{i}));
        % add arbitrary values for each datatip label (Data * 1, Data * 2, etc...)
        for ii = 1:nDataTipTypes
            dataTipValues{1,ii} = Data{i}.*ii;
        end
        % add the set of datatip values for each label to the cell in dtData for this violin
        dtData{i} = dataTipValues;
    end

    % horizontally concatenate datatip names and values to create the datatip cell passed into ViolinChart
    dtCell = [dtNames,dtData];    
    
    % create a figure to hold the component
    fig = uifigure("HandleVisibility","on",...
        "Name","Violin Chart Demo",...
        "WindowStyle","alwaysontop",...
        "Visible","off");

    % edge color
    MarkerEdgeColor = [0 0 0];

    % violin face color
    %ViolinFaceColor = [1 1 1];
    ViolinFaceColor = [];
    


    % nViolinsx1 cell array of random RGB triplets - one color for all of the markers in each plot
    %CData = cellfun(@(x) rand(1,3),cell(nViolins,1),'UniformOutput',false);
    %CData = Data;
    CData = {};


    % single color for all violin edges
    %ViolinEdgeColor = [0 0 0];

    % edge colors matching group colors
    %ViolinEdgeColor = cell2mat(CData);
    % ViolinEdgeColor = cell2mat(cellfun(@(x) rand(1,3),cell(nViolins,1),'UniformOutput',false));
    ViolinEdgeColor = [0 0 0];



    % CData corresponds to data, color of each marker is set by its value, the selected colormap, and the color limits
    %CData = Data;

    violinChart = ViolinChart(...
        "Parent",fig,...
        "Title",'Violin Chart Demo',...
        "Data",Data,...
        "BackgroundColor",[1 1 1],...
        "ForegroundColor",[0 0 0],...
        "FontColor",[0 0 0],...
        "Position",[0 0 1 1],...
        "PlotSpacing",1,...
        "XJitterWidth",0.5,...
        "DataTipCell",dtCell,...
        "XLabel",'Group',...
        "YLabel",'Variable name',...
        "MarkerEdgeColor",MarkerEdgeColor,...
        "MarkerSize",25,...
        "CData",CData,...
        "ViolinOutlinesVisible","on",...
        "ViolinLineWidth",2,...
        "ViolinFaceColor",ViolinFaceColor,...
        "ViolinEdgeColor",ViolinEdgeColor,...
        "CLimMode","auto");

    fig.Visible = "on";

end