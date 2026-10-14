% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Display < handle
%DISPLAY General image and application appearance; no UI handles or view state.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        KeepAutoDisplayIntensity_ (1,1) logical = true
        KeepAutoDisplayOrder_ (1,1) logical = true
        LockDisplayIntensity_ (1,1) logical = false
        LockDisplayOrder_ (1,1) logical = false
        LockedDisplayRangeIntensity_ double = []
        LockedDisplayRangeOrder_ double = []
        OrderAutoScaleMethod_ (1,1) string {mustBeMember(OrderAutoScaleMethod_, ...
            ["Contrast","Zero to max","Data range"])} = "Contrast"
        Theme_ (1,1) string = "Dark"
        BackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor_,0,1)} = [0.0 0.0 0.0]
        ForegroundColor_ (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor_,0,1)} = [1.0 1.0 1.0]
        HighlightColor_ (1,3) double {mustBeFinite,mustBeInRange(HighlightColor_,0,1)} = [1.0 1.0 1.0]
        FontSize_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 11
        FontName_ (1,1) string = "Consolas"
        PlotFontName_ (1,1) string = "Arial"
    end

    properties (Dependent)
        KeepAutoDisplayIntensity
        KeepAutoDisplayOrder
        LockDisplayIntensity
        LockDisplayOrder
        LockedDisplayRangeIntensity
        LockedDisplayRangeOrder
        OrderAutoScaleMethod

        % Deprecated aliases retained while older callers move to Keep Auto.
        AutoScaleDisplayIntensity
        AutoScaleDisplayOrder
        Theme
        BackgroundColor
        ForegroundColor
        HighlightColor
        FontSize
        FontName
        PlotFontName
    end

    events
        Changed
        DisplayChanged
    end

    methods

        function v = get.KeepAutoDisplayIntensity(obj)
        %GET.KEEPAUTODISPLAYINTENSITY Return the intensity navigation policy.

            v = obj.KeepAutoDisplayIntensity_;
        end

        function set.KeepAutoDisplayIntensity(obj,v)
        %SET.KEEPAUTODISPLAYINTENSITY Enable automatic intensity limits exclusively.

            obj.setExclusiveMode("Intensity","KeepAuto",v);
        end

        function v = get.KeepAutoDisplayOrder(obj)
        %GET.KEEPAUTODISPLAYORDER Return the order navigation policy.

            v = obj.KeepAutoDisplayOrder_;
        end

        function set.KeepAutoDisplayOrder(obj,v)
        %SET.KEEPAUTODISPLAYORDER Enable automatic order limits exclusively.

            obj.setExclusiveMode("Order","KeepAuto",v);
        end

        function v = get.LockDisplayIntensity(obj)
        %GET.LOCKDISPLAYINTENSITY Return whether one intensity range spans navigation.

            v = obj.LockDisplayIntensity_;
        end

        function set.LockDisplayIntensity(obj,v)
        %SET.LOCKDISPLAYINTENSITY Enable locked intensity limits exclusively.

            obj.setExclusiveMode("Intensity","Lock",v);
        end

        function v = get.LockDisplayOrder(obj)
        %GET.LOCKDISPLAYORDER Return whether one order range spans navigation.

            v = obj.LockDisplayOrder_;
        end

        function set.LockDisplayOrder(obj,v)
        %SET.LOCKDISPLAYORDER Enable locked order limits exclusively.

            obj.setExclusiveMode("Order","Lock",v);
        end

        function v = get.LockedDisplayRangeIntensity(obj)
        %GET.LOCKEDDISPLAYRANGEINTENSITY Return the shared locked intensity limits.

            v = obj.LockedDisplayRangeIntensity_;
        end

        function set.LockedDisplayRangeIntensity(obj,v)
        %SET.LOCKEDDISPLAYRANGEINTENSITY Validate and store shared intensity limits.

            obj.setDisplayRange("LockedDisplayRangeIntensity",v,false);
        end

        function v = get.LockedDisplayRangeOrder(obj)
        %GET.LOCKEDDISPLAYRANGEORDER Return the shared locked order limits.

            v = obj.LockedDisplayRangeOrder_;
        end

        function set.LockedDisplayRangeOrder(obj,v)
        %SET.LOCKEDDISPLAYRANGEORDER Validate and store shared order limits.

            obj.setDisplayRange("LockedDisplayRangeOrder",v,true);
        end

        function v = get.OrderAutoScaleMethod(obj)
        %GET.ORDERAUTOSCALEMETHOD Return the method used by Order Auto and Keep Auto.

            v = obj.OrderAutoScaleMethod_;
        end

        function set.OrderAutoScaleMethod(obj,v)
        %SET.ORDERAUTOSCALEMETHOD Validate and store the order scaling method.

            obj.setValue("OrderAutoScaleMethod",string(v));
        end

        function v = get.AutoScaleDisplayIntensity(obj)
        %GET.AUTOSCALEDISPLAYINTENSITY Return the legacy alias for Keep Auto.

            v = obj.KeepAutoDisplayIntensity;
        end

        function set.AutoScaleDisplayIntensity(obj,v)
        %SET.AUTOSCALEDISPLAYINTENSITY Forward the legacy alias to Keep Auto.

            obj.KeepAutoDisplayIntensity = v;
        end

        function v = get.AutoScaleDisplayOrder(obj)
        %GET.AUTOSCALEDISPLAYORDER Return the legacy alias for Keep Auto.

            v = obj.KeepAutoDisplayOrder;
        end

        function set.AutoScaleDisplayOrder(obj,v)
        %SET.AUTOSCALEDISPLAYORDER Forward the legacy alias to Keep Auto.

            obj.KeepAutoDisplayOrder = v;
        end

        function v = get.Theme(obj)
        %GET.THEME Return the stored Theme setting.

            v = obj.Theme_;
        end

        function set.Theme(obj,v)
        %SET.THEME Validate, store, and notify a Display setting change.

            obj.setValue("Theme",v);
        end

        function v = get.BackgroundColor(obj)
        %GET.BACKGROUNDCOLOR Return the stored BackgroundColor setting.

            v = obj.BackgroundColor_;
        end

        function set.BackgroundColor(obj,v)
        %SET.BACKGROUNDCOLOR Validate, store, and notify a Display setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("BackgroundColor",v);
        end

        function v = get.ForegroundColor(obj)
        %GET.FOREGROUNDCOLOR Return the stored ForegroundColor setting.

            v = obj.ForegroundColor_;
        end

        function set.ForegroundColor(obj,v)
        %SET.FOREGROUNDCOLOR Validate, store, and notify a Display setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("ForegroundColor",v);
        end

        function v = get.HighlightColor(obj)
        %GET.HIGHLIGHTCOLOR Return the stored HighlightColor setting.

            v = obj.HighlightColor_;
        end

        function set.HighlightColor(obj,v)
        %SET.HIGHLIGHTCOLOR Validate, store, and notify a Display setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("HighlightColor",v);
        end

        function v = get.FontSize(obj)
        %GET.FONTSIZE Return the stored FontSize setting.

            v = obj.FontSize_;
        end

        function set.FontSize(obj,v)
        %SET.FONTSIZE Validate, store, and notify a Display setting change.

            obj.setValue("FontSize",v);
        end

        function v = get.FontName(obj)
        %GET.FONTNAME Return the stored FontName setting.

            v = obj.FontName_;
        end

        function set.FontName(obj,v)
        %SET.FONTNAME Validate, store, and notify a Display setting change.

            obj.setValue("FontName",v);
        end

        function v = get.PlotFontName(obj)
        %GET.PLOTFONTNAME Return the stored PlotFontName setting.

            v = obj.PlotFontName_;
        end

        function set.PlotFontName(obj,v)
        %SET.PLOTFONTNAME Validate, store, and notify a Display setting change.

            obj.setValue("PlotFontName",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('KeepAutoDisplayIntensity',obj.KeepAutoDisplayIntensity, ...
                'KeepAutoDisplayOrder',obj.KeepAutoDisplayOrder, ...
                'LockDisplayIntensity',obj.LockDisplayIntensity, ...
                'LockDisplayOrder',obj.LockDisplayOrder, ...
                'LockedDisplayRangeIntensity',obj.LockedDisplayRangeIntensity, ...
                'LockedDisplayRangeOrder',obj.LockedDisplayRangeOrder, ...
                'OrderAutoScaleMethod',obj.OrderAutoScaleMethod, ...
                'Theme',obj.Theme, ...
                'BackgroundColor',obj.BackgroundColor, ...
                'ForegroundColor',obj.ForegroundColor, ...
                'HighlightColor',obj.HighlightColor, ...
                'FontSize',obj.FontSize, ...
                'FontName',obj.FontName, ...
                'PlotFontName',obj.PlotFontName);
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

        function setExclusiveMode(obj,domain,mode,value)
        %SETEXCLUSIVEMODE Store one display policy and disable its counterpart.

            validateattributes(value,{'logical','numeric'},{'scalar'});
            value = logical(value);

            % Setting names for the requested mode and the mutually exclusive mode.
            name = mode+"Display"+domain;

            if mode == "KeepAuto"
                other = "LockDisplay"+domain;
            else
                other = "KeepAutoDisplay"+domain;
            end

            obj.setValue(name,value);

            if value
                obj.setValue(other,false);
            end

        end

        function setDisplayRange(obj,name,value,unitRange)
        %SETDISPLAYRANGE Validate an optional two-element locked display range.

            if isempty(value)
                obj.setValue(name,[]);
                return;
            end

            validateattributes(value,{'numeric'},{'real','finite','vector','numel',2});
            value = sort(reshape(double(value),1,2));

            if value(1) >= value(2)
                error('oops:config:InvalidDisplayRange', ...
                    'Locked display limits must span a positive range.');
            end

            if unitRange && (value(1) < 0 || value(2) > 1)
                error('oops:config:InvalidDisplayRange', ...
                    'Locked order limits must lie between zero and one.');
            end

            obj.setValue(name,value);
        end

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
                ev = oops.config.ChangeEvent("Display",name,old,value);
                notify(obj,'DisplayChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
