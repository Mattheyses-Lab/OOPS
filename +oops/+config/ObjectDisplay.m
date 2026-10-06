% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectDisplay < handle
%OBJECTDISPLAY Object crop defaults and future object azimuth rendering preferences.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        % Requested pixels of context on every side before squaring.
        CropMargin_ (1,1) double {mustBeFinite,mustBeInteger,mustBeNonnegative} = 5
        SquareCrop_ (1,1) logical = true
        LineAlpha_ (1,1) double {mustBeFinite,mustBeInRange(LineAlpha_,0,1)} = 0.8
        LineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 3.0
        LineScale_ (1,1) double {mustBeFinite,mustBePositive} = 15.0
        ScaleDownFactor_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 1
        ColorMode_ (1,1) string = "Direction"
    end

    properties (Dependent)
        CropMargin
        SquareCrop
        LineAlpha
        LineWidth
        LineScale
        ScaleDownFactor
        ColorMode
    end

    events
        Changed
        ObjectDisplayChanged
    end

    methods

        function v = get.CropMargin(obj)
        %GET.CROPMARGIN Return the stored CropMargin setting.

            v = obj.CropMargin_;
        end

        function set.CropMargin(obj,v)
        %SET.CROPMARGIN Validate, store, and notify a ObjectDisplay setting change.

            obj.setValue("CropMargin",v);
        end

        function v = get.SquareCrop(obj)
        %GET.SQUARECROP Return the stored SquareCrop setting.

            v = obj.SquareCrop_;
        end

        function set.SquareCrop(obj,v)
        %SET.SQUARECROP Validate, store, and notify a ObjectDisplay setting change.

            obj.setValue("SquareCrop",v);
        end

        function v = get.LineAlpha(obj)
        %GET.LINEALPHA Return the stored LineAlpha setting.

            v = obj.LineAlpha_;
        end

        function set.LineAlpha(obj,v)
        %SET.LINEALPHA Validate, store, and notify a ObjectDisplay setting change.

            obj.setValue("LineAlpha",v);
        end

        function v = get.LineWidth(obj)
        %GET.LINEWIDTH Return the stored LineWidth setting.

            v = obj.LineWidth_;
        end

        function set.LineWidth(obj,v)
        %SET.LINEWIDTH Validate, store, and notify a ObjectDisplay setting change.

            obj.setValue("LineWidth",v);
        end

        function v = get.LineScale(obj)
        %GET.LINESCALE Return the stored LineScale setting.

            v = obj.LineScale_;
        end

        function set.LineScale(obj,v)
        %SET.LINESCALE Validate, store, and notify a ObjectDisplay setting change.

            obj.setValue("LineScale",v);
        end

        function v = get.ScaleDownFactor(obj)
        %GET.SCALEDOWNFACTOR Return the stored ScaleDownFactor setting.

            v = obj.ScaleDownFactor_;
        end

        function set.ScaleDownFactor(obj,v)
        %SET.SCALEDOWNFACTOR Validate, store, and notify a ObjectDisplay setting change.

            obj.setValue("ScaleDownFactor",v);
        end

        function v = get.ColorMode(obj)
        %GET.COLORMODE Return the stored ColorMode setting.

            v = obj.ColorMode_;
        end

        function set.ColorMode(obj,v)
        %SET.COLORMODE Validate, store, and notify a ObjectDisplay setting change.

            obj.setValue("ColorMode",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('CropMargin',obj.CropMargin, ...
                'SquareCrop',obj.SquareCrop, ...
                'LineAlpha',obj.LineAlpha, ...
                'LineWidth',obj.LineWidth, ...
                'LineScale',obj.LineScale, ...
                'ScaleDownFactor',obj.ScaleDownFactor, ...
                'ColorMode',obj.ColorMode);
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
                ev = oops.config.ChangeEvent("ObjectDisplay",name,old,value);
                notify(obj,'ObjectDisplayChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
