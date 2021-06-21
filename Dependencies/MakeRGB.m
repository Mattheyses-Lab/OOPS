function [clr, clr_noblack] = MakeRGB
    disordered_thresh = 0.2;
    disordered_region = ceil(disordered_thresh/(1/256));

    thing = jet(256);
    
    clr = zeros(256,3);
    clr(1,:) = [0,0,0];

    for i=2:disordered_region
        clr(i,:) = thing(95,:);
    end
    length = 490;
    thing2 = jet(length);
    
    start = 256-disordered_region;
    clr(disordered_region:256,:) = thing2((length-start):length,:);
    temp = clr;
    temp(1,:) = thing(95,:);
    clr_noblack = temp;
end