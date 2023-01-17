function CumulativeHist = CumulativeHistogram(Data,Names)

    CumulativeHist = gobjects(size(Names));

    figure();

    for i = 1:length(Data)
        % get hist bin counts and edges
        [counts,edges] = histcounts(Data{i},'BinWidth',1);
        % cumulative distribution function, scaled between 0 and 100
        cdf = rescale(cumsum(counts),0,100);
        % plot the function
        CumulativeHist(i) = plot(edges(1:end-1), cdf,'DisplayName',Names{i});
        
        % hold on so we can plot more
        hold on
        bar(edges(1:end-1), cdf)
        % plot a line showing the max
        xline(edges(end),'-',Names{i},'LabelVerticalAlignment','Middle');
    end
    % release hold
    hold off
    % add a legend, using values in Names
    legend(CumulativeHist);

end