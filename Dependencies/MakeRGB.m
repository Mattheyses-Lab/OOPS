function [clr, clr_noblack] = MakeRGB
    disordered_thresh = 0.2;
    disordered_region = ceil(disordered_thresh*256);

    thing = jet(256);
    
    clr = zeros(256,3);

%     for i=2:disordered_region
%         clr(i,:) = thing(95,:);
%     end
    
    
    clr(2:disordered_region,:) = repmat(thing(95,:),disordered_region-1,1);
    
    length = 490;
    thing2 = jet(length);
    
    start = 256-disordered_region;
    clr(disordered_region:256,:) = thing2((length-start):length,:);
    temp = clr;
    temp(1,:) = thing(95,:);
    clr_noblack = temp;
end