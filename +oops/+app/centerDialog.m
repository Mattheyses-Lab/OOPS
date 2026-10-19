% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function centerDialog(dialog)
%CENTERDIALOG Place an OOPS-owned dialog at the center of the active screen.

arguments
    dialog (1,1) matlab.ui.Figure
end

movegui(dialog,'center');
end
