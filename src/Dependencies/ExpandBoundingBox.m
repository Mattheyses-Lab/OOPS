function BoundingBox = ExpandBoundingBox(BoundingBox,Padding)
    % inputs:
    %   BoundingBox: coordinates of a bounding box [x,y,width,height]
    %   Padding: number of pixels to add to each side of the bounding box
    
    BoundingBox(1) = BoundingBox(1)-Padding;
    BoundingBox(2) = BoundingBox(2)-Padding;
    BoundingBox(3) = BoundingBox(3)+2*Padding;
    BoundingBox(4) = BoundingBox(4)+2*Padding;

end