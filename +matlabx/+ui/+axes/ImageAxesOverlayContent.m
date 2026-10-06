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

classdef (Abstract) ImageAxesOverlayContent < handle
%IMAGEAXESOVERLAYCONTENT Application-owned passive graphics for ImageAxes.
%   Implement attach(parent,context) and detach(). Parent is a dedicated
%   hggroup; context.Host is the ImageAxes. Create non-pickable primitives
%   (HitTest='off', PickableParts='none') beneath parent. Query current image
%   dimensions from context.Host rather than retaining a size snapshot.
%
%   detach must tolerate repeated calls and partially completed attach calls.
%   Delete primitives or set their Parent=[] to preserve them for reuse.
%   The host deletes its group after detach, but never deletes this object.
%   Call host.mountOverlay/unmountOverlay to manage the relationship; calling
%   lifecycle methods directly does not update the host's bookkeeping.

    properties (Access={?matlabx.ui.axes.ImageAxes, ?matlabx.ui.axes.ImageAxesOverlayMount})
        Mount = []
    end

    methods (Abstract)
        attach(obj,parent,context)
        detach(obj)
    end

    methods
        function delete(obj)
            if ~isempty(obj.Mount) && isvalid(obj.Mount)
                obj.Mount.remove();
            end
        end
    end
end
