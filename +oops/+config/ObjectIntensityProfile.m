% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectIntensityProfile < handle
%OBJECTINTENSITYPROFILE Appearance of future polarization-response profile plots.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        FitLineColor_ (1,3) double {mustBeFinite,mustBeInRange(FitLineColor_,0,1)} = [0.0 0.0 0.0]
        PixelLinesColor_ (1,3) double {mustBeFinite,mustBeInRange(PixelLinesColor_,0,1)} = [0.5019607843137255 0.5019607843137255 0.5019607843137255]
        BackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor_,0,1)} = [1.0 1.0 1.0]
        ForegroundColor_ (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor_,0,1)} = [0.0 0.0 0.0]
        AnnotationsColor_ (1,3) double {mustBeFinite,mustBeInRange(AnnotationsColor_,0,1)} = [0.0 0.0 0.0]
        AzimuthLinesColor_ (1,3) double {mustBeFinite,mustBeInRange(AzimuthLinesColor_,0,1)} = [0.5 0.5 1.0]
    end

    properties (Dependent)
        FitLineColor
        PixelLinesColor
        BackgroundColor
        ForegroundColor
        AnnotationsColor
        AzimuthLinesColor
    end

    events
        Changed
        ObjectIntensityProfileChanged
    end

    methods

        function v = get.FitLineColor(obj)
        %GET.FITLINECOLOR Return the stored FitLineColor setting.

            v = obj.FitLineColor_;
        end

        function set.FitLineColor(obj,v)
        %SET.FITLINECOLOR Validate, store, and notify a ObjectIntensityProfile setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("FitLineColor",v);
        end

        function v = get.PixelLinesColor(obj)
        %GET.PIXELLINESCOLOR Return the stored PixelLinesColor setting.

            v = obj.PixelLinesColor_;
        end

        function set.PixelLinesColor(obj,v)
        %SET.PIXELLINESCOLOR Validate, store, and notify a ObjectIntensityProfile setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("PixelLinesColor",v);
        end

        function v = get.BackgroundColor(obj)
        %GET.BACKGROUNDCOLOR Return the stored BackgroundColor setting.

            v = obj.BackgroundColor_;
        end

        function set.BackgroundColor(obj,v)
        %SET.BACKGROUNDCOLOR Validate, store, and notify a ObjectIntensityProfile setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("BackgroundColor",v);
        end

        function v = get.ForegroundColor(obj)
        %GET.FOREGROUNDCOLOR Return the stored ForegroundColor setting.

            v = obj.ForegroundColor_;
        end

        function set.ForegroundColor(obj,v)
        %SET.FOREGROUNDCOLOR Validate, store, and notify a ObjectIntensityProfile setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("ForegroundColor",v);
        end

        function v = get.AnnotationsColor(obj)
        %GET.ANNOTATIONSCOLOR Return the stored AnnotationsColor setting.

            v = obj.AnnotationsColor_;
        end

        function set.AnnotationsColor(obj,v)
        %SET.ANNOTATIONSCOLOR Validate, store, and notify a ObjectIntensityProfile setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("AnnotationsColor",v);
        end

        function v = get.AzimuthLinesColor(obj)
        %GET.AZIMUTHLINESCOLOR Return the stored AzimuthLinesColor setting.

            v = obj.AzimuthLinesColor_;
        end

        function set.AzimuthLinesColor(obj,v)
        %SET.AZIMUTHLINESCOLOR Validate, store, and notify a ObjectIntensityProfile setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("AzimuthLinesColor",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('FitLineColor',obj.FitLineColor, ...
                'PixelLinesColor',obj.PixelLinesColor, ...
                'BackgroundColor',obj.BackgroundColor, ...
                'ForegroundColor',obj.ForegroundColor, ...
                'AnnotationsColor',obj.AnnotationsColor, ...
                'AzimuthLinesColor',obj.AzimuthLinesColor);
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
                ev = oops.config.ChangeEvent("ObjectIntensityProfile",name,old,value);
                notify(obj,'ObjectIntensityProfileChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
