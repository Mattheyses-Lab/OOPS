% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Palettes < handle
%PALETTES Named group and label palettes, independent of label/group data.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        Group_ (1,1) string = "lines"
        Label_ (1,1) string = "lines"
        Category_ (1,1) string = "MATLAB"
    end

    properties (Dependent)
        Group
        Label
        Category
    end

    events
        Changed
        PalettesChanged
    end

    methods

        function v = get.Group(obj)
        %GET.GROUP Return the stored Group setting.

            v = obj.Group_;
        end

        function set.Group(obj,v)
        %SET.GROUP Validate, store, and notify a Palettes setting change.

            obj.setValue("Group",v);
        end

        function v = get.Label(obj)
        %GET.LABEL Return the stored Label setting.

            v = obj.Label_;
        end

        function set.Label(obj,v)
        %SET.LABEL Validate, store, and notify a Palettes setting change.

            obj.setValue("Label",v);
        end

        function v = get.Category(obj)
        %GET.CATEGORY Return the stored Category setting.

            v = obj.Category_;
        end

        function set.Category(obj,v)
        %SET.CATEGORY Validate, store, and notify a Palettes setting change.

            obj.setValue("Category",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('Group',obj.Group, ...
                'Label',obj.Label, ...
                'Category',obj.Category);
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
                ev = oops.config.ChangeEvent("Palettes",name,old,value);
                notify(obj,'PalettesChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
