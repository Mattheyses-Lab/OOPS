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

classdef ImageAxesOverlayMount < handle
%IMAGEAXESOVERLAYMOUNT Host-owned relationship with reusable overlay content.
%   Obtain via ImageAxes.mountOverlay. remove/delete detaches the content,
%   releases the host's group, and invalidates this mount, not the content.

    properties (SetAccess=private)
        Content
    end
    properties (Dependent)
        Visible (1,1) matlab.lang.OnOffSwitchState
    end
    properties (Access=private)
        Host
        Group
        Visible_ (1,1) matlab.lang.OnOffSwitchState = "on"
        Removing = false
    end

    methods (Access=?matlabx.ui.axes.ImageAxes)
        function obj = ImageAxesOverlayMount(host,content,parent)
            obj.Host = host;
            obj.Content = content;
            obj.Group = hggroup(parent,'Tag','ApplicationOverlayMount', ...
                'HitTest','off','PickableParts','none');
        end

        function attachContent(obj)
            obj.Content.attach(obj.Group,struct('Host',obj.Host));
        end
    end

    methods
        function value = get.Visible(obj)
            value = obj.Visible_;
        end

        function set.Visible(obj,value)
            obj.Visible_ = value;
            if ~isempty(obj.Group) && isgraphics(obj.Group)
                obj.Group.Visible = value;
            end
        end

        function remove(obj)
            delete(obj);
        end

        function delete(obj)
            if obj.Removing
                return;
            end
            obj.Removing = true;
            % Clear relationship state before calling application code. This
            % makes reentrant removal harmless and avoids stale registrations.
            content = obj.Content;
            if ~isempty(content) && isvalid(content)
                content.Mount = [];
            end
            if ~isempty(obj.Host) && isvalid(obj.Host)
                obj.Host.releaseOverlayMount(obj);
            end
            cleanup = onCleanup(@() obj.deleteGroup()); %#ok<NASGU>
            if ~isempty(content) && isvalid(content)
                content.detach();
            end
        end
    end

    methods (Access=private)
        function deleteGroup(obj)
            if ~isempty(obj.Group) && isgraphics(obj.Group)
                delete(obj.Group);
            end
        end
    end
end
