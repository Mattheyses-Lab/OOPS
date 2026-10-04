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

function BWout = removeBorderTouchers(BW, N)
% Remove 4-connected components that touch N or more image borders
% BW : logical (binary mask)
% N  : scalar integer (e.g., 1 removes anything touching >=1 border)

BW = logical(BW);
[h,w] = size(BW);

% get connected components
CC = bwconncomp(BW, 4);
if CC.NumObjects == 0
    BWout = BW;
    return
end

% get label matrix from components
L = labelmatrix(CC);

% helper: given a vector of labels (may include 0), return logical flag per label
edgeAny = @(lbls) accumarray(lbls(lbls>0), true, [CC.NumObjects 1], @any, false);

t = edgeAny(L(1,:).');   % top
b = edgeAny(L(h,:).');   % bottom
l = edgeAny(L(:,1));     % left
r = edgeAny(L(:,w));     % right

borderCount = t + b + l + r;          % 0..4 per component
removeLbl   = find(borderCount >= N);

BWout = BW;
BWout(ismember(L, removeLbl)) = false;
end