function pastelColors = randomPastelColors(nColors)

    v = 1;
    s = 0.5;

    % constant value
    v = repmat(v,nColors,1);

    % constant saturation
    s = repmat(s,nColors,1);

    % generate 100 random hues in radians in the range [0 2pi]
    h = sort(rand(100,1))*2*pi;
    
    % shift the vector up/down one position
    h_shift1 = [h(end);h(1:end-1)];
    h_shift2 = [h(2:end);h(1)];

    % get pairwise angular distances between neighboring hues (ignoring directionality)
    h_dist1 = abs(circ_dist(h,h_shift1));
    h_dist2 = abs(circ_dist(h,h_shift2));

    % get the average of the angular distances in either directions
    h_dist_mean = (h_dist1+h_dist2)/2;

    % get the nColors values with the largest average angular distance betwwen neighboring hues
    [~,maxIdx] = maxk(h_dist_mean,nColors);

    % select the hues that were farthest from their neighbors
    h = h(maxIdx);
    
    % rescale to fall in the range [0 1]
    h = h./(2*pi);

    % make our array of hsv colors 
    hsv_colors = [h s v];

    % convert to rgb
    pastelColors = hsv2rgb(hsv_colors);

    % show an image with tiles showing the colors
    showTiledColorSquares(pastelColors);

end