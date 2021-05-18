function [L,BoundaryPixels4,BoundaryPixels8,bwObjectProperties,nObjects] = ObjectDetection3(bw)
%Create Objects from black and white mask, return Label Matrix and object
%properties struct
    % L = Label matrix where each 4-connected object in binary image is 
    % replaced by a unique number
    L = bwlabel(bw,4);
    
    BoundaryPixels4 = bwboundaries(bw,4);
    BoundaryPixels8 = bwboundaries(bw,8);
    
    bwObjectProperties = regionprops(logical(L),'all');
    
    % number of objects
    nObjects = length(bwObjectProperties);
    
    
end