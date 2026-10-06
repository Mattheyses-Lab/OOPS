% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tf = hasMainFigure()
%HASMAINFIGURE Report whether the OOPS main figure exists.

% Whether a registered main OOPS figure currently exists.
tf = ~isempty(oops.app.getMainFigure());
end
