% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectSelection < handle
%OBJECTSELECTION Configure object overlay geometry and appearance.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        BoxType_ (1,1) string = "Boundary"
        ColorMode_ (1,1) string = "Custom"
        LineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 1.0
        SelectedLineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 2.0
        Color_ (1,3) double {mustBeFinite,mustBeInRange(Color_,0,1)} = [1.0 1.0 1.0]
    end

    properties (Dependent)
        BoxType
        ColorMode
        LineWidth
        SelectedLineWidth
        Color
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

        function v = get.Color(obj)
        %GET.COLOR Return the stored Color setting.

            v = obj.Color_;
        end

        function set.Color(obj,v)
        %SET.COLOR Validate, store, and notify a ObjectSelection setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("Color",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('BoxType',obj.BoxType, ...
                'ColorMode',obj.ColorMode, ...
                'LineWidth',obj.LineWidth, ...
                'SelectedLineWidth',obj.SelectedLineWidth, ...
                'Color',obj.Color);
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
