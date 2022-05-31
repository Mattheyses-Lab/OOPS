function Composite = CompositeRGB(IM1,map1,Limits1,IM2,map2,Limits2)

    gamma = 1;

    IM1 = uint8(IM1*255);
    IM2 = uint8(IM2*255);
    
%     Limits1 = [0 1];
%     Limits2 = [0 1];
    
%     Limits1 = stretchlim(IM1);
%     Limits2 = stretchlim(IM2);    
    
    
    IM1 = imadjust(IM1,Limits1,[0 1],gamma);
    IM2 = imadjust(IM2,Limits2,[0 1],gamma);

    RGB1 = ind2rgb(IM1,map1);
    RGB2 = ind2rgb(IM2,map2);

    Composite = RGB1+RGB2;

end