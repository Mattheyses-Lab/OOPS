% OOPS - MATLAB app for desmosomal plaque protein analysis.
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

function setDeveloperMode(tf, opts)
%SETDEVELOPERMODE Enable or disable developer-oriented runtime behavior.
%
%   oops.runtime.setDeveloperMode(TF) stores the DeveloperMode
%   preference and reapplies logging policy to the active logger, if one
%   exists. For now, developer mode only changes logging defaults.

arguments
    tf (1,1) logical
    opts.ApplyLogging (1,1) logical = true
    opts.Verbose (1,1) logical = true
end

% Developer-mode preference before this update, used to detect an actual change.
oldValue = oops.runtime.isDeveloperMode();
oops.Preferences.set("DeveloperMode", tf);

if opts.ApplyLogging && oops.Log.exists()
    oops.Log.applyConfigFromPreferences();

    if opts.Verbose && oldValue ~= tf

        % Readable mode label included in the informational log message.
        state = "disabled";

        if tf
            state = "enabled";
        end

        oops.Log.INFO("Developer mode " + state + ".");
    end

end

end
