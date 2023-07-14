function hImg = imshow2(I)
% Author: Will Dean
% uses imshow() with some additional settings that are helpful:
% always opens a new figure by default
% set that figure to a specific size, particularly useful for small images
% make the image fill the window as much as possible while maintaining aspect ratio

    fH = figure('Visible','off');

    hImg = imshow(I);

    hAx = hImg.Parent;
    hAx.Units = 'normalized';
    hAx.InnerPosition = [0 0 1 1];
    hAx.Visible = 'off';

    fH.Position = [200 200 800 800];

    movegui(fH,'center');

    fH.Visible = 'on';

end