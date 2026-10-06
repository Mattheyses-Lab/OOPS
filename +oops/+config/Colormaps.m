% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Colormaps < handle
%COLORMAPS Named intensity, order, and cyclic azimuth colormaps.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        Intensity_ (1,1) string = "gray"
        Order_ (1,1) string = "parula"
        % Use a cyclic colormap for axial angle display.
        Azimuth_ (1,1) string = "hsv"
        IntensityCategory_ (1,1) string = "MATLAB"
        OrderCategory_ (1,1) string = "MATLAB"
        AzimuthCategory_ (1,1) string = "MATLAB"
    end

    properties (Dependent)
        Intensity
        Order
        Azimuth
        IntensityCategory
        OrderCategory
        AzimuthCategory
    end

    events
        Changed
        ColormapsChanged
    end

    methods

        function v = get.Intensity(obj)
        %GET.INTENSITY Return the stored Intensity setting.

            v = obj.Intensity_;
        end

        function set.Intensity(obj,v)
        %SET.INTENSITY Validate, store, and notify a Colormaps setting change.

            obj.setValue("Intensity",v);
        end

        function v = get.Order(obj)
        %GET.ORDER Return the stored Order setting.

            v = obj.Order_;
        end

        function set.Order(obj,v)
        %SET.ORDER Validate, store, and notify a Colormaps setting change.

            obj.setValue("Order",v);
        end

        function v = get.Azimuth(obj)
        %GET.AZIMUTH Return the stored Azimuth setting.

            v = obj.Azimuth_;
        end

        function set.Azimuth(obj,v)
        %SET.AZIMUTH Validate, store, and notify a Colormaps setting change.

            obj.setValue("Azimuth",v);
        end

        function v = get.IntensityCategory(obj)
        %GET.INTENSITYCATEGORY Return this domain's registry category.

            v = obj.IntensityCategory_;
        end

        function set.IntensityCategory(obj,v)
        %SET.INTENSITYCATEGORY Store a category independently of the other domains.

            obj.setValue("IntensityCategory",v);
        end

        function v = get.OrderCategory(obj)
        %GET.ORDERCATEGORY Return this domain's registry category.

            v = obj.OrderCategory_;
        end

        function set.OrderCategory(obj,v)
        %SET.ORDERCATEGORY Store a category independently of the other domains.

            obj.setValue("OrderCategory",v);
        end

        function v = get.AzimuthCategory(obj)
        %GET.AZIMUTHCATEGORY Return this domain's registry category.

            v = obj.AzimuthCategory_;
        end

        function set.AzimuthCategory(obj,v)
        %SET.AZIMUTHCATEGORY Store a category independently of the other domains.

            obj.setValue("AzimuthCategory",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('Intensity',obj.Intensity, ...
                'Order',obj.Order, ...
                'Azimuth',obj.Azimuth, ...
                'IntensityCategory',obj.IntensityCategory, ...
                'OrderCategory',obj.OrderCategory, ...
                'AzimuthCategory',obj.AzimuthCategory);
        end

        function setMap(obj,domain,name,category)
        %SETMAP Commit a registry name/category pair before broadcasting either change.

            try

                % Display domain whose independent colormap assignment is being changed.
                domain = string(domain);

                % Requested registry map name, normalized to string.
                name = string(name);

                % Requested registry category, normalized to string.
                category = string(category);

                if ~ismember(domain,["Intensity","Order","Azimuth"]) || ...
                        ~matlabx.colors.maps.Registry.has(name,category)
                    error('oops:config:UnknownColormap','Unknown colormap/domain: %s (%s).',name,category);
                end

                % Previous map name retained for the final change notification.
                oldName = obj.(domain);

                % Previous category saved to detect a completed assignment change.
                oldCategory = obj.(domain+"Category");
                obj.(domain+"_") = name;
                obj.(domain+"Category_") = category;

                % Map names available in the chosen registry category.
                names = [domain,domain+"Category"];

                % Previous value for the specific map/category field being assigned.
                old = [oldName,oldCategory];

                % Validated new value for that field, used in its change event.
                next = [name,category];

                for k = 1:2

                    if old(k) == next(k)
                        continue;
                    end

                    % Event describing the completed colormap-name change.
                    ev = oops.config.ChangeEvent("Colormaps",names(k),old(k),next(k));
                    notify(obj,'ColormapsChanged',ev);
                    notify(obj,'Changed',ev);
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function fromStruct(obj,S)
        %FROMSTRUCT Restore complete map pairs without exposing intermediate mismatches.

            validateattributes(S,{'struct'},{'scalar'});

            % Apply serialized fields through their validated public setting setters.
            for domain = ["Intensity","Order","Azimuth"]

                % Display domain being restored from the serialized map assignments.
                name = obj.(domain);

                % Saved per-domain category field paired with that map name.
                category = obj.(domain+"Category");

                if isfield(S,domain)
                    name = S.(domain);
                end

                if isfield(S,domain+"Category")
                    category = S.(domain+"Category");
                end

                obj.setMap(domain,name,category);
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
                ev = oops.config.ChangeEvent("Colormaps",name,old,value);
                notify(obj,'ColormapsChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
