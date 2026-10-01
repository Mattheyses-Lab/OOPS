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

function hk = hotkey(key, opts)
%HOTKEY Build a normalized hotkey string for declarations.
%
%   hk = matlabx.keyboard.hotkey("z", "Modifiers", ["shift","meta"])
%   returns "shift+meta+z". Use this helper when declaring tool hotkeys so
%   callers do not need to remember the exact normalized string format.

    arguments
        key (1,1) string
        opts.Modifiers (1,:) string = string.empty(1,0)
    end

    hk = matlabx.keyboard.normalize(key, "", opts.Modifiers);
end
