% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectBoundaries < matlabx.ui.axes.AxesTool
%OBJECTBOUNDARIES Present object-specific controls for polygon overlays.
% The MATLABX Polygon tool retains responsibility for generic polygon
% interaction. This application tool translates that controller into OOPS
% object terminology without keeping a second overlay registry.

    properties
        ObjectActivatedFcn = []
        ObjectSelectionChangedFcn = []
        ObjectsDeleteRequestedFcn = []
    end

    properties (Access=private)
        PolygonTool = []
    end

    methods

        function obj = ObjectBoundaries(host,polygonTool)
        %OBJECTBOUNDARIES Construct an OOPS facade for a headless Polygon tool.

            arguments
                host (1,1) matlabx.ui.axes.ImageAxes
                polygonTool (1,1) matlabx.ui.axes.tools.Polygon
            end

            if polygonTool.Host ~= host
                error('oops:ui:ObjectBoundaryToolHostMismatch', ...
                    'The Polygon controller must belong to the same ImageAxes host.');
            end

            obj@matlabx.ui.axes.AxesTool(host,"ObjectBoundaries", ...
                'Tooltip','Object boundaries (help)', ...
                'AxesType',"image", ...
                'Icon',matlabx.internal.Paths.icons('SelectionWhiteFGTransparentBG.svg'), ...
                'Style','push');

            obj.PolygonTool = polygonTool;
        end

        function onInstall(obj)
        %ONINSTALL Forward generic polygon events through object-facing callbacks.

            obj.PolygonTool.PolygonActivatedFcn = ...
                @(~,data) obj.emitObjectActivated(data);
            obj.PolygonTool.PolygonSelectionChangedFcn = ...
                @(~,data) obj.emitObjectSelectionChanged(data);
            obj.PolygonTool.PolygonsDeleteRequestedFcn = ...
                @(~,data) obj.emitObjectsDeleteRequested(data);
        end

        function onUninstall(obj)
        %ONUNINSTALL Release callbacks installed on the borrowed controller.

            if isempty(obj.PolygonTool) || ~isvalid(obj.PolygonTool)
                return;
            end

            obj.PolygonTool.PolygonActivatedFcn = [];
            obj.PolygonTool.PolygonSelectionChangedFcn = [];
            obj.PolygonTool.PolygonsDeleteRequestedFcn = [];
        end

        function onPush(obj)
        %ONPUSH Open help for object-boundary interaction.

            obj.Host.openToolHelpWindow(obj);
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add object-facing selection and deletion commands.

            menu.addSubmenu( ...
                "ObjectBoundaries", ...
                "Object Boundaries", ...
                'Owner',obj);

            menu.addItem( ...
                "ObjectBoundaries.SelectAll", ...
                "Select All Objects", ...
                @(~,~) obj.selectAll(), ...
                'Parent',"ObjectBoundaries", ...
                'Owner',obj);

            menu.addItem( ...
                "ObjectBoundaries.ClearSelection", ...
                "Clear Object Selection", ...
                @(~,~) obj.clearSelection(), ...
                'Parent',"ObjectBoundaries", ...
                'Owner',obj);

            menu.addItem( ...
                "ObjectBoundaries.ClearActive", ...
                "Clear Active Object", ...
                @(~,~) obj.setActiveObjectID(""), ...
                'Parent',"ObjectBoundaries", ...
                'Owner',obj);

            menu.addItem( ...
                "ObjectBoundaries.DeleteActive", ...
                "Delete Active Object", ...
                @(~,~) obj.deleteActive(), ...
                'Parent',"ObjectBoundaries", ...
                'Owner',obj, ...
                'Separator','on');

            menu.addItem( ...
                "ObjectBoundaries.DeleteSelected", ...
                "Delete Selected Objects", ...
                @(~,~) obj.deleteSelected(), ...
                'Parent',"ObjectBoundaries", ...
                'Owner',obj);

            menu.addItem( ...
                "ObjectBoundaries.DeleteAll", ...
                "Delete All Objects", ...
                @(~,~) obj.deleteAll(), ...
                'Parent',"ObjectBoundaries", ...
                'Owner',obj);

            menu.addItem( ...
                "ObjectBoundaries.Help", ...
                "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                'Parent',"ObjectBoundaries", ...
                'Owner',obj, ...
                'Separator','on');
        end

        function overlay = addBoundary(obj,id,vertices,varargin)
        %ADDBOUNDARY Add one object boundary to the shared overlay registry.

            overlay = obj.PolygonTool.addPolygon(id,vertices,varargin{:});
        end

        function removeBoundary(obj,id)
        %REMOVEBOUNDARY Request deletion of the object represented by one boundary.

            obj.PolygonTool.removePolygon(id);
        end

        function selectAll(obj)
        %SELECTALL Select every object boundary registered with this viewer.

            obj.PolygonTool.selectAllPolygons();
        end

        function clearSelection(obj)
        %CLEARSELECTION Clear selected object boundaries without changing active state.

            obj.PolygonTool.clearPolygonSelection();
        end

        function ids = getSelectedObjectIDs(obj)
        %GETSELECTEDOBJECTIDS Return selected object-boundary IDs in stable order.

            ids = obj.PolygonTool.getSelectedPolygonIDs();
        end

        function setSelectedObjectIDs(obj,ids)
        %SETSELECTEDOBJECTIDS Replace selected object-boundary membership.

            obj.PolygonTool.setSelectedPolygonIDs(ids);
        end

        function setActiveObjectID(obj,id)
        %SETACTIVEOBJECTID Set or clear the active object boundary.

            obj.PolygonTool.setActivePolygonID(id);
        end

        function deleteActive(obj)
        %DELETEACTIVE Request deletion of the active object.

            obj.PolygonTool.deleteActivePolygon();
        end

        function deleteSelected(obj)
        %DELETESELECTED Request one batch deletion for selected objects.

            obj.PolygonTool.deleteSelectedPolygons();
        end

        function deleteAll(obj)
        %DELETEALL Request deletion of every object represented in the viewer.

            obj.PolygonTool.deleteAllPolygons();
        end

        function summary = getHelpSummary(~)
        %GETHELPSUMMARY Return a one-line object-boundary description.

            summary = "Activate, select, and delete image objects through their boundaries.";
        end

        function usage = getUsageHelp(~)
        %GETUSAGEHELP Return concise object-boundary interaction instructions.

            usage = [ ...
                "Click an object boundary to make that object active."; ...
                "Shift-click a boundary or use Rectangle Select to change batch selection."; ...
                "Use the Object Boundaries menu for selection and deletion commands."];
        end

        function bindings = getBindingHelp(~)
        %GETBINDINGHELP Describe object-boundary mouse bindings.

            bindings = struct( ...
                'Activate','click object boundary', ...
                'ToggleSelection','shift+extendclick object boundary', ...
                'Deactivate','alt+click object boundary', ...
                'DeleteObject','control+contextclick object boundary');
        end

        function notes = getNotesHelp(~)
        %GETNOTESHELP Describe the active/selected distinction.

            notes = [ ...
                "The active object controls displayed data."; ...
                "Selected objects form the set used by batch operations."];
        end

    end

    methods (Access=private)

        function emitObjectActivated(obj,data)
        %EMITOBJECTACTIVATED Forward one generic activation event to OOPS.

            if ~isempty(obj.ObjectActivatedFcn)
                obj.ObjectActivatedFcn(obj,data);
            end
        end

        function emitObjectSelectionChanged(obj,data)
        %EMITOBJECTSELECTIONCHANGED Forward one batched selection event to OOPS.

            if ~isempty(obj.ObjectSelectionChangedFcn)
                obj.ObjectSelectionChangedFcn(obj,data);
            end
        end

        function emitObjectsDeleteRequested(obj,data)
        %EMITOBJECTSDELETEREQUESTED Forward deletion before overlays are mutated.

            if ~isempty(obj.ObjectsDeleteRequestedFcn)
                obj.ObjectsDeleteRequestedFcn(obj,data);
            end
        end

    end

end
