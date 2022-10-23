function BGSubtractedImages = QuickBGSubtraction(StackToBGSubtract,DiskRadius)
    Dimensions = size(StackToBGSubtract);
    NumberOfDimensions = length(Dimensions);
    BGSubtractedImages = zeros(Dimensions);
    switch NumberOfDimensions
        case 3
                for i = 1:size(StackToBGSubtract,3)
                    BG(:,:,i) = imopen(StackToBGSubtract(:,:,i),strel('disk',DiskRadius,0));
                    % subtract BG
                    BGSubtractedImages(:,:,i) = StackToBGSubtract(:,:,i) - BG(:,:,i);
                end
        case 2
            BG(:,:) = imopen(StackToBGSubtract(:,:),strel('disk',DiskRadius,0));
            % subtract BG
            BGSubtractedImages(:,:) = StackToBGSubtract(:,:) - BG(:,:);
    end
end