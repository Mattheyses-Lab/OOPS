function circBar = circularColorbarDemo()

    imageSize = 1000;


    [H,~,~] = makeHSVComponents(imageSize);

    [~,hAx] = imshow3(H);

    hAx.Colormap = hsv;

    hFig = hAx.Parent;
    hFig.WindowStyle = 'alwaysontop';




    % calculate center and radius for lower right position
    padding = 0.025*imageSize;
    % inner and outer radii
    outerRadius = 0.1*imageSize;
    innerRadius = outerRadius/(pi/2);
    % center coordinates
    centerX = imageSize-outerRadius-padding;
    centerY = centerX;

    circBar = circularColorbar(hAx, ...
        'centerX',centerX, ...
        'centerY',centerY, ...
        'Colormap',vertcat(hsv,hsv), ...
        'innerRadius',innerRadius, ...
        'outerRadius',outerRadius, ...
        'nRepeats',1 ...
        );

    % fH = uifigure(...
    %     'HandleVisibility','on',...
    %     'WindowStyle','alwaysontop');
    % 
    % ax = uiaxes(fH);
    % 
    % circBar = circularColorbar(ax);


end