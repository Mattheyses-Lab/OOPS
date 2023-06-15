function plotMarkers = getPlotMarkers(nMarkers)

    % cell array of char vectors for each possible plot marker
    allMarkers = {...
        'o',... % circle
        's',... % square
        '^',... % upward-pointing triangle
        'h',... % hexagram
        'p',... % pentagram
        'd',... % diamond
        'v',... % downward-pointing triangle
        '>',... % right-pointing triangle
        '<',... % left-pointing triangle
        '+',... % plus sign
        '*',... % asterisk
        'x',... % cross
        '_',... % horizontal line
        '|'...  % vertical line
        };

    % throw error if too many plot markers requested
    if nMarkers > numel(allMarkers)
        error('getplotMarkers:invalidInput','nMarkers can not be greater than 14')
    end

    % return cell array containing the requested number of plot markers
    plotMarkers = allMarkers(1:nMarkers);

end