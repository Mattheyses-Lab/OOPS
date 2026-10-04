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

classdef RectangleSelect < matlabx.ui.axes.AxesTool
%RECTANGLESELECT Select overlays by dragging a temporary rectangle.
%
%   RectangleSelect is a transient selection tool. It does not create
%   persistent overlays; it previews a desktop-style marquee rectangle while
%   dragging, then asks ImageAxesOverlayManager which overlays fall inside.
%
%   Selection policy:
%       click-drag          replace selection for TargetTypes
%       shift-drag          toggle enclosed overlays in the selection
%       alt-drag            remove enclosed overlays from selection

    properties
        TargetTypes (1,:) string = "all"
        MinimumDragDistance (1,1) double {mustBeNonnegative} = 2

        RectangleFaceColor = [0.2 0.55 1]
        RectangleFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(RectangleFaceAlpha,0), mustBeLessThanOrEqual(RectangleFaceAlpha,1)} = 0.12
        RectangleEdgeColor = [0.2 0.55 1]
        RectangleLineWidth (1,1) double {mustBePositive} = 1
        RectangleLineStyle (1,:) char = '-'
    end

    properties (Access=private)
        StartPoint (1,2) double = [NaN NaN]
        CurrentPoint (1,2) double = [NaN NaN]
        SelectionMode (1,1) string = "replace"
    end

    properties (Access=private, Transient, NonCopyable)
        SelectionPatch matlab.graphics.primitive.Patch = matlab.graphics.primitive.Patch.empty()
    end

    methods
        function obj = RectangleSelect(host)
        %RECTANGLESELECT Create the rectangle-selection tool.
            obj@matlabx.ui.axes.AxesTool(host, "RectangleSelect", ...
                'Tooltip', 'Rectangle selection', ...
                'AxesType', "image", ...
                'Icon', matlabx.internal.Paths.icons('Selection.png'), ...
                'Priority', 2, ...
                'IsExclusive', true, ...
                'InterceptsDown', true, ...
                'InterceptsMove', true, ...
                'InterceptsUp', true);
        end

        function onInstall(obj)
        %ONINSTALL Register tool-owned drawing mode.
            obj.addMode('DrawingSelectionRectangle');
        end

        function onUninstall(obj)
        %ONUNINSTALL Remove mode and transient graphics.
            obj.removeMode('DrawingSelectionRectangle');
            obj.deleteSelectionPatch();
        end

        function contributeContextMenu(obj, menu)
        %CONTRIBUTECONTEXTMENU Add RectangleSelect help to the context menu.
            menu.addSubmenu( ...
                "RectangleSelect", ...
                "Rectangle Select", ...
                "Owner", obj);

            menu.addItem( ...
                "RectangleSelect.Help", ...
                "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                "Parent", "RectangleSelect", ...
                "Owner", obj);
        end
    end

    %% Help
    methods
        function summary = getHelpSummary(~)
        %GETHELPSUMMARY Return a one-line RectangleSelect description.
            summary = "Select overlays by dragging a temporary rectangle.";
        end

        function usage = getUsageHelp(~)
        %GETUSAGEHELP Return short RectangleSelect usage notes.
            usage = [ ...
                "Enable Rectangle Select and drag over overlays to select them."; ...
                "The rectangle is temporary and disappears on mouse release."; ...
                "Overlays decide their own selection point, such as point position, box center, or line midpoint."];
        end

        function B = getBindingHelp(obj)
        %GETBINDINGHELP Return RectangleSelect click binding descriptions.
            B = struct( ...
                "ToggleTool", obj.ToggleHotkey, ...
                "ReplaceSelection", "click-drag", ...
                "ToggleSelection", "shift+extendclick-drag", ...
                "RemoveFromSelection", "alt+click-drag");
        end

        function notes = getNotesHelp(~)
        %GETNOTESHELP Return additional RectangleSelect behavior notes.
            notes = [ ...
                "TargetTypes can be ""all"" or a string array such as [""Point"",""Box""]."; ...
                "Small drags below MinimumDragDistance are ignored."];
        end
    end

    %% Active event hooks
    methods
        function onDown(obj, E)
        %ONDOWN Start a marquee rectangle from a supported mouse gesture.
            switch E.MouseChord
                case "click"
                    obj.SelectionMode = "replace";
                case "shift+extendclick"
                    obj.SelectionMode = "toggle";
                case "alt+click"
                    obj.SelectionMode = "remove";
                otherwise
                    return
            end

            xy = obj.Host.cursorPosition;
            if isempty(xy)
                return
            end

            obj.StartPoint = xy;
            obj.CurrentPoint = xy;
            obj.setMode('DrawingSelectionRectangle', true);
            obj.createSelectionPatch();
            obj.updateSelectionPatch();
            E.stop();
        end

        function onMove(obj, E)
        %ONMOVE Update the temporary rectangle while dragging.
            if ~obj.Mode.DrawingSelectionRectangle
                return
            end

            xy = obj.Host.cursorPosition;
            if isempty(xy)
                return
            end

            obj.CurrentPoint = xy;
            obj.updateSelectionPatch();
            E.stop();
        end

        function onUp(obj, E)
        %ONUP Apply rectangle selection and remove the preview rectangle.
            if ~obj.Mode.DrawingSelectionRectangle
                return
            end

            xy = obj.Host.cursorPosition;
            if ~isempty(xy)
                obj.CurrentPoint = xy;
            end

            if obj.dragDistance() >= obj.MinimumDragDistance
                obj.applySelectionRectangle();
            end

            obj.setMode('DrawingSelectionRectangle', false);
            obj.deleteSelectionPatch();
            E.stop();
        end
    end

    %% Host update helpers
    methods
        function pointer = getPreferredPointer(obj)
        %GETPREFERREDPOINTER Return pointer requested by current selection state.
            if obj.Mode.DrawingSelectionRectangle
                pointer = 'crosshair';
            elseif obj.Enabled
                pointer = 'crosshair';
            else
                pointer = '';
            end
        end
    end

    %% Private helpers
    methods (Access=private)
        function createSelectionPatch(obj)
        %CREATESELECTIONPATCH Create the transient marquee rectangle.
            if ~isempty(obj.SelectionPatch) && isgraphics(obj.SelectionPatch)
                return
            end

            obj.SelectionPatch = patch(obj.Host.getAxes(), ...
                "XData", [NaN NaN NaN NaN], ...
                "YData", [NaN NaN NaN NaN], ...
                "FaceColor", obj.RectangleFaceColor, ...
                "FaceAlpha", obj.RectangleFaceAlpha, ...
                "EdgeColor", obj.RectangleEdgeColor, ...
                "LineWidth", obj.RectangleLineWidth, ...
                "LineStyle", obj.RectangleLineStyle, ...
                "HitTest", "off", ...
                "PickableParts", "none", ...
                "Tag", "RectangleSelectPreview");
        end

        function updateSelectionPatch(obj)
        %UPDATESELECTIONPATCH Update preview rectangle coordinates.
            if isempty(obj.SelectionPatch) || ~isgraphics(obj.SelectionPatch)
                return
            end

            rect = obj.currentRectangle();
            x = [rect(1), rect(2), rect(2), rect(1)];
            y = [rect(3), rect(3), rect(4), rect(4)];

            set(obj.SelectionPatch, ...
                "XData", x, ...
                "YData", y, ...
                "FaceColor", obj.RectangleFaceColor, ...
                "FaceAlpha", obj.RectangleFaceAlpha, ...
                "EdgeColor", obj.RectangleEdgeColor, ...
                "LineWidth", obj.RectangleLineWidth, ...
                "LineStyle", obj.RectangleLineStyle);
        end

        function deleteSelectionPatch(obj)
        %DELETESELECTIONPATCH Delete the transient marquee rectangle.
            if ~isempty(obj.SelectionPatch) && isgraphics(obj.SelectionPatch)
                delete(obj.SelectionPatch);
            end
            obj.SelectionPatch = matlab.graphics.primitive.Patch.empty();
        end

        function applySelectionRectangle(obj)
        %APPLYSELECTIONRECTANGLE Mutate overlay selection from the current rect.
            rect = obj.currentRectangle();
            ids = obj.Host.Overlays.idsInsideRectangle(rect, Type=obj.TargetTypes);

            switch obj.SelectionMode
                case "replace"
                    obj.replaceSelection(ids);
                case "toggle"
                    for i = 1:numel(ids)
                        obj.Host.Overlays.toggleSelected(ids(i));
                    end
                case "remove"
                    for i = 1:numel(ids)
                        obj.Host.Overlays.deselect(ids(i));
                    end
            end
        end

        function replaceSelection(obj, ids)
        %REPLACESELECTION Replace selection while respecting TargetTypes.
            targetTypes = string(obj.TargetTypes);
            if isempty(targetTypes) || any(targetTypes == "") || any(strcmpi(targetTypes, "all"))
                obj.Host.Overlays.setSelected(ids);
                return
            end

            % Replace each target type independently so non-target overlay
            % selections survive the operation.
            for i = 1:numel(targetTypes)
                typeIds = ids(obj.idsMatchType(ids, targetTypes(i)));
                obj.Host.Overlays.setSelected(typeIds, Type=targetTypes(i));
            end
        end

        function tf = idsMatchType(obj, ids, typeName)
        %IDSMATCHTYPE True for IDs whose overlay Type matches typeName.
            ids = string(ids);
            tf = false(size(ids));

            for i = 1:numel(ids)
                overlay = obj.Host.Overlays.get(ids(i));
                tf(i) = ~isempty(overlay) && isvalid(overlay) ...
                    && strcmpi(overlay.Type, typeName);
            end
        end

        function rect = currentRectangle(obj)
        %CURRENTRECTANGLE Return [xmin xmax ymin ymax] for current drag.
            x = sort([obj.StartPoint(1), obj.CurrentPoint(1)]);
            y = sort([obj.StartPoint(2), obj.CurrentPoint(2)]);
            rect = [x, y];
        end

        function d = dragDistance(obj)
        %DRAGDISTANCE Return Euclidean drag distance in image pixels.
            delta = obj.CurrentPoint - obj.StartPoint;
            d = hypot(delta(1), delta(2));
        end
    end

    %% Teardown
    methods (Access=protected)
        function teardown(obj)
        %TEARDOWN Delete transient rectangle graphics during tool destruction.
            obj.deleteSelectionPatch();
        end
    end
end
