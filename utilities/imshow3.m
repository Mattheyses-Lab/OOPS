function [hImg,hAx] = imshow3(I)
% Author: Will Dean

    % create the uifigure to hold our image axes
    fH = uifigure('Visible','off','HandleVisibility','on','AutoResizeChildren','Off');
    fH.Position = [50 50 800 800];

    % create an axes to hold our image object
    hAx = uiaxes(fH,"InnerPosition",[0 0 1 1],...
        "Units","normalized",...
        "Visible","off");

    % call imshow to display the image
    hImg = imshow(I,'Parent',hAx);

    % restore some props potentially screwed up by imshow()
    hAx.YDir = 'reverse';
    hAx.PlotBoxAspectRatio = [1 1 1];
    hAx.InnerPosition = [0 0 1 1];
    
    % show the figure
    fH.Visible = 'on';
end