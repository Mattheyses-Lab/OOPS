% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function [XData,YData,CData] = ring(innerRadius,outerRadius,nWedges)
%RING Return XData, YData, and CData for trapezoidal patches forming a circular ring
%
%   Notes: Uses hsv colormap by default

    % make hsv map with nWedges colors, copy the first color to the end
    cmap = hsv(nWedges);
    cmap(end+1,:) = cmap(1,:);

    % get the angle of each trapezoid leg
    theta = linspace(0,360,nWedges+1);

    % get coordinates for the vertices of the longer bases of the trapezoids
    x1 = outerRadius*cosd(theta);
    y1 = outerRadius*sind(theta);

    % get coordinates for the vertices of the shorter bases of the trapezoids
    x2 = innerRadius*cosd(theta);
    y2 = innerRadius*sind(theta);

    trapX = [ ...
        x1(1:nWedges); ...   % outer circle, vertex 1
        x2(1:nWedges); ...   % inner circle, vertex 1
        x2(2:nWedges+1); ... % inner circle, vertex 2
        x1(2:nWedges+1) ...  % outer circle, vertex 2
        ];

    trapY = [...
        y1(1:nWedges); ...   % outer circle, vertex 1
        y2(1:nWedges); ...   % inner circle, vertex 1
        y2(2:nWedges+1); ... % inner circle, vertex 2
        y1(2:nWedges+1) ...  % outer circle, vertex 2
        ];

    trapC = [ ...
        1:nWedges; ...       % outer circle, vertex 1 color idx
        1:nWedges; ...       % inner circle, vertex 1 color idx
        2:nWedges+1; ...     % inner circle, vertex 2 color idx
        2:nWedges+1 ...      % outer circle, vertex 1 color idx
        ];

    % convert color idxs to column vector
    trapC = trapC(:);

    % extract colors
    CData = cmap(trapC,:);

    XData = trapX;
    YData = trapY;

end