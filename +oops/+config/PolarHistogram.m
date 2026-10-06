% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef PolarHistogram < handle
%POLARHISTOGRAM Appearance and variable selection for future polar histograms.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        nBins_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 48
        WedgeFaceAlpha_ (1,1) double {mustBeFinite,mustBeInRange(WedgeFaceAlpha_,0,1)} = 0.8
        WedgeFaceColor_ (1,1) string = "flat"
        WedgeLineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 1.0
        GridlinesColor_ (1,3) double {mustBeFinite,mustBeInRange(GridlinesColor_,0,1)} = [0.9 0.9 0.9]
        LabelsColor_ (1,3) double {mustBeFinite,mustBeInRange(LabelsColor_,0,1)} = [0.0 0.0 0.0]
        CircleColor_ (1,3) double {mustBeFinite,mustBeInRange(CircleColor_,0,1)} = [0.0 0.0 0.0]
        GridlinesLineWidth_ (1,1) double {mustBeFinite,mustBePositive} = 1.0
        CircleBackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(CircleBackgroundColor_,0,1)} = [1.0 1.0 1.0]
        BackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor_,0,1)} = [1.0 1.0 1.0]
        Variable_ (1,1) string = "MidlineRelativeAzimuth"
        WedgeEdgeColorMode_ (1,1) string = "flat"
        WedgeEdgeColor_ (1,3) double {mustBeFinite,mustBeInRange(WedgeEdgeColor_,0,1)} = [0.0 0.0 0.0]
    end

    properties (Dependent)
        nBins
        WedgeFaceAlpha
        WedgeFaceColor
        WedgeLineWidth
        GridlinesColor
        LabelsColor
        CircleColor
        GridlinesLineWidth
        CircleBackgroundColor
        BackgroundColor
        Variable
        WedgeEdgeColorMode
        WedgeEdgeColor
    end

    events
        Changed
        PolarHistogramChanged
    end

    methods

        function v = get.nBins(obj)
        %GET.NBINS Return the stored nBins setting.

            v = obj.nBins_;
        end

        function set.nBins(obj,v)
        %SET.NBINS Validate, store, and notify a PolarHistogram setting change.

            obj.setValue("nBins",v);
        end

        function v = get.WedgeFaceAlpha(obj)
        %GET.WEDGEFACEALPHA Return the stored WedgeFaceAlpha setting.

            v = obj.WedgeFaceAlpha_;
        end

        function set.WedgeFaceAlpha(obj,v)
        %SET.WEDGEFACEALPHA Validate, store, and notify a PolarHistogram setting change.

            obj.setValue("WedgeFaceAlpha",v);
        end

        function v = get.WedgeFaceColor(obj)
        %GET.WEDGEFACECOLOR Return the stored WedgeFaceColor setting.

            v = obj.WedgeFaceColor_;
        end

        function set.WedgeFaceColor(obj,v)
        %SET.WEDGEFACECOLOR Validate, store, and notify a PolarHistogram setting change.

            obj.setValue("WedgeFaceColor",v);
        end

        function v = get.WedgeLineWidth(obj)
        %GET.WEDGELINEWIDTH Return the stored WedgeLineWidth setting.

            v = obj.WedgeLineWidth_;
        end

        function set.WedgeLineWidth(obj,v)
        %SET.WEDGELINEWIDTH Validate, store, and notify a PolarHistogram setting change.

            obj.setValue("WedgeLineWidth",v);
        end

        function v = get.GridlinesColor(obj)
        %GET.GRIDLINESCOLOR Return the stored GridlinesColor setting.

            v = obj.GridlinesColor_;
        end

        function set.GridlinesColor(obj,v)
        %SET.GRIDLINESCOLOR Validate, store, and notify a PolarHistogram setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("GridlinesColor",v);
        end

        function v = get.LabelsColor(obj)
        %GET.LABELSCOLOR Return the stored LabelsColor setting.

            v = obj.LabelsColor_;
        end

        function set.LabelsColor(obj,v)
        %SET.LABELSCOLOR Validate, store, and notify a PolarHistogram setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("LabelsColor",v);
        end

        function v = get.CircleColor(obj)
        %GET.CIRCLECOLOR Return the stored CircleColor setting.

            v = obj.CircleColor_;
        end

        function set.CircleColor(obj,v)
        %SET.CIRCLECOLOR Validate, store, and notify a PolarHistogram setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("CircleColor",v);
        end

        function v = get.GridlinesLineWidth(obj)
        %GET.GRIDLINESLINEWIDTH Return the stored GridlinesLineWidth setting.

            v = obj.GridlinesLineWidth_;
        end

        function set.GridlinesLineWidth(obj,v)
        %SET.GRIDLINESLINEWIDTH Validate, store, and notify a PolarHistogram setting change.

            obj.setValue("GridlinesLineWidth",v);
        end

        function v = get.CircleBackgroundColor(obj)
        %GET.CIRCLEBACKGROUNDCOLOR Return the stored CircleBackgroundColor setting.

            v = obj.CircleBackgroundColor_;
        end

        function set.CircleBackgroundColor(obj,v)
        %SET.CIRCLEBACKGROUNDCOLOR Validate, store, and notify a PolarHistogram setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("CircleBackgroundColor",v);
        end

        function v = get.BackgroundColor(obj)
        %GET.BACKGROUNDCOLOR Return the stored BackgroundColor setting.

            v = obj.BackgroundColor_;
        end

        function set.BackgroundColor(obj,v)
        %SET.BACKGROUNDCOLOR Validate, store, and notify a PolarHistogram setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("BackgroundColor",v);
        end

        function v = get.Variable(obj)
        %GET.VARIABLE Return the stored Variable setting.

            v = obj.Variable_;
        end

        function set.Variable(obj,v)
        %SET.VARIABLE Validate, store, and notify a PolarHistogram setting change.

            obj.setValue("Variable",v);
        end

        function v = get.WedgeEdgeColorMode(obj)
        %GET.WEDGEEDGECOLORMODE Return the stored WedgeEdgeColorMode setting.

            v = obj.WedgeEdgeColorMode_;
        end

        function set.WedgeEdgeColorMode(obj,v)
        %SET.WEDGEEDGECOLORMODE Validate, store, and notify a PolarHistogram setting change.

            obj.setValue("WedgeEdgeColorMode",v);
        end

        function v = get.WedgeEdgeColor(obj)
        %GET.WEDGEEDGECOLOR Return the stored WedgeEdgeColor setting.

            v = obj.WedgeEdgeColor_;
        end

        function set.WedgeEdgeColor(obj,v)
        %SET.WEDGEEDGECOLOR Validate, store, and notify a PolarHistogram setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("WedgeEdgeColor",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('nBins',obj.nBins, ...
                'WedgeFaceAlpha',obj.WedgeFaceAlpha, ...
                'WedgeFaceColor',obj.WedgeFaceColor, ...
                'WedgeLineWidth',obj.WedgeLineWidth, ...
                'GridlinesColor',obj.GridlinesColor, ...
                'LabelsColor',obj.LabelsColor, ...
                'CircleColor',obj.CircleColor, ...
                'GridlinesLineWidth',obj.GridlinesLineWidth, ...
                'CircleBackgroundColor',obj.CircleBackgroundColor, ...
                'BackgroundColor',obj.BackgroundColor, ...
                'Variable',obj.Variable, ...
                'WedgeEdgeColorMode',obj.WedgeEdgeColorMode, ...
                'WedgeEdgeColor',obj.WedgeEdgeColor);
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
                ev = oops.config.ChangeEvent("PolarHistogram",name,old,value);
                notify(obj,'PolarHistogramChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
