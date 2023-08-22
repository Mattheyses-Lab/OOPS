function HSV = makeHSVSpecial(H,S,V)
% makeHSVSpecial  Make an "HSV" image (in RGB colorspace) from H, S, and V inputs
% assumes H is in the range [0 1] (representing angular values in the range [0 pi])

% concatenate along the third dimension and convert to RGB
HSV = hsv2rgb(cat(3,H,S,V));

end