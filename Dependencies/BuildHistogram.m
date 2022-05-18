function [IntensityBinCenters,IntensityHistPlot] = BuildHistogram(im)
% Adapted from thresh_tool()
    % (By Brandon Kuczenski for Kensington Labs)
    % (brandon_kuczenski@kensingtonlabs.com)
    % (8 November 2001)

    color_range = double(limits(im));
    max_colors = 1000;

    if isa(im,'uint8') %special case [0 255]
        color_range = [0 255];
        num_colors = 256;
        di = 1;
    elseif isinteger(im)
        %try direct indices first
        num_colors = diff(color_range)+1;
        if num_colors<max_colors %okay
          di = 1;                                 %inherent bins
        else %too many levels
          num_colors = max_colors;                %practical limit
          di = diff(color_range)/(num_colors-1);
        end
    else %noninteger
        %try infering discrete resolution first (intensities often quantized)
        di = min(diff(sort(unique(im(:)))));
        num_colors = round(diff(color_range)/di)+1;
        if num_colors>max_colors %too many levels
            num_colors = max_colors;                %practical limit
            di = diff(color_range)/(num_colors-1);
        end
    end

    IntensityBinCenters = [color_range(1):di:color_range(2)];
    
    IntensityHistPlot = hist(double(im(:)),IntensityBinCenters);

end