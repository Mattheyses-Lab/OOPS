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

classdef ImageAxesOverlay < handle & matlab.mixin.SetGetExactNames
%IMAGEAXESOVERLAY Base class for graphics overlays hosted by ImageAxes.
%
%   ImageAxesOverlay is intentionally small. It owns identity, host/axes
%   attachment, C/Z/T applicability, common state flags, and graphics lifetime.
%   Concrete subclasses own geometry and appearance policy.
%
%   State flags such as Hovered, Selected, and Active are descriptive state.
%   Subclasses decide how those flags change graphics appearance in
%   updateAppearance().

    properties (SetAccess=protected)
        Host matlabx.ui.axes.ImageAxes
        TargetAxes matlab.ui.control.UIAxes
        ID (1,1) string = matlabx.utils.text.uniqueID()
        Type (1,1) string = ""
    end

    properties (SetObservable, AbortSet)
        Label (1,1) string = ""
        UserData = []

        C = "all"
        Z = "all"
        T = "all"

        Visible (1,1) matlab.lang.OnOffSwitchState = "on"
        ActivateOnCreate (1,1) logical = false
        Hovered (1,1) logical = false
        Selected (1,1) logical = false
        Active (1,1) logical = false
    end

    properties (SetAccess=protected)
        ViewVisible (1,1) matlab.lang.OnOffSwitchState = "on"
    end

    properties (Access=protected, Transient, NonCopyable)
        Graphics matlab.graphics.Graphics = matlab.graphics.Graphics.empty()
    end

    methods
        function obj = ImageAxesOverlay(host, opts)
        %IMAGEAXESOVERLAY Construct base overlay state and attach to host.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.ID (1,1) string = ""
                opts.Type (1,1) string = ""
                opts.TargetAxes = []
                opts.Label (1,1) string = ""
                opts.UserData = []
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ActivateOnCreate (1,1) logical = false
            end

            obj.Host = host;
            obj.Type = opts.Type;

            if strlength(opts.ID) > 0
                obj.ID = opts.ID;
            end

            if isempty(opts.TargetAxes)
                obj.TargetAxes = host.getAxes();
            else
                obj.TargetAxes = opts.TargetAxes;
            end

            obj.Label = opts.Label;
            obj.UserData = opts.UserData;
            obj.C = obj.normalizeIndexSpec(opts.C);
            obj.Z = obj.normalizeIndexSpec(opts.Z);
            obj.T = obj.normalizeIndexSpec(opts.T);
            obj.Visible = opts.Visible;
            obj.ActivateOnCreate = opts.ActivateOnCreate;
        end

        function delete(obj)
        %DELETE Delete graphics owned by this overlay.
            for k = 1:numel(obj)
                obj(k).deleteGraphics();
            end
        end

        function set.Visible(obj, value)
        %SET.VISIBLE Update visibility for all graphics handles.
            obj.Visible = value;
            obj.updateVisibility();
        end

        function set.Hovered(obj, value)
        %SET.HOVERED Update hover state and appearance.
            obj.Hovered = value;
            obj.updateAppearance();
        end

        function set.Selected(obj, value)
        %SET.SELECTED Update selection state and appearance.
            obj.Selected = value;
            obj.updateAppearance();
        end

        function set.Active(obj, value)
        %SET.ACTIVE Update active state and appearance.
            obj.Active = value;
            obj.updateAppearance();
        end

        function tf = appliesToView(obj, c, z, t, showComposite)
        %APPLIESTOVIEW True when this overlay belongs in the current view.
            if showComposite
                cOk = true;
            else
                cOk = obj.matchesIndex(obj.C, c);
            end

            tf = cOk ...
                && obj.matchesIndex(obj.Z, z) ...
                && obj.matchesIndex(obj.T, t);
        end

        function tf = containsGraphics(obj, h)
        %CONTAINSGRAPHICS True when h is one of this overlay's graphics.
            tf = false;
            if isempty(h) || isempty(obj.Graphics)
                return
            end

            G = obj.Graphics(isgraphics(obj.Graphics));
            tf = any(G == h);
        end

        function refresh(obj)
        %REFRESH Reapply geometry, appearance, and visibility.
            obj.updateGeometry();
            obj.updateAppearance();
            obj.updateVisibility();
        end

        function setViewVisible(obj, value)
        %SETVIEWVISIBLE Set manager-controlled C/Z/T visibility.
            obj.ViewVisible = value;
            obj.updateVisibility();
        end

        function tf = isInsideRectangle(~, ~)
        %ISINSIDERECTANGLE True when overlay selection point lies in rectangle.
        %
        %   Subclasses override this for rectangle/lasso-style selection.
        %   RECT is [xmin xmax ymin ymax] in image data coordinates.
            tf = false;
        end
    end

    methods (Access=protected)
        function registerGraphics(obj, h)
        %REGISTERGRAPHICS Track graphics handles owned by this overlay.
            h = h(isgraphics(h));
            obj.Graphics = [obj.Graphics(:); h(:)];

            for i = 1:numel(h)
                setappdata(h(i), "matlabxOverlayID", obj.ID);
                setappdata(h(i), "matlabxOverlayType", obj.Type);
            end
        end

        function deleteGraphics(obj)
        %DELETEGRAPHICS Delete valid graphics handles and forget them.
            if isempty(obj.Graphics)
                return
            end

            h = obj.Graphics(isgraphics(obj.Graphics));
            if ~isempty(h)
                delete(h);
            end
            obj.Graphics = matlab.graphics.Graphics.empty();
        end

        function updateVisibility(obj)
        %UPDATEVISIBILITY Apply overlay Visible state to graphics handles.
            if isempty(obj.Graphics)
                return
            end

            h = obj.Graphics(isgraphics(obj.Graphics));
            if ~isempty(h)
                effectiveVisible = obj.Visible == "on" && obj.ViewVisible == "on";
                set(h, "Visible", matlab.lang.OnOffSwitchState(effectiveVisible));
            end
        end
    end

    methods
        function updateGeometry(~)
        %UPDATEGEOMETRY Subclasses update geometry in this hook.
        end

        function updateAppearance(~)
        %UPDATEAPPEARANCE Subclasses update visual state in this hook.
        end
    end

    methods (Static, Access=protected)
        function value = normalizeIndexSpec(value)
        %NORMALIZEINDEXSPEC Normalize C/Z/T selectors to "all" or row vector.
            if ischar(value) || isstring(value)
                value = string(value);
                if isscalar(value) && strcmpi(value, "all")
                    value = "all";
                    return
                end
            end

            value = double(value);
            value = value(:).';
        end

        function tf = matchesIndex(spec, idx)
        %MATCHESINDEX True when spec is "all" or contains idx.
            if ischar(spec) || isstring(spec)
                tf = isscalar(string(spec)) && strcmpi(string(spec), "all");
            else
                tf = any(spec == idx);
            end
        end
    end
end
