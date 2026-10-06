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

classdef PassiveOverlayContent < matlabx.ui.axes.ImageAxesOverlayContent
    properties
        Graphic = []
        AttachCount = 0
        DetachCount = 0
        FailAttach = false
    end
    methods
        function attach(obj,parent,context)
            assert(isa(context.Host,'matlabx.ui.axes.ImageAxes'));
            obj.AttachCount = obj.AttachCount + 1;
            if isempty(obj.Graphic) || ~isgraphics(obj.Graphic)
                obj.Graphic = line('Parent',parent,'XData',[1 2 NaN 3 4], ...
                    'YData',[2 3 NaN 4 5],'HitTest','off','PickableParts','none');
            else
                obj.Graphic.Parent = parent;
            end
            if obj.FailAttach
                error('test:AttachFailed','Requested failure');
            end
        end
        function detach(obj)
            obj.DetachCount = obj.DetachCount + 1;
            if isgraphics(obj.Graphic)
                obj.Graphic.Parent = [];
            end
        end
        function delete(obj)
            % Real applications also dispose of any reusable primitives.
            if isgraphics(obj.Graphic)
                delete(obj.Graphic);
            end
        end
    end
end
