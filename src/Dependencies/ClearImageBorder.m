function ImageOut = ClearImageBorder(ImageIn,n)
    % sets all pixels n pixels from the border to 0
    ImageOut = ImageIn;
    [rows,cols] = size(ImageOut);
    ImageOut(1:n,1:end) = 0;
    ImageOut(1:end,1:n) = 0;
    ImageOut(rows-(n-1):end,1:end) = 0;
    ImageOut(1:end,cols-(n-1):end) = 0;
end