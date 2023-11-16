function boundariesSmooth = smoothBoundaries2(I)
% function to test smoothdata2 function from R2023b
% given a binary image with a single object, calculates and plots smooth boundaries
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

boundaries = getPerfectBinaryBoundaries(I,"conn",8,"interpResolution",0.5,"method","tightest");

% boundaries split into x and y components
boundariesX = boundaries{1}(:,2);
boundariesY = boundaries{1}(:,1);

% number of points in the original boundary
nPoints = numel(boundariesX);

% determine the number of points to wrap onto the curve
wrapLength = floor(nPoints*0.5);

% "wrap" the curve onto itself
boundariesXWrap = [boundariesX(end-wrapLength:end-1); boundariesX(1:end); boundariesX(2:2+wrapLength)];
boundariesYWrap = [boundariesY(end-wrapLength:end-1); boundariesY(1:end); boundariesY(2:2+wrapLength)];

% determine window size from n points in data
windowSize = round(nPoints*0.15);

% smooth the wrapped curve (2nd output is window size)
[S,~] = smoothdata2([boundariesYWrap,boundariesXWrap],"sgolay",{windowSize,2});

% remove the wrapped ends
S = S(1+wrapLength:end-wrapLength,:);

imshow2(I);

hold on

plot(boundariesX,boundariesY,'LineStyle','-','LineWidth',2,'Color',[0 0 1]);

plot(S(:,2),S(:,1),'LineStyle','-','LineWidth',2,'Color',[1 0 0]);

end