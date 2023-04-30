function diffs = getAzimuthDiff(ref,check)
% get the smallest angle between intersecting azimuths, 
% assuming opposite directions are equivalent and lines intersect at the origin
% (i.e. theta = 30° = -150°)
% negative difference indicates CW rotation
% function assumes input is in radians, output will be in degrees

    % indicates we need to add a negative sign after finding angle between azimuths
    negDiff = (check-ref)<0;
    % find the angle between the two azimuths
    diff = acos(cos(ref-check));
    diff = rad2deg(diff);
    % there are two possible angles, we want the one that is less than 90 degrees
    diffAdjust = diff;
    diffAdjust(diffAdjust>90) = 180-diffAdjust(diffAdjust>90);
    % find the angles we adjusted so we can flip their signs
    diffAdjusted = diffAdjust~=diff;
    % only want to flip if XOR(negdiff,diff_2_flip) evaluates true
    flipSign = xor(negDiff,diffAdjusted);
    % adjust the signs
    diffAdjust(flipSign) = diffAdjust(flipSign)*-1;
    
    diffs = diffAdjust;

end