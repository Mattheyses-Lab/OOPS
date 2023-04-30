%% colormap_from_RGB.m
%% Author Info
% Author: William F. Dean
% University of Alabama at Birmingham
% Department of Cell, Developmental, and Integrative Biology
% Lab of Dr. Alexa Mattheyses
% Last Updated: 20210503

%% OVERVIEW AND USAGE
%% Overview
%   This function was written to generate custom colormaps representing a
%   gradient between two user-defined colors 
%   Inputs: RGB_in1 & RGB_in2, both 3-element vectors containing RGB values
%   in either uint8 format (values 0-255) or as normalized doubles (values
%   0.0 to 1.0)
%   Outputs: map_out, a 256x3 matrix with values between 0.0 and 1.0,
%   inclusive, to be used as a colormap

%% Example Usage
%   % generating a colormap that transitions from blue to yellow
%   my_rgb_color1 = [0,0,255]   % RGB values for Blue
%   my_rgb_color2 = [255,255,0] % RGB values for Yellow
%   blue2yellow_map = colormap_from_RGB(my_rgb_color1,my_rgb_color2)


function [map1_out,map2_out] = colormap_from_RGB(RGB_in1, RGB_in2)

    if find(RGB_in1>1) | find(RGB_in2>1)
        RGB_format = 'int8'
    else
        RGB_format = 'double_norm'
    end
    
    switch RGB_format
        case 'double_norm'
            r1 = RGB_in1(1)*255;
            g1 = RGB_in1(2)*255;
            b1 = RGB_in1(3)*255;

            r2 = RGB_in2(1)*255;
            g2 = RGB_in2(2)*255;
            b2 = RGB_in2(3)*255;
        case 'int8'
            r1 = RGB_in1(1);
            g1 = RGB_in1(2);
            b1 = RGB_in1(3);

            r2 = RGB_in2(1);
            g2 = RGB_in2(2);
            b2 = RGB_in2(3);            
    end

    %% Map Type 1
    %  each channel is a linearly spaced vector from RGB_in1 to RGB_in2
    
    r3 = linspace(r1,r2,256)';
    g3 = linspace(g1,g2,256)';
    b3 = linspace(b1,b2,256)';
    
    r3 = r3/255;
    g3 = g3/255;
    b3 = b3/255;

    map1_out = [r3,g3,b3];
    
    %% Map Type Two
    %  Each channel represents the normalized average between RGB_in1
    %  and RGB_in2
    r1_array = linspace(r1,0,256)';
    g1_array = linspace(g1,0,256)';
    b1_array = linspace(b1,0,256)';     
    
    
    r2_array = linspace(0,r2,256)';
    g2_array = linspace(0,g2,256)';
    b2_array = linspace(0,b2,256)';
    
    r4 = (r1_array+r2_array)/2;
    g4 = (g1_array+g2_array)/2;
    b4 = (b1_array+b2_array)/2;
    
    map2_out = [r4,g4,b4];
    
    if max(max(map2_out)) > 1
        map2_out = map2_out./max(max(map2_out));
    end
    

    return
end