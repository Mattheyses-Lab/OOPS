function averageAzimuthImage = getAverageAzimuthImage(AzimuthImage)

% define function for sliding window
fun = @(x) getAzimuthAverage(x(:));
% apply fun to image with sliding window using nlfilter2
averageAzimuthImage = nlfilter2(AzimuthImage,3,fun);

end

