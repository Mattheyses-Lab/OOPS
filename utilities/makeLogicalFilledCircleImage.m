function circlePixels = makeLogicalFilledCircleImage(centerX,centerY,radius,height,width)


    %[imageSizeY,imageSizeX] = size(imageIn);
    [columnsInImage,rowsInImage] = meshgrid(1:width, 1:height);

    % create 2D logical array containing a circle at the specified location
    circlePixels = (rowsInImage-centerY).^2 + (columnsInImage-centerX).^2 <= radius.^2;

%     figure()
%     % display it
%     imshow(circlePixels);

end