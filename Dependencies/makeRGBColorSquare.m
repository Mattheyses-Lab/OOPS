function ColorSquare = makeRGBColorSquare(Color,size)

    ColorSquare = zeros(1,1,3);
    ColorSquare(1,1,:) = Color;
    ColorSquare = repmat(ColorSquare,[size,size]);

end