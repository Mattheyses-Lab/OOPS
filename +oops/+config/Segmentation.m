% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Segmentation < handle
%SEGMENTATION Mask strategy and object-partition parameters; processing is separate.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        % A strategy name is configuration, not an implementation registry.
        Strategy_ (1,1) string = "Puncta"
        Connectivity_ (1,1) double {mustBeMember(Connectivity_,[4 8])} = 4
        MinimumArea_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 10
        BorderWidth_ (1,1) double {mustBeFinite,mustBeInteger,mustBeNonnegative} = 10
        % Post-segmentation brightness ranking; zero disables the object limit.
        MaxObjects_ (1,1) double {mustBeFinite,mustBeInteger,mustBeNonnegative} = 499
    end

    properties (Dependent)
        Strategy
        Connectivity
        MinimumArea
        BorderWidth
        MaxObjects
    end

    events
        Changed
        SegmentationChanged
    end

    methods

        function v = get.Strategy(obj)
        %GET.STRATEGY Return the stored Strategy setting.

            v = obj.Strategy_;
        end

        function set.Strategy(obj,v)
        %SET.STRATEGY Validate, store, and notify a Segmentation setting change.

            obj.setValue("Strategy",v);
        end

        function v = get.Connectivity(obj)
        %GET.CONNECTIVITY Return the stored Connectivity setting.

            v = obj.Connectivity_;
        end

        function set.Connectivity(obj,v)
        %SET.CONNECTIVITY Validate, store, and notify a Segmentation setting change.

            obj.setValue("Connectivity",v);
        end

        function v = get.MinimumArea(obj)
        %GET.MINIMUMAREA Return the stored MinimumArea setting.

            v = obj.MinimumArea_;
        end

        function set.MinimumArea(obj,v)
        %SET.MINIMUMAREA Validate, store, and notify a Segmentation setting change.

            obj.setValue("MinimumArea",v);
        end

        function v = get.BorderWidth(obj)
        %GET.BORDERWIDTH Return the stored BorderWidth setting.

            v = obj.BorderWidth_;
        end

        function set.BorderWidth(obj,v)
        %SET.BORDERWIDTH Validate, store, and notify a Segmentation setting change.

            obj.setValue("BorderWidth",v);
        end

        function v = get.MaxObjects(obj)
        %GET.MAXOBJECTS Return the stored MaxObjects setting.

            v = obj.MaxObjects_;
        end

        function set.MaxObjects(obj,v)
        %SET.MAXOBJECTS Validate, store, and notify a Segmentation setting change.

            obj.setValue("MaxObjects",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('Strategy',obj.Strategy, ...
                'Connectivity',obj.Connectivity, ...
                'MinimumArea',obj.MinimumArea, ...
                'BorderWidth',obj.BorderWidth, ...
                'MaxObjects',obj.MaxObjects);
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

                if name == "Strategy"
                    oops.analysis.segment.strategies(string(value));
                end

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
                ev = oops.config.ChangeEvent("Segmentation",name,old,value);
                notify(obj,'SegmentationChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
