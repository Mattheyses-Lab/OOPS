% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Display < handle
%DISPLAY General image and application appearance; no UI handles or view state.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        AutoScaleDisplayIntensity_ (1,1) logical = true
        AutoScaleDisplayOrder_ (1,1) logical = true
        Theme_ (1,1) string = "Dark"
        BackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor_,0,1)} = [0.0 0.0 0.0]
        ForegroundColor_ (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor_,0,1)} = [1.0 1.0 1.0]
        HighlightColor_ (1,3) double {mustBeFinite,mustBeInRange(HighlightColor_,0,1)} = [1.0 1.0 1.0]
        FontSize_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 11
        FontName_ (1,1) string = "Consolas"
        PlotFontName_ (1,1) string = "Arial"
    end

    properties (Dependent)
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

        function v = get.AutoScaleDisplayIntensity(obj)
        %GET.AUTOSCALEDISPLAYINTENSITY Return the stored AutoScaleDisplayIntensity setting.

            v = obj.AutoScaleDisplayIntensity_;
        end

        function set.AutoScaleDisplayIntensity(obj,v)
        %SET.AUTOSCALEDISPLAYINTENSITY Validate, store, and notify a Display setting change.

            obj.setValue("AutoScaleDisplayIntensity",v);
        end

        function v = get.AutoScaleDisplayOrder(obj)
        %GET.AUTOSCALEDISPLAYORDER Return the project-wide order auto-scale policy.

            v = obj.AutoScaleDisplayOrder_;
        end

        function set.AutoScaleDisplayOrder(obj,v)
        %SET.AUTOSCALEDISPLAYORDER Validate and notify independently of intensity.

            obj.setValue("AutoScaleDisplayOrder",v);
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
            S = struct('AutoScaleDisplayIntensity',obj.AutoScaleDisplayIntensity, ...
                'AutoScaleDisplayOrder',obj.AutoScaleDisplayOrder, ...
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
