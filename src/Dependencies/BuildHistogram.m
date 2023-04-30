function [IntensityBinCenters,IntensityHistPlot] = BuildHistogram(I)
% this does not need to be a separate function as of now, but we may add more control
% to n bins in the future

    [IntensityHistPlot,IntensityBinCenters] = imhist(I);

end