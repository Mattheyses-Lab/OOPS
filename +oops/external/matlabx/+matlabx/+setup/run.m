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

function run()
%RUN  Performs setup actions for a new installation of matlabx

matlabx.Log.INFO("Setting up matlabx...");

% --- SEARCH PATH ---
matlabx.Log.INFO("Setting up matlabx search path...");
try matlabx.setup.searchPath(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

% --- BIO-FORMATS ---
matlabx.Log.INFO("Setting up Bio-Formats...");
try matlabx.setup.bioFormats(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

% --- UI CALIBRATION ---
matlabx.Log.INFO("Setting up UI calibration...");
try matlabx.setup.uiCalibration(); catch ME, matlabx.Log.ERROR(ME); rethrow(ME); end

% save path
savepath();

% indicate success
matlabx.Log.INFO("matlabx setup completed successfully.");

end