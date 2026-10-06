% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [limits,className] = detectorRange(input)
%DETECTORRANGE Return the integer storage range of four-angle input planes.
% Floating-point storage does not encode detector bit depth, so LIMITS is
% empty for single and double inputs. CLASSNAME is still returned so callers
% can preserve the source representation where appropriate.

arguments
    input (1,1) matlabx.image.Image5D
end

% Canonical plane addresses identify the component metadata used by each angle.
locations = oops.io.fourAngleLocations(input);
components = input.Components;
classNames = string({components(locations(:,1)).Class});
classNames = unique(classNames,'stable');

if numel(classNames) ~= 1
    error('oops:analysis:MixedDetectorClasses', ...
        'All four polarization planes must use the same numeric class.');
end

% MATLAB storage class shared by the four detector planes.
className = classNames(1);

if startsWith(className,"uint")
    limits = [0 double(intmax(className))];
elseif startsWith(className,"int")
    limits = [double(intmin(className)) double(intmax(className))];
elseif className == "logical"
    limits = [0 1];
else
    limits = [];
end

end
