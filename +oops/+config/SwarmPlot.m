% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef SwarmPlot < handle
%SWARMPLOT Appearance and variable selection for future object swarm plots.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        GroupingType_ (1,1) string = "Group"
        ColorMode_ (1,1) string = "Group"
        YVariable_ (1,1) string = "OrderAvg"
        BackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor_,0,1)} = [1.0 1.0 1.0]
        ForegroundColor_ (1,3) double {mustBeFinite,mustBeInRange(ForegroundColor_,0,1)} = [0.0 0.0 0.0]
        MarkerFaceAlpha_ (1,1) double {mustBeFinite,mustBeInRange(MarkerFaceAlpha_,0,1)} = 1.0
        MarkerSize_ (1,1) double {mustBeFinite,mustBePositive} = 50.0
        ErrorBarsVisible_ (1,1) logical = true
        PointsVisible_ (1,1) logical = true
        MarkerEdgeColorMode_ (1,1) string = "Custom"
        XJitterWidth_ (1,1) double {mustBeFinite,mustBeInRange(XJitterWidth_,0,1)} = 0.6
        ViolinEdgeColorMode_ (1,1) string = "auto"
        ViolinEdgeColor_ (1,3) double {mustBeFinite,mustBeInRange(ViolinEdgeColor_,0,1)} = [0.0 0.0 0.0]
        MarkerEdgeColor_ (1,3) double {mustBeFinite,mustBeInRange(MarkerEdgeColor_,0,1)} = [0.0 0.0 0.0]
        ViolinFaceColorMode_ (1,1) string = "auto"
        ViolinFaceColor_ (1,3) double {mustBeFinite,mustBeInRange(ViolinFaceColor_,0,1)} = [1.0 1.0 1.0]
        ErrorBarsColor_ (1,3) double {mustBeFinite,mustBeInRange(ErrorBarsColor_,0,1)} = [0.0 0.0 0.0]
        ErrorBarsColorMode_ (1,1) string = "Custom"
        ViolinOutlinesVisible_ (1,1) logical = true
    end

    properties (Dependent)
        GroupingType
        ColorMode
        YVariable
        BackgroundColor
        ForegroundColor
        MarkerFaceAlpha
        MarkerSize
        ErrorBarsVisible
        PointsVisible
        MarkerEdgeColorMode
        XJitterWidth
        ViolinEdgeColorMode
        ViolinEdgeColor
        MarkerEdgeColor
        ViolinFaceColorMode
        ViolinFaceColor
        ErrorBarsColor
        ErrorBarsColorMode
        ViolinOutlinesVisible
    end

    events
        Changed
        SwarmPlotChanged
    end

    methods

        function v = get.GroupingType(obj)
        %GET.GROUPINGTYPE Return the stored GroupingType setting.

            v = obj.GroupingType_;
        end

        function set.GroupingType(obj,v)
        %SET.GROUPINGTYPE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("GroupingType",v);
        end

        function v = get.ColorMode(obj)
        %GET.COLORMODE Return the stored ColorMode setting.

            v = obj.ColorMode_;
        end

        function set.ColorMode(obj,v)
        %SET.COLORMODE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("ColorMode",v);
        end

        function v = get.YVariable(obj)
        %GET.YVARIABLE Return the stored YVariable setting.

            v = obj.YVariable_;
        end

        function set.YVariable(obj,v)
        %SET.YVARIABLE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("YVariable",v);
        end

        function v = get.BackgroundColor(obj)
        %GET.BACKGROUNDCOLOR Return the stored BackgroundColor setting.

            v = obj.BackgroundColor_;
        end

        function set.BackgroundColor(obj,v)
        %SET.BACKGROUNDCOLOR Validate, store, and notify a SwarmPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("BackgroundColor",v);
        end

        function v = get.ForegroundColor(obj)
        %GET.FOREGROUNDCOLOR Return the stored ForegroundColor setting.

            v = obj.ForegroundColor_;
        end

        function set.ForegroundColor(obj,v)
        %SET.FOREGROUNDCOLOR Validate, store, and notify a SwarmPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("ForegroundColor",v);
        end

        function v = get.MarkerFaceAlpha(obj)
        %GET.MARKERFACEALPHA Return the stored MarkerFaceAlpha setting.

            v = obj.MarkerFaceAlpha_;
        end

        function set.MarkerFaceAlpha(obj,v)
        %SET.MARKERFACEALPHA Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("MarkerFaceAlpha",v);
        end

        function v = get.MarkerSize(obj)
        %GET.MARKERSIZE Return the stored MarkerSize setting.

            v = obj.MarkerSize_;
        end

        function set.MarkerSize(obj,v)
        %SET.MARKERSIZE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("MarkerSize",v);
        end

        function v = get.ErrorBarsVisible(obj)
        %GET.ERRORBARSVISIBLE Return the stored ErrorBarsVisible setting.

            v = obj.ErrorBarsVisible_;
        end

        function set.ErrorBarsVisible(obj,v)
        %SET.ERRORBARSVISIBLE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("ErrorBarsVisible",v);
        end

        function v = get.PointsVisible(obj)
        %GET.POINTSVISIBLE Return the stored PointsVisible setting.

            v = obj.PointsVisible_;
        end

        function set.PointsVisible(obj,v)
        %SET.POINTSVISIBLE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("PointsVisible",v);
        end

        function v = get.MarkerEdgeColorMode(obj)
        %GET.MARKEREDGECOLORMODE Return the stored MarkerEdgeColorMode setting.

            v = obj.MarkerEdgeColorMode_;
        end

        function set.MarkerEdgeColorMode(obj,v)
        %SET.MARKEREDGECOLORMODE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("MarkerEdgeColorMode",v);
        end

        function v = get.XJitterWidth(obj)
        %GET.XJITTERWIDTH Return the stored XJitterWidth setting.

            v = obj.XJitterWidth_;
        end

        function set.XJitterWidth(obj,v)
        %SET.XJITTERWIDTH Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("XJitterWidth",v);
        end

        function v = get.ViolinEdgeColorMode(obj)
        %GET.VIOLINEDGECOLORMODE Return the stored ViolinEdgeColorMode setting.

            v = obj.ViolinEdgeColorMode_;
        end

        function set.ViolinEdgeColorMode(obj,v)
        %SET.VIOLINEDGECOLORMODE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("ViolinEdgeColorMode",v);
        end

        function v = get.ViolinEdgeColor(obj)
        %GET.VIOLINEDGECOLOR Return the stored ViolinEdgeColor setting.

            v = obj.ViolinEdgeColor_;
        end

        function set.ViolinEdgeColor(obj,v)
        %SET.VIOLINEDGECOLOR Validate, store, and notify a SwarmPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("ViolinEdgeColor",v);
        end

        function v = get.MarkerEdgeColor(obj)
        %GET.MARKEREDGECOLOR Return the stored MarkerEdgeColor setting.

            v = obj.MarkerEdgeColor_;
        end

        function set.MarkerEdgeColor(obj,v)
        %SET.MARKEREDGECOLOR Validate, store, and notify a SwarmPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("MarkerEdgeColor",v);
        end

        function v = get.ViolinFaceColorMode(obj)
        %GET.VIOLINFACECOLORMODE Return the stored ViolinFaceColorMode setting.

            v = obj.ViolinFaceColorMode_;
        end

        function set.ViolinFaceColorMode(obj,v)
        %SET.VIOLINFACECOLORMODE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("ViolinFaceColorMode",v);
        end

        function v = get.ViolinFaceColor(obj)
        %GET.VIOLINFACECOLOR Return the stored ViolinFaceColor setting.

            v = obj.ViolinFaceColor_;
        end

        function set.ViolinFaceColor(obj,v)
        %SET.VIOLINFACECOLOR Validate, store, and notify a SwarmPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("ViolinFaceColor",v);
        end

        function v = get.ErrorBarsColor(obj)
        %GET.ERRORBARSCOLOR Return the stored ErrorBarsColor setting.

            v = obj.ErrorBarsColor_;
        end

        function set.ErrorBarsColor(obj,v)
        %SET.ERRORBARSCOLOR Validate, store, and notify a SwarmPlot setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("ErrorBarsColor",v);
        end

        function v = get.ErrorBarsColorMode(obj)
        %GET.ERRORBARSCOLORMODE Return the stored ErrorBarsColorMode setting.

            v = obj.ErrorBarsColorMode_;
        end

        function set.ErrorBarsColorMode(obj,v)
        %SET.ERRORBARSCOLORMODE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("ErrorBarsColorMode",v);
        end

        function v = get.ViolinOutlinesVisible(obj)
        %GET.VIOLINOUTLINESVISIBLE Return the stored ViolinOutlinesVisible setting.

            v = obj.ViolinOutlinesVisible_;
        end

        function set.ViolinOutlinesVisible(obj,v)
        %SET.VIOLINOUTLINESVISIBLE Validate, store, and notify a SwarmPlot setting change.

            obj.setValue("ViolinOutlinesVisible",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('GroupingType',obj.GroupingType, ...
                'ColorMode',obj.ColorMode, ...
                'YVariable',obj.YVariable, ...
                'BackgroundColor',obj.BackgroundColor, ...
                'ForegroundColor',obj.ForegroundColor, ...
                'MarkerFaceAlpha',obj.MarkerFaceAlpha, ...
                'MarkerSize',obj.MarkerSize, ...
                'ErrorBarsVisible',obj.ErrorBarsVisible, ...
                'PointsVisible',obj.PointsVisible, ...
                'MarkerEdgeColorMode',obj.MarkerEdgeColorMode, ...
                'XJitterWidth',obj.XJitterWidth, ...
                'ViolinEdgeColorMode',obj.ViolinEdgeColorMode, ...
                'ViolinEdgeColor',obj.ViolinEdgeColor, ...
                'MarkerEdgeColor',obj.MarkerEdgeColor, ...
                'ViolinFaceColorMode',obj.ViolinFaceColorMode, ...
                'ViolinFaceColor',obj.ViolinFaceColor, ...
                'ErrorBarsColor',obj.ErrorBarsColor, ...
                'ErrorBarsColorMode',obj.ErrorBarsColorMode, ...
                'ViolinOutlinesVisible',obj.ViolinOutlinesVisible);
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
                ev = oops.config.ChangeEvent("SwarmPlot",name,old,value);
                notify(obj,'SwarmPlotChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
