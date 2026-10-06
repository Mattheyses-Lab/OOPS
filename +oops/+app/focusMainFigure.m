% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function focusMainFigure()
%FOCUSMAINFIGURE Raise the existing OOPS window and make it visible.

% Existing OOPS main figure to raise above other windows.
fig = oops.app.getMainFigure();

if isempty(fig)
    return;
end

fig.Visible = 'on';
figure(fig);
drawnow;
end
