function cmap = custom_cmap(m,clrs)
% This function takes 2 inputs: m, the number of colors to output in the
% new colormap, and clrs, an nx3 array of rgb values
% ([r1,g1,b1;r2,g2,b2;...])
% The function outputs a custom colormap representing a gradient from the
% first color in clrs, to the last


sz = size(clrs,1);

if ~mod(sz,2)
    mid = sz/2;
    left = clrs(mid,:);
    right = clrs(mid+1,:);
    new = (left+right)./2;
    
    clrs = [clrs(1:mid,:);new;clrs(mid+1:sz,:)];
    
end

sz = size(clrs,1);


half2 = (sz-1)/2;

y = -half2:half2;

if mod(m,2)
    delta = min(1,(half2*2)/(m-1));
    half = (m-1)/2;
    yi = delta*(-half:half)';
else
    delta = min(1,(half2*2)/m);
    half = m/2;
    yi = delta*nonzeros(-half:half);
end
cmap = interp2(1:3,y,clrs,1:3,yi);

