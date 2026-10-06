% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function fig = getMainFigure()
%GETMAINFIGURE Return the live OOPS main figure, or an empty figure array.

% Registered main figure, or an empty figure array when OOPS is not open.
fig = findall(groot,'Type','figure','Tag',oops.Info.MainFigureTag);

if isempty(fig)
    fig = matlab.ui.Figure.empty(0,1);
else
    fig = fig(1);
end

end
