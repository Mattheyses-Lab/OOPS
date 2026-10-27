% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectSelection < handle
%OBJECTSELECTION Configure object overlay geometry and appearance.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        BoxType_ (1,1) string = "Boundary"
        LineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 0.5
        SelectedLineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 0.5
        ActiveLineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 0.5
        HoverLineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 2.0
        ColorMode_ (1,1) string = "Custom"
        Color_ (1,3) double {mustBeFinite,mustBeInRange(Color_,0,1)} = [1.0 1.0 1.0]
        SelectedColorMode_ (1,1) string = "Custom"
        SelectedColor_ (1,3) double {mustBeFinite,mustBeInRange(SelectedColor_,0,1)} = [1.0 1.0 0.0]
        ActiveColorMode_ (1,1) string = "Auto"
        ActiveColor_ (1,3) double {mustBeFinite,mustBeInRange(ActiveColor_,0,1)} = [0.30 0.65 1.00]
        HoverColorMode_ (1,1) string = "Auto"
        HoverColor_ (1,3) double {mustBeFinite,mustBeInRange(HoverColor_,0,1)} = [1.0 1.0 1.0]
        ShowActiveWhenSelected_ (1,1) logical = false
    end

    properties (Dependent)
        BoxType
        ColorMode
        LineWidth
        SelectedLineWidth
        ActiveLineWidth
        HoverLineWidth
        Color
        SelectedColorMode
        SelectedColor
        ActiveColorMode
        ActiveColor
        HoverColorMode
        HoverColor
        ShowActiveWhenSelected
    end

    events
        Changed
        ObjectSelectionChanged
    end

    methods

        function v = get.BoxType(obj)
        %GET.BOXTYPE Return the stored BoxType setting.

            v = obj.BoxType_;
        end

        function set.BoxType(obj,v)
        %SET.BOXTYPE Validate, store, and notify a ObjectSelection setting change.

            v = string(validatestring(string(v),["Boundary","Box"]));
            obj.setValue("BoxType",v);
        end

        function v = get.ColorMode(obj)
        %GET.COLORMODE Return the stored ColorMode setting.

            v = obj.ColorMode_;
        end

        function set.ColorMode(obj,v)
        %SET.COLORMODE Validate, store, and notify a ObjectSelection setting change.

            v = string(validatestring(string(v),["Custom","Label"]));
            obj.setValue("ColorMode",v);
        end

        function v = get.LineWidth(obj)
        %GET.LINEWIDTH Return the stored LineWidth setting.

            v = obj.LineWidth_;
        end

        function set.LineWidth(obj,v)
        %SET.LINEWIDTH Validate, store, and notify a ObjectSelection setting change.

            obj.setValue("LineWidth",v);
        end

        function v = get.SelectedLineWidth(obj)
        %GET.SELECTEDLINEWIDTH Return the stored SelectedLineWidth setting.

            v = obj.SelectedLineWidth_;
        end

        function set.SelectedLineWidth(obj,v)
        %SET.SELECTEDLINEWIDTH Validate, store, and notify a ObjectSelection setting change.

            obj.setValue("SelectedLineWidth",v);
        end

        function v = get.ActiveLineWidth(obj)
        %GET.ACTIVELINEWIDTH Return the stored ActiveLineWidth setting.

            v = obj.ActiveLineWidth_;
        end

        function set.ActiveLineWidth(obj,v)
        %SET.ACTIVELINEWIDTH Validate, store, and notify an ObjectSelection change.

            obj.setValue("ActiveLineWidth",v);
        end

        function v = get.HoverLineWidth(obj)
        %GET.HOVERLINEWIDTH Return the stored HoverLineWidth setting.

            v = obj.HoverLineWidth_;
        end

        function set.HoverLineWidth(obj,v)
        %SET.HOVERLINEWIDTH Validate, store, and notify an ObjectSelection change.

            obj.setValue("HoverLineWidth",v);
        end

        function v = get.Color(obj)
        %GET.COLOR Return the stored Color setting.

            v = obj.Color_;
        end

        function set.Color(obj,v)
        %SET.COLOR Validate, store, and notify a ObjectSelection setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("Color",v);
        end

        function v = get.SelectedColorMode(obj)
        %GET.SELECTEDCOLORMODE Return the selected-boundary color mode.

            v = obj.SelectedColorMode_;
        end

        function set.SelectedColorMode(obj,v)
        %SET.SELECTEDCOLORMODE Validate and store the selected-boundary color mode.

            v = string(validatestring(string(v),["Auto","Custom"]));
            obj.setValue("SelectedColorMode",v);
        end

        function v = get.SelectedColor(obj)
        %GET.SELECTEDCOLOR Return the custom selected-boundary color.

            v = obj.SelectedColor_;
        end

        function set.SelectedColor(obj,v)
        %SET.SELECTEDCOLOR Validate and store the custom selected-boundary color.

            obj.setValue("SelectedColor",reshape(v,1,[]));
        end

        function v = get.ActiveColorMode(obj)
        %GET.ACTIVECOLORMODE Return the active-boundary color mode.

            v = obj.ActiveColorMode_;
        end

        function set.ActiveColorMode(obj,v)
        %SET.ACTIVECOLORMODE Validate and store the active-boundary color mode.

            v = string(validatestring(string(v),["Auto","Custom"]));
            obj.setValue("ActiveColorMode",v);
        end

        function v = get.ActiveColor(obj)
        %GET.ACTIVECOLOR Return the custom active-boundary color.

            v = obj.ActiveColor_;
        end

        function set.ActiveColor(obj,v)
        %SET.ACTIVECOLOR Validate and store the custom active-boundary color.

            obj.setValue("ActiveColor",reshape(v,1,[]));
        end

        function v = get.HoverColorMode(obj)
        %GET.HOVERCOLORMODE Return the hovered-boundary color mode.

            v = obj.HoverColorMode_;
        end

        function set.HoverColorMode(obj,v)
        %SET.HOVERCOLORMODE Validate and store the hovered-boundary color mode.

            v = string(validatestring(string(v),["Auto","Custom"]));
            obj.setValue("HoverColorMode",v);
        end

        function v = get.HoverColor(obj)
        %GET.HOVERCOLOR Return the custom hovered-boundary color.

            v = obj.HoverColor_;
        end

        function set.HoverColor(obj,v)
        %SET.HOVERCOLOR Validate and store the custom hovered-boundary color.

            obj.setValue("HoverColor",reshape(v,1,[]));
        end

        function v = get.ShowActiveWhenSelected(obj)
        %GET.SHOWACTIVEWHENSELECTED Return whether selected objects retain their active edge.

            v = obj.ShowActiveWhenSelected_;
        end

        function set.ShowActiveWhenSelected(obj,v)
        %SET.SHOWACTIVEWHENSELECTED Store whether selected objects retain their active edge.

            obj.setValue("ShowActiveWhenSelected",logical(v));
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('BoxType',obj.BoxType, ...
                'ColorMode',obj.ColorMode, ...
                'LineWidth',obj.LineWidth, ...
                'SelectedLineWidth',obj.SelectedLineWidth, ...
                'ActiveLineWidth',obj.ActiveLineWidth, ...
                'HoverLineWidth',obj.HoverLineWidth, ...
                'Color',obj.Color, ...
                'SelectedColorMode',obj.SelectedColorMode, ...
                'SelectedColor',obj.SelectedColor, ...
                'ActiveColorMode',obj.ActiveColorMode, ...
                'ActiveColor',obj.ActiveColor, ...
                'HoverColorMode',obj.HoverColorMode, ...
                'HoverColor',obj.HoverColor, ...
                'ShowActiveWhenSelected',obj.ShowActiveWhenSelected);
        end

        function fromStruct(obj,S)
        %FROMSTRUCT Restore recognized settings through their validated setters.

            validateattributes(S,{'struct'},{'scalar'});

            % Names of the serialized fields to apply through the public setters.
            names = fieldnames(obj.toStruct());

            % Apply serialized fields through their validated public setting setters.
            for k = 1:numel(names)

                if isfield(S,names{k})
                    obj.(names{k}) = S.(names{k});
                end

            end

        end

    end

    methods (Access=private)

        function setValue(obj,name,value)
        %SETVALUE Validate the backing property before emitting change events.

            try

                % Private storage property corresponding to the public setting name.
                property = char(name + "_");

                % Stored setting value before validation and assignment.
                old = obj.(property);
                obj.(property) = value;

                % Stored/coerced setting value used in the change-event payload.
                value = obj.(property);

                if isequaln(old,value)
                    return;
                end

                % Change event carrying the domain, setting name, and old/new values.
                ev = oops.config.ChangeEvent("ObjectSelection",name,old,value);
                notify(obj,'ObjectSelectionChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
