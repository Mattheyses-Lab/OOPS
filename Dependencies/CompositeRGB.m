function Composite = CompositeRGB(IM1,map1,Limits1,IM2,map2,Limits2)
%CompositeRGB - Makes composite RGB image from 2 input grayscale images using colormaps and intensity ranges defined by user
%
% Syntax:  Composite = CompositeRGB(IM1,map1,Limits1,IM2,map2,Limits2)
%
% Inputs:
%    IM1 - First input image (m x n array, can be of type single, double, uint8, uint16)
%    map1 - LUT/colormap for first input image (256 x 3 double array, where each row is one RGB code, i.e. [R,G,B])
%    Limits1 - Output range of intensity values for IM1 (2-element row vector in the range [0 1])
%    IM2 - Second input image (m x n array, can be of type single, double, uint8, uint16)
%    map2 - LUT/colormap for second input image (256 x 3 double array, where each row is one RGB code, i.e. [R,G,B])
%    Limits2 - Output range of intensity values for IM2 (2-element row vector in the range [0 1])
%
% Outputs:
%    Composite - Composite RGB image (m x n x 3 array, type double)
%
% Notes:
%    For 'automated' intensity scaling, set Limits1 and Limits2 = [0 1] and uncomment the lines including stretchlim()
%
% Author: Will Dean
% Mattheyses Lab, University of Alabama at Birmingham
% email: willdean@uab.edu
% April 2022; Last revision: 29-July-2022

    % if images types are not double, convert them to double
    if ~isa(IM1,'double')
        IM1 = im2double(IM1);
    end

    if ~isa(IM2,'double')
        IM2 = im2double(IM2);
    end

    % scale each image to its maximum intensity
    IM1 = IM1./max(max(IM1));
    IM2 = IM2./max(max(IM2));

    % default gamma = 1, comment this line and add gamma to inputs for control over the gamma value
    gamma = 1;

    % scale intensity to fall within the range [0 255] and convert type to uint8
    IM1 = uint8(IM1*255);
    IM2 = uint8(IM2*255);
    
    % uncomment for 'automated' intensity scaling
%    Limits1 = stretchlim(IM1);
%    Limits2 = stretchlim(IM2);    
    
    % adjust image contrast using user inputs Limits1 and Limits2 (or stretchlim() if above lines are uncommented)
    IM1 = imadjust(IM1,Limits1,[0 1],gamma);
    IM2 = imadjust(IM2,Limits2,[0 1],gamma);

    % convert each of the indexed images to RGB images using the colormaps provided by user
    RGB1 = ind2rgb(IM1,map1);
    RGB2 = ind2rgb(IM2,map2);

    % make the composite by adding RGB images for each channel
    Composite = RGB1+RGB2;

end