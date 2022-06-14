function Scaled = Scale0To1(UnscaledImage)

    sz = size(UnscaledImage);
    ndim = length(sz);
    
    if ndim > 3
        error('Dimensions > 3 not supported!');
    end
    
    switch ndim
        
        case 3
            max_value = max(max(max(UnscaledImage)));
            min_value = min(min(min(UnscaledImage)));
        case 2
            max_value = max(max(UnscaledImage));
            min_value = min(min(UnscaledImage));            
        case 1
            max_value = max(UnscaledImage);
            min_value = min(UnscaledImage); 
    end

    Scaled = zeros(sz);

    Scaled = (UnscaledImage-min_value)./(max_value-min_value);

end