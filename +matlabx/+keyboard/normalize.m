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

% function hk = normalize(key, character, modifier)
% % matlabx.keyboard.normalize
% % Normalize MATLAB key event fields into canonical hotkey string.
% %
% % Example outputs:
% %   "a"
% %   "shift+a"
% %   "ctrl+z"
% %   "ctrl+alt+rightarrow"
% 
%     % normalize inputs
%     key = lower(string(key));
%     character = lower(string(character));
%     modifier = lower(string(modifier));
% 
%     % MATLAB uses "control", normalize to "ctrl"
%     modifier(modifier == "control") = "ctrl";
% 
%     % canonical modifier order
%     order = ["shift","ctrl","alt","meta"];
% 
%     if ~isempty(modifier)
%         modifier = intersect(order, modifier, 'stable');
%     end
% 
%     % determine base key
%     base = key;
% 
%     % sometimes key is empty but character exists
%     if strlength(base) == 0 && strlength(character) > 0
%         base = character;
%     end
% 
%     % build output
%     parts = [modifier base];
%     parts(parts=="") = [];
% 
%     if isempty(parts)
%         hk = "";
%     else
%         hk = strjoin(parts, "+");
%     end
% end

function hk = normalize(key, character, modifier)
% matlabx.keyboard.normalize
% Normalize MATLAB key event fields into canonical hotkey string.

    % Normalize inputs
    key = lower(string(key));
    character = lower(string(character));
    modifier = lower(string(modifier));

    % Remove empties
    key(key == "") = [];
    character(character == "") = [];
    modifier(modifier == "") = [];

    % Canonicalize names
    modifier(modifier == "command") = "meta";
    modifier(modifier == "option") = "alt";

    key(key == "ctrl") = "control";
    key(key == "command") = "meta";
    key(key == "option") = "alt";

    % Canonical modifier order
    order = ["shift","control","alt","meta"];

    % Normalize modifier list
    modifier = intersect(order, unique(modifier, "stable"), "stable");

    % Determine base key
    if ~isempty(key)
        base = key(1);
    elseif ~isempty(character)
        base = character(1);
    else
        base = "";
    end

    % If the key itself is just a modifier, fold it into modifiers
    if any(base == order)
        if ~any(modifier == base)
            modifier(end+1) = base;
            modifier = intersect(order, modifier, "stable");
        end
        base = "";
    end

    % Build output
    parts = [modifier, base];
    parts(parts == "") = [];

    if isempty(parts)
        hk = "";
    else
        hk = strjoin(parts, "+");
    end
end