classdef Boundaries < matlabx.ui.axes.AxesTool
%BOUNDARIES Interact with batched BoundaryCollection entries.
%
%   Boundaries applies standard ImageAxes activation, hover, selection, and
%   deletion gestures while BoundaryCollection owns the shared graphics.

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

    properties
        BoundaryActivatedFcn = []
        BoundarySelectionChangedFcn = []
        BoundariesDeleteRequestedFcn = []
    end

    properties (Access=private,Transient,NonCopyable)
        OverlayListeners event.listener = event.listener.empty()
    end

    methods
        function obj=Boundaries(host)
        %BOUNDARIES Create the shared-boundary controller.
            obj@matlabx.ui.axes.AxesTool(host,"Boundaries", ...
                Tooltip='Show/Hide Boundaries',AxesType="image",Style='state', ...
                Icon=matlabx.internal.Paths.icons('ObjectsWhiteFGTransparentBG.svg'), ...
                Priority=10,PassivelyInterceptsDown=true,PassivelyInterceptsMove=true);
        end

        function onInstall(obj)
        %ONINSTALL Listen for manager-owned state and show collections initially.
            obj.OverlayListeners(1)=addlistener(obj.Host.Overlays,'ActiveChanged',@(~,~) obj.emitActive());
            obj.OverlayListeners(2)=addlistener(obj.Host.Overlays,'SelectionChanged',@(~,~) obj.emitSelection());
            obj.enable();
        end

        function onUninstall(obj)
        %ONUNINSTALL Release listeners without deleting boundary data.
            delete(obj.OverlayListeners(isvalid(obj.OverlayListeners)));
            obj.OverlayListeners=event.listener.empty();
            obj.clearHover();
        end

        function onEnabled(obj)
        %ONENABLED Show all boundary collections.
            obj.Host.Overlays.setBoundaryCollectionsVisible("on");
        end

        function onDisabled(obj)
        %ONDISABLED Hide all boundary collections without changing state.
            if isvalid(obj.Host)
                obj.clearHover();
                obj.Host.Overlays.setBoundaryCollectionsVisible("off");
            end
        end

        function onPassiveMove(obj,E)
        %ONPASSIVEMOVE Resolve the UUID beneath the cursor and update hover.
            [~,id]=obj.resolveAt(E.Target);
            if strlength(id)>0, obj.Host.Overlays.setHover(id); else, obj.clearHover(); end
        end

        function onPassiveDown(obj,E)
        %ONPASSIVEDOWN Apply standard overlay gestures to one resolved boundary.
            [collection,id]=obj.resolveAt(E.Target);
            if isempty(collection) || strlength(id)==0
                if E.MouseChord=="click" && ~obj.Host.toolEnabled("RectangleSelect") ...
                        && strlength(obj.Host.Overlays.getActiveID(Type="Boundary"))>0
                    obj.Host.Overlays.clearActive();
                end
                return
            end
            switch E.MouseChord
                case "click"
                    if obj.Host.Overlays.getActiveID(Type="Boundary")==id
                        obj.Host.Overlays.clearActive();
                    else
                        obj.Host.Overlays.setActive(id);
                    end
                case "shift+extendclick"
                    obj.Host.Overlays.toggleSelected(id);
                case "alt+click"
                    obj.Host.Overlays.clearActive();
                case "control+contextclick"
                    obj.requestDeletion(id);
                case "contextclick"
                    E.markHandled();
                otherwise
                    return
            end
            E.stop();
        end

        function onHostLeave(obj,~)
        %ONHOSTLEAVE Clear transient boundary hover state.
            obj.clearHover();
        end

        function pointer=getPreferredPointer(obj)
        %GETPREFERREDPOINTER Use a hand over an individually resolved boundary.
            if strlength(obj.Host.Overlays.getHoverID(Type="Boundary"))>0
                pointer='hand';
            else
                pointer='';
            end
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add generic boundary commands.
            menu.addSubmenu("Boundaries","Boundaries",Owner=obj);
            menu.addItem("Boundaries.Options","Options...",@(~,~) obj.openOptions(), ...
                Parent="Boundaries",Owner=obj);
            menu.addItem("Boundaries.SelectAll","Select All",@(~,~) obj.selectAll(),Parent="Boundaries",Owner=obj);
            menu.addItem("Boundaries.ClearSelection","Clear Selection",@(~,~) obj.clearSelection(),Parent="Boundaries",Owner=obj);
            menu.addItem("Boundaries.ClearActive","Clear Active",@(~,~) obj.Host.Overlays.clearActive(),Parent="Boundaries",Owner=obj);
            menu.addItem("Boundaries.DeleteActive","Delete Active",@(~,~) obj.deleteActive(),Parent="Boundaries",Owner=obj,Separator="on");
            menu.addItem("Boundaries.DeleteSelected","Delete Selected",@(~,~) obj.deleteSelected(),Parent="Boundaries",Owner=obj);
            menu.addItem("Boundaries.DeleteAll","Delete All",@(~,~) obj.deleteAll(),Parent="Boundaries",Owner=obj);
            menu.addItem("Boundaries.Help","Help...",@(~,~) obj.Host.openToolHelpWindow(obj),Parent="Boundaries",Owner=obj,Separator="on");
        end

        function selectAll(obj)
        %SELECTALL Select every registered Boundary.
            obj.Host.Overlays.setSelected(obj.Host.Overlays.ids(Type="Boundary"),Type="Boundary");
        end

        function openOptions(obj)
        %OPENOPTIONS Edit shared boundary collection colors and line widths.
            collections=obj.Host.Overlays.getBoundaryCollections();
            if isempty(collections), return; end
            source=collections{1};
            positive=@(x) isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>0;
            params=matlabx.app.ParamsDialog.prompt("Boundary Options", ...
                {'DisplayGeometry','Display geometry','choice',source.DisplayGeometry, ...
                    {'boundary','boundingbox'}}, ...
                {'ShowActiveEdgeWhenSelected','Show active edge when selected','logical', ...
                    source.ShowActiveEdgeWhenSelected}, ...
                {'UsePerBoundaryColors','Use per-boundary colors','logical',source.UsePerBoundaryColors}, ...
                {'EdgeColor','Base color','color',source.EdgeColor}, ...
                {'LineWidth','Base line width','double',source.LineWidth,positive,'Line width must be positive.'}, ...
                {'UseActiveEdgeColor','Override active color','logical',~isempty(source.ActiveEdgeColor)}, ...
                {'ActiveEdgeColor','Active color','color',obj.dialogColor(source.ActiveEdgeColor,source.EdgeColor)}, ...
                {'ActiveLineWidth','Active line width','double',source.ActiveLineWidth,positive,'Line width must be positive.'}, ...
                {'UseHoverEdgeColor','Override hover color','logical',~isempty(source.HoverEdgeColor)}, ...
                {'HoverEdgeColor','Hover color','color',obj.dialogColor(source.HoverEdgeColor,source.EdgeColor)}, ...
                {'HoverLineWidth','Hover line width','double',source.HoverLineWidth,positive,'Line width must be positive.'}, ...
                {'UseSelectionEdgeColor','Override selected color','logical',~isempty(source.SelectionEdgeColor)}, ...
                {'SelectionEdgeColor','Selected color','color',obj.dialogColor(source.SelectionEdgeColor,source.EdgeColor)}, ...
                {'SelectionLineWidth','Selected line width','double',source.SelectionLineWidth,positive,'Line width must be positive.'});
            if isempty(params), return; end
            for i=1:numel(collections)
                collection=collections{i};
                collection.DisplayGeometry=params.DisplayGeometry;
                collection.ShowActiveEdgeWhenSelected=params.ShowActiveEdgeWhenSelected;
                collection.UsePerBoundaryColors=params.UsePerBoundaryColors;
                collection.EdgeColor=params.EdgeColor;
                collection.LineWidth=params.LineWidth;
                collection.ActiveEdgeColor=obj.optionalColor(params.UseActiveEdgeColor,params.ActiveEdgeColor);
                collection.ActiveLineWidth=params.ActiveLineWidth;
                collection.HoverEdgeColor=obj.optionalColor(params.UseHoverEdgeColor,params.HoverEdgeColor);
                collection.HoverLineWidth=params.HoverLineWidth;
                collection.SelectionEdgeColor=obj.optionalColor(params.UseSelectionEdgeColor,params.SelectionEdgeColor);
                collection.SelectionLineWidth=params.SelectionLineWidth;
            end
        end

        function clearSelection(obj)
        %CLEARSELECTION Clear Boundary selection only.
            obj.Host.Overlays.clearSelection(Type="Boundary");
        end

        function deleteSelected(obj)
        %DELETESELECTED Request one deletion batch for selected boundaries.
            obj.requestDeletion(obj.Host.Overlays.getSelectedIDs(Type="Boundary"));
        end

        function deleteActive(obj)
        %DELETEACTIVE Request deletion of the active Boundary.
            obj.requestDeletion(obj.Host.Overlays.getActiveID(Type="Boundary"));
        end

        function deleteAll(obj)
        %DELETEALL Request deletion of every registered Boundary.
            obj.requestDeletion(obj.Host.Overlays.ids(Type="Boundary"));
        end

        function summary=getHelpSummary(~)
            summary="Activate, select, and delete efficiently batched boundaries.";
        end

        function usage=getUsageHelp(~)
            usage=["Click a boundary region to toggle its active state."; ...
                "Shift-click or use Rectangle Select for batch selection."; ...
                "Use the Boundaries menu for selection and deletion commands."];
        end

        function bindings=getBindingHelp(~)
            bindings=struct(Activate="click boundary",ToggleSelection="shift+extendclick boundary", ...
                Deactivate="alt+click boundary",Delete="control+contextclick boundary");
        end
    end

    methods (Access=private)
        function color=dialogColor(~,color,fallback)
            if isempty(color), color=fallback; end
        end

        function color=optionalColor(~,useColor,color)
            if ~useColor, color=[]; end
        end

        function [collection,id]=resolveAt(obj,target)
            collection=obj.Host.Overlays.boundaryCollectionForTarget(target);
            id="";
            if ~isempty(collection)
                id=collection.idAt(obj.Host.cursorPosition);
                if strlength(id)>0, return; end
            end
            collections=obj.Host.Overlays.getBoundaryCollections();
            for i=1:numel(collections)
                candidate=collections{i};
                if ~isempty(collection) && candidate==collection, continue; end
                candidateID=candidate.idAt(obj.Host.cursorPosition);
                if strlength(candidateID)>0
                    collection=candidate;
                    id=candidateID;
                    return
                end
            end
            collection=[];
        end

        function requestDeletion(obj,ids)
            ids=unique(matlabx.ui.axes.ImageAxesOverlayManager.normalizeIds(ids),"stable");
            ids=ids(arrayfun(@(id) isa(obj.Host.Overlays.get(id),'matlabx.ui.axes.overlays.Boundary'),ids));
            if isempty(ids), return; end
            if ~isempty(obj.BoundariesDeleteRequestedFcn)
                obj.BoundariesDeleteRequestedFcn(obj,struct('IDs',ids));
            else
                obj.Host.Overlays.removeMany(ids);
            end
        end

        function clearHover(obj)
            if strlength(obj.Host.Overlays.getHoverID(Type="Boundary"))>0
                obj.Host.Overlays.clearHover();
            end
        end

        function emitActive(obj)
            if ~isempty(obj.BoundaryActivatedFcn)
                obj.BoundaryActivatedFcn(obj,struct('ID',obj.Host.Overlays.getActiveID(Type="Boundary")));
            end
        end

        function emitSelection(obj)
            if ~isempty(obj.BoundarySelectionChangedFcn)
                obj.BoundarySelectionChangedFcn(obj,struct('IDs',obj.Host.Overlays.getSelectedIDs(Type="Boundary")));
            end
        end
    end
end
