% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function updateProgress(sink,message,value)
%UPDATEPROGRESS Best-effort dialog or headless callback updates, like DesmoSTORM.
% A callback receives (message, fraction). A UI sink exposes Message and Value.

if isempty(sink)
    return;
end

try

    if isa(sink,'function_handle')
        sink(string(message),value);
    else
        sink.Message = message;

        if ~isempty(value)
            sink.Indeterminate = 'off';
            sink.Value = value;
        else
            sink.Indeterminate = 'on';
        end

        drawnow limitrate;
    end

catch ME
    oops.Log.DEBUG("Progress sink update failed: " + string(ME.message));
end
end
