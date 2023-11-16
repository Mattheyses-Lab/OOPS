function testVoronoiMidline(ObjectArray)
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

nObjects = numel(ObjectArray);

tic
for i = 1:nObjects

    try
        I = ObjectArray(i).RestrictedPaddedMaskSubImage;

        % method 1
        %Midline = traceObjectVoronoiMidline(I);
    
        % method 2
        % seems to be faster (and more elegant) but need to account for circular input/smoothing of curves
        [G,edges,Midline] = getObjectMidline(I,...
            "DisplayResults",false,...
            "BoundaryInterpolation",true,...
            "BoundarySmoothing",true...
            );
    catch ME
        msg = ME.getReport();
        disp(['Error at object ',num2str(i),': ',msg]);
    end

end

elapsedTime = toc;

disp(['Elapsed time: ',num2str(elapsedTime)]);

end