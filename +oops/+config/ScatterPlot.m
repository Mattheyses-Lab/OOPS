% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ScatterPlot < handle
%SCATTERPLOT Appearance and variable selection for future object scatter plots.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        XVariable_ (1,1) string = "SBRatio"
        YVariable_ (1,1) string = "OrderAvg"
        BackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor_,0,1)} = [1.0 1.0 1.0]
        ForegroundColor_ (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor_,0,1)} = [0.0 0.0 0.0]
        LegendVisible_ (1,1) logical = false
        MarkerSize_ (1,1) double {mustBeFinite,mustBePositive} = 50.0
        ColorMode_ (1,1) string = "Group"
        MarkerFaceAlpha_ (1,1) double {mustBeFinite,mustBeInRange(MarkerFaceAlpha_,0,1)} = 1.0
        HullLineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 1.0
        HullFaceColor_ (1,3) double {mustBeFinite,mustBeInRange(HullFaceColor_,0,1)} = [1.0 1.0 1.0]
        HullFaceAlpha_ (1,1) double {mustBeFinite,mustBeInRange(HullFaceAlpha_,0,1)} = 0.5
        MarkerEdgeColorMode_ (1,1) string = "Custom"
        HullFaceColorMode_ (1,1) string = "auto"
        HullEdgeColorMode_ (1,1) string = "auto"
        MarkerEdgeColor_ (1,3) double {mustBeFinite,mustBeInRange(MarkerEdgeColor_,0,1)} = [0.0 0.0 0.0]
        HullEdgeColor_ (1,3) double {mustBeFinite,mustBeInRange(HullEdgeColor_,0,1)} = [0.0 0.0 0.0]
        HullVisible_ (1,1) logical = false
        MarkerEdgeAlpha_ (1,1) double {mustBeFinite,mustBeInRange(MarkerEdgeAlpha_,0,1)} = 1.0
        HullEdgeAlpha_ (1,1) double {mustBeFinite,mustBeInRange(HullEdgeAlpha_,0,1)} = 1.0
        HullType_ (1,1) string = "concave"
        GroupingType_ (1,1) string = "Group"
        MarkerMode_ (1,1) string = "single"
    end

    properties (Dependent)
        XVariable
        YVariable
        BackgroundColor
        ForegroundColor
        LegendVisible
        MarkerSize
        ColorMode
        MarkerFaceAlpha
        HullLineWidth
        HullFaceColor
        HullFaceAlpha
        MarkerEdgeColorMode
        HullFaceColorMode
        HullEdgeColorMode
        MarkerEdgeColor
        HullEdgeColor
        HullVisible
        MarkerEdgeAlpha
        HullEdgeAlpha
        HullType
        GroupingType
        MarkerMode
    end

    events
        Changed
        ScatterPlotChanged
    end

    methods

        function v = get.XVariable(obj)
        %GET.XVARIABLE Return the stored XVariable setting.

            v = obj.XVariable_;
        end

        function set.XVariable(obj,v)
        %SET.XVARIABLE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("XVariable",v);
        end

        function v = get.YVariable(obj)
        %GET.YVARIABLE Return the stored YVariable setting.

            v = obj.YVariable_;
        end

        function set.YVariable(obj,v)
        %SET.YVARIABLE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("YVariable",v);
        end

        function v = get.BackgroundColor(obj)
        %GET.BACKGROUNDCOLOR Return the stored BackgroundColor setting.

            v = obj.BackgroundColor_;
        end

        function set.BackgroundColor(obj,v)
        %SET.BACKGROUNDCOLOR Validate, store, and notify a ScatterPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("BackgroundColor",v);
        end

        function v = get.ForegroundColor(obj)
        %GET.FOREGROUNDCOLOR Return the stored ForegroundColor setting.

            v = obj.ForegroundColor_;
        end

        function set.ForegroundColor(obj,v)
        %SET.FOREGROUNDCOLOR Validate, store, and notify a ScatterPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("ForegroundColor",v);
        end

        function v = get.LegendVisible(obj)
        %GET.LEGENDVISIBLE Return the stored LegendVisible setting.

            v = obj.LegendVisible_;
        end

        function set.LegendVisible(obj,v)
        %SET.LEGENDVISIBLE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("LegendVisible",v);
        end

        function v = get.MarkerSize(obj)
        %GET.MARKERSIZE Return the stored MarkerSize setting.

            v = obj.MarkerSize_;
        end

        function set.MarkerSize(obj,v)
        %SET.MARKERSIZE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("MarkerSize",v);
        end

        function v = get.ColorMode(obj)
        %GET.COLORMODE Return the stored ColorMode setting.

            v = obj.ColorMode_;
        end

        function set.ColorMode(obj,v)
        %SET.COLORMODE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("ColorMode",v);
        end

        function v = get.MarkerFaceAlpha(obj)
        %GET.MARKERFACEALPHA Return the stored MarkerFaceAlpha setting.

            v = obj.MarkerFaceAlpha_;
        end

        function set.MarkerFaceAlpha(obj,v)
        %SET.MARKERFACEALPHA Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("MarkerFaceAlpha",v);
        end

        function v = get.HullLineWidth(obj)
        %GET.HULLLINEWIDTH Return the stored HullLineWidth setting.

            v = obj.HullLineWidth_;
        end

        function set.HullLineWidth(obj,v)
        %SET.HULLLINEWIDTH Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("HullLineWidth",v);
        end

        function v = get.HullFaceColor(obj)
        %GET.HULLFACECOLOR Return the stored HullFaceColor setting.

            v = obj.HullFaceColor_;
        end

        function set.HullFaceColor(obj,v)
        %SET.HULLFACECOLOR Validate, store, and notify a ScatterPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("HullFaceColor",v);
        end

        function v = get.HullFaceAlpha(obj)
        %GET.HULLFACEALPHA Return the stored HullFaceAlpha setting.

            v = obj.HullFaceAlpha_;
        end

        function set.HullFaceAlpha(obj,v)
        %SET.HULLFACEALPHA Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("HullFaceAlpha",v);
        end

        function v = get.MarkerEdgeColorMode(obj)
        %GET.MARKEREDGECOLORMODE Return the stored MarkerEdgeColorMode setting.

            v = obj.MarkerEdgeColorMode_;
        end

        function set.MarkerEdgeColorMode(obj,v)
        %SET.MARKEREDGECOLORMODE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("MarkerEdgeColorMode",v);
        end

        function v = get.HullFaceColorMode(obj)
        %GET.HULLFACECOLORMODE Return the stored HullFaceColorMode setting.

            v = obj.HullFaceColorMode_;
        end

        function set.HullFaceColorMode(obj,v)
        %SET.HULLFACECOLORMODE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("HullFaceColorMode",v);
        end

        function v = get.HullEdgeColorMode(obj)
        %GET.HULLEDGECOLORMODE Return the stored HullEdgeColorMode setting.

            v = obj.HullEdgeColorMode_;
        end

        function set.HullEdgeColorMode(obj,v)
        %SET.HULLEDGECOLORMODE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("HullEdgeColorMode",v);
        end

        function v = get.MarkerEdgeColor(obj)
        %GET.MARKEREDGECOLOR Return the stored MarkerEdgeColor setting.

            v = obj.MarkerEdgeColor_;
        end

        function set.MarkerEdgeColor(obj,v)
        %SET.MARKEREDGECOLOR Validate, store, and notify a ScatterPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("MarkerEdgeColor",v);
        end

        function v = get.HullEdgeColor(obj)
        %GET.HULLEDGECOLOR Return the stored HullEdgeColor setting.

            v = obj.HullEdgeColor_;
        end

        function set.HullEdgeColor(obj,v)
        %SET.HULLEDGECOLOR Validate, store, and notify a ScatterPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("HullEdgeColor",v);
        end

        function v = get.HullVisible(obj)
        %GET.HULLVISIBLE Return the stored HullVisible setting.

            v = obj.HullVisible_;
        end

        function set.HullVisible(obj,v)
        %SET.HULLVISIBLE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("HullVisible",v);
        end

        function v = get.MarkerEdgeAlpha(obj)
        %GET.MARKEREDGEALPHA Return the stored MarkerEdgeAlpha setting.

            v = obj.MarkerEdgeAlpha_;
        end

        function set.MarkerEdgeAlpha(obj,v)
        %SET.MARKEREDGEALPHA Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("MarkerEdgeAlpha",v);
        end

        function v = get.HullEdgeAlpha(obj)
        %GET.HULLEDGEALPHA Return the stored HullEdgeAlpha setting.

            v = obj.HullEdgeAlpha_;
        end

        function set.HullEdgeAlpha(obj,v)
        %SET.HULLEDGEALPHA Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("HullEdgeAlpha",v);
        end

        function v = get.HullType(obj)
        %GET.HULLTYPE Return the stored HullType setting.

            v = obj.HullType_;
        end

        function set.HullType(obj,v)
        %SET.HULLTYPE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("HullType",v);
        end

        function v = get.GroupingType(obj)
        %GET.GROUPINGTYPE Return the stored GroupingType setting.

            v = obj.GroupingType_;
        end

        function set.GroupingType(obj,v)
        %SET.GROUPINGTYPE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("GroupingType",v);
        end

        function v = get.MarkerMode(obj)
        %GET.MARKERMODE Return the stored MarkerMode setting.

            v = obj.MarkerMode_;
        end

        function set.MarkerMode(obj,v)
        %SET.MARKERMODE Validate, store, and notify a ScatterPlot setting change.

            obj.setValue("MarkerMode",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('XVariable',obj.XVariable, ...
                'YVariable',obj.YVariable, ...
                'BackgroundColor',obj.BackgroundColor, ...
                'ForegroundColor',obj.ForegroundColor, ...
                'LegendVisible',obj.LegendVisible, ...
                'MarkerSize',obj.MarkerSize, ...
                'ColorMode',obj.ColorMode, ...
                'MarkerFaceAlpha',obj.MarkerFaceAlpha, ...
                'HullLineWidth',obj.HullLineWidth, ...
                'HullFaceColor',obj.HullFaceColor, ...
                'HullFaceAlpha',obj.HullFaceAlpha, ...
                'MarkerEdgeColorMode',obj.MarkerEdgeColorMode, ...
                'HullFaceColorMode',obj.HullFaceColorMode, ...
                'HullEdgeColorMode',obj.HullEdgeColorMode, ...
                'MarkerEdgeColor',obj.MarkerEdgeColor, ...
                'HullEdgeColor',obj.HullEdgeColor, ...
                'HullVisible',obj.HullVisible, ...
                'MarkerEdgeAlpha',obj.MarkerEdgeAlpha, ...
                'HullEdgeAlpha',obj.HullEdgeAlpha, ...
                'HullType',obj.HullType, ...
                'GroupingType',obj.GroupingType, ...
                'MarkerMode',obj.MarkerMode);
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
                ev = oops.config.ChangeEvent("ScatterPlot",name,old,value);
                notify(obj,'ScatterPlotChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
