function [h,s,v] = makeHSVComponents(sz)

    rows = sz;
    columns = sz;
    midX = ceil(columns / 2);
    midY = ceil(rows / 2);
    % Construct v image as uniform.
    v = ones(rows, columns);
    s = zeros(size(v)); % Initialize.
    h = zeros(size(v)); % Initialize.
    % Construct the h image as going from 0 to 1 as the angle goes from 0 to 360.
    % Construct the S image going from 0 at the center to 1 at the edge.
    for c = 1 : columns
	    for r = 1 : rows
		    % Radius goes from 0 to 1 at edge, a little more in the corners.
		    radius = sqrt((r - midY)^2 + (c - midX)^2) / min([midX, midY]);
		    s(r, c) = min(1, radius); % Max out at 1

            % use atand instead of atan2d to change period of hue image from 360° to 180°
            % h(r, c) = atan2d((r - midY) , (c - midX));
		    h(r, c) = atan2d((r - midY),(c - midX));
	    end
    end
    % Flip h right to left.
    % don't flip, so we still start
    h = fliplr(mat2gray(h));
end