function showTiledColorSquares(colors)
% colors (nx3 double) - matrix of n colors

nColors = size(colors,1);

colorSquares = cell(nColors,1);

for i = 1:nColors
    colorSquares{i} = makeRGBColorSquare(colors(i,:),25);
end

tiledColorSquares = imtile(colorSquares,...
    'ThumbnailSize',[25 25],...
    'BorderSize',1,...
    'BackgroundColor',[0 0 0],...
    'GridSize',[NaN NaN]);

imshow2(tiledColorSquares);

end