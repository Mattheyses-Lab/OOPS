% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef PolarHistogram < handle
%POLARHISTOGRAM Data selection and appearance for the polar histogram.

    properties (Access=private)
        DataSource_ (1,1) string {mustBeMember(DataSource_,["Group","Image"])} = "Group"
        Variable_ (1,1) string = "MidlineRelativeAzimuthMean"
        BinCount_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 24
        WedgeFaceAlpha_ (1,1) double {mustBeFinite,mustBeInRange(WedgeFaceAlpha_,0,1)} = .75
        WedgeFaceColorMode_ (1,1) string {mustBeMember(WedgeFaceColorMode_,["flat","interp","custom"])} = "flat"
        WedgeFaceColor_ (1,3) double {mustBeFinite,mustBeInRange(WedgeFaceColor_,0,1)} = [0 0.4470 0.7410]
        WedgeEdgeColorMode_ (1,1) string {mustBeMember(WedgeEdgeColorMode_,["flat","interp","custom"])} = "flat"
        WedgeEdgeColor_ (1,3) double {mustBeFinite,mustBeInRange(WedgeEdgeColor_,0,1)} = [0 0 0]
        WedgeLineWidth_ (1,1) double {mustBeFinite,mustBeNonnegative} = 1
        GridlinesColor_ (1,3) double {mustBeFinite,mustBeInRange(GridlinesColor_,0,1)} = [.9 .9 .9]
        LabelsColor_ (1,3) double {mustBeFinite,mustBeInRange(LabelsColor_,0,1)} = [0 0 0]
        GridlinesLineWidth_ (1,1) double {mustBeFinite,mustBeNonnegative} = .5
        CircleBackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(CircleBackgroundColor_,0,1)} = [1 1 1]
        CircleColor_ (1,3) double {mustBeFinite,mustBeInRange(CircleColor_,0,1)} = [0 0 0]
        BackgroundColor_ (1,3) double {mustBeFinite,mustBeInRange(BackgroundColor_,0,1)} = [1 1 1]
    end

    properties (Dependent)
        DataSource
        Variable
        BinCount
        WedgeFaceAlpha
        WedgeFaceColorMode
        WedgeFaceColor
        WedgeEdgeColorMode
        WedgeEdgeColor
        WedgeLineWidth
        GridlinesColor
        LabelsColor
        GridlinesLineWidth
        CircleBackgroundColor
        CircleColor
        BackgroundColor
    end

    events
        Changed
        PolarHistogramChanged
    end

    methods
        function value = get.DataSource(obj), value = obj.DataSource_; end
        function set.DataSource(obj,value), obj.setValue("DataSource",value); end
        function value = get.Variable(obj), value = obj.Variable_; end
        function set.Variable(obj,value), obj.setValue("Variable",value); end
        function value = get.BinCount(obj), value = obj.BinCount_; end
        function set.BinCount(obj,value), obj.setValue("BinCount",value); end
        function value = get.WedgeFaceAlpha(obj), value = obj.WedgeFaceAlpha_; end
        function set.WedgeFaceAlpha(obj,value), obj.setValue("WedgeFaceAlpha",value); end
        function value = get.WedgeFaceColorMode(obj), value = obj.WedgeFaceColorMode_; end
        function set.WedgeFaceColorMode(obj,value), obj.setValue("WedgeFaceColorMode",value); end
        function value = get.WedgeFaceColor(obj), value = obj.WedgeFaceColor_; end
        function set.WedgeFaceColor(obj,value), obj.setColor("WedgeFaceColor",value); end
        function value = get.WedgeEdgeColorMode(obj), value = obj.WedgeEdgeColorMode_; end
        function set.WedgeEdgeColorMode(obj,value), obj.setValue("WedgeEdgeColorMode",value); end
        function value = get.WedgeEdgeColor(obj), value = obj.WedgeEdgeColor_; end
        function set.WedgeEdgeColor(obj,value), obj.setColor("WedgeEdgeColor",value); end
        function value = get.WedgeLineWidth(obj), value = obj.WedgeLineWidth_; end
        function set.WedgeLineWidth(obj,value), obj.setValue("WedgeLineWidth",value); end
        function value = get.GridlinesColor(obj), value = obj.GridlinesColor_; end
        function set.GridlinesColor(obj,value), obj.setColor("GridlinesColor",value); end
        function value = get.LabelsColor(obj), value = obj.LabelsColor_; end
        function set.LabelsColor(obj,value), obj.setColor("LabelsColor",value); end
        function value = get.GridlinesLineWidth(obj), value = obj.GridlinesLineWidth_; end
        function set.GridlinesLineWidth(obj,value), obj.setValue("GridlinesLineWidth",value); end
        function value = get.CircleBackgroundColor(obj), value = obj.CircleBackgroundColor_; end
        function set.CircleBackgroundColor(obj,value), obj.setColor("CircleBackgroundColor",value); end
        function value = get.CircleColor(obj), value = obj.CircleColor_; end
        function set.CircleColor(obj,value), obj.setColor("CircleColor",value); end
        function value = get.BackgroundColor(obj), value = obj.BackgroundColor_; end
        function set.BackgroundColor(obj,value), obj.setColor("BackgroundColor",value); end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics handles.

            names = string(properties(obj));
            S = struct();

            for k = 1:numel(names)
                S.(names(k)) = obj.(names(k));
            end
        end

        function fromStruct(obj,S)
        %FROMSTRUCT Restore recognized settings through validated setters.

            validateattributes(S,{'struct'},{'scalar'});
            names = string(fieldnames(obj.toStruct()));

            for k = 1:numel(names)
                if isfield(S,names(k)), obj.(names(k)) = S.(names(k)); end
            end
        end
    end

    methods (Access=private)
        function setColor(obj,name,value)
        %SETCOLOR Restore JSON vectors to rows before normal assignment.
            obj.setValue(name,reshape(value,1,[]));
        end

        function setValue(obj,name,value)
        %SETVALUE Store one setting and publish the standard change payload.
            property = char(name + "_");
            old = obj.(property);
            obj.(property) = value;
            value = obj.(property);

            if isequaln(old,value), return; end

            event = oops.config.ChangeEvent("PolarHistogram",name,old,value);
            notify(obj,'PolarHistogramChanged',event);
            notify(obj,'Changed',event);
        end
    end
end
