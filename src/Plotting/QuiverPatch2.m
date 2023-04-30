function hPatch = QuiverPatch2(hAx,...
    x,...
    y,...
    theta,...
    rho,...
    ColorMode,...
    Colormap,...
    LineWidth,...
    LineAlpha,...
    LineScale)

%% NEW METHOD

    nLines = length(x);

    % get cartesian coordinates of line endpoints
    [u,v] = pol2cart(theta,rho);
    % transpose each set of start/endpoint coordinates
    x = x';
    y = y';
    u = u';
    v = v';
    % scaling factor of each 'half-line'
    HalfLineScale = LineScale/2;
    % x and y coordinates for each 'half-line'
    X = [x+HalfLineScale*u;x-HalfLineScale*u];
    Y = [y-HalfLineScale*v;y+HalfLineScale*v];

    % 'bin' the x and y coords if desired,
    %   sometimes useful if plotting many lines
    X = X(:,1:1:end);
    Y = Y(:,1:1:end);
    rho = rho(1:1:end);
    theta = theta(1:1:end);
    % preallocate line colors array
    PatchColors = zeros(nLines,3);
    
    % calculate colors for each line based on ColorMode
    switch ColorMode
        case 'Magnitude'
            % number of colors in the map (for indexing)
            nColors = length(Colormap);
            % determine the colormap idx of each line based on its pixel's OF (range 0-1)
            ColorIdx = round(rho.*(nColors-1))+1;
            % fill the array with colors based on idxs in ColorIdx
            PatchColors(:,:) = Colormap(ColorIdx,:);
        case 'Direction'
            % determine how many colors in the full map
            nColors = length(Colormap);
            % get the region of the circular map from
            % -pi/2 to pi/2 (the range of our values)
            % (pi/2)/(2pi) = 0.25
            % (3pi/2)/(2pi) = 0.75
            halfcircmap = Colormap(0.25*nColors:0.75*nColors,:);
            % how many colors in the truncated map
            nColors = length(halfcircmap);
            % normalize our theta values and convert to idxs
            % theta is in the range [-pi/2,pi/2]...
            % (theta+pi/2)./(pi) will scale theta to 0-1...
            % thus: 0 -> -pi/2, 1 -> pi/2
            ColorIdxsNorm = round(((theta+pi/2)./(pi))*(nColors-1))+1;
            % fill the array with colors based on idxs in ColorIdxsNorm
            PatchColors(:,:) = halfcircmap(ColorIdxsNorm,:);
        case 'Mono'
            MonoColor = [1 1 1];
            % replicate the MonoColor nLines times since each line is the same color
            PatchColors = repmat(MonoColor,nLines,1);
    end

C = Interleave2DArrays(PatchColors,nan(size(PatchColors)),'row');

hPatch = patch(hAx,"XData",X,"YData",Y,"FaceVertexCData",C,"EdgeColor","Flat");
hPatch.HitTest = 'Off';
hPatch.PickableParts = 'None';
hPatch.LineWidth = LineWidth;
hPatch.EdgeAlpha = LineAlpha;

end