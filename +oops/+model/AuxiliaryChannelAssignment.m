% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef AuxiliaryChannelAssignment < handle
%AUXILIARYCHANNELASSIGNMENT Bind one source component to a semantic channel.

    properties (SetAccess=private)
        ChannelID (1,1) string = ""
        Input (1,1) matlabx.image.Image5D
        ComponentIndex (1,1) double {mustBeInteger,mustBePositive} = 1
        DisplayRange double = []
        DisplayStatistics (1,1) struct = struct()
    end

    methods

        function obj = AuxiliaryChannelAssignment( ...
                channelID,input,componentIndex,displayRange,displayStatistics)
        %AUXILIARYCHANNELASSIGNMENT Validate a single-plane scalar component.

            arguments
                channelID (1,1) string
                input (1,1) matlabx.image.Image5D
                componentIndex (1,1) double {mustBeInteger,mustBePositive}
                displayRange double = []
                displayStatistics (1,1) struct = struct()
            end

            if componentIndex > input.NumComponents
                error('oops:model:InvalidAuxiliaryComponent', ...
                    'Component %d exceeds the source component count.',componentIndex);
            end

            component = input.getComponent(componentIndex);

            if ~component.IsScalar || component.SizeZ ~= 1 || component.SizeT ~= 1
                error('oops:model:InvalidAuxiliaryComponent', ...
                    'Auxiliary channels must be scalar components with one Z and T plane.');
            end

            if ~isempty(displayRange)
                validateattributes(displayRange,{'numeric'}, ...
                    {'real','finite','size',[1 2],'increasing'});
            end

            obj.ChannelID = channelID;
            obj.Input = input;
            obj.ComponentIndex = componentIndex;
            obj.DisplayRange = double(displayRange);
            obj.DisplayStatistics = displayStatistics;
        end

        function delete(obj)
        %DELETE Release resident source pixels when an assignment is discarded.

            for k = 1:numel(obj)

                if ~isempty(obj(k).Input)
                    obj(k).Input.unload();
                end

            end
        end

        function values = getPlane(obj)
        %GETPLANE Read the assigned source component without retaining a full stack.

            started = tic;
            oops.Log.DEBUG(sprintf( ...
                'Reading auxiliary plane: channel=%s, component=%d, resident=%s.', ...
                obj.ChannelID,obj.ComponentIndex,string(obj.Input.IsLoaded)));
            values = obj.Input.getPlane(obj.ComponentIndex,1,1);
            oops.Log.DEBUG(sprintf( ...
                'Read auxiliary plane: channel=%s, class=%s, size=%dx%d, elapsed=%.3f s.', ...
                obj.ChannelID,class(values),size(values,1),size(values,2),toc(started)));
        end

        function setDisplayRange(obj,value)
        %SETDISPLAYRANGE Store image-local limits for this semantic channel.

            if isempty(value)
                obj.DisplayRange = [];
                return;
            end

            validateattributes(value,{'numeric'}, ...
                {'real','finite','size',[1 2],'increasing'});
            obj.DisplayRange = double(value);
        end

        function statistics = getDisplayStatistics(obj,values)
        %GETDISPLAYSTATISTICS Cache extrema and robust percentiles after first read.

            required = ["Minimum","Maximum","Percentile0_5","Percentile1", ...
                "Percentile99_5","Percentile99_9","Percentile99_95"];

            if all(isfield(obj.DisplayStatistics,required))
                statistics = obj.DisplayStatistics;
                return;
            end

            if nargin < 2 || isempty(values)
                values = obj.getPlane();
            end

            finiteValues = double(values(:));
            finiteValues = finiteValues(isfinite(finiteValues));

            if isempty(finiteValues)
                limits = [0 1];
                percentile1 = limits(1);
                percentile0_5 = limits(1);
                percentile99_5 = limits(2);
                percentile99_9 = limits(2);
                percentile99_95 = limits(2);
            else
                limits = [min(finiteValues) max(finiteValues)];
                percentiles = prctile(finiteValues,[0.5 1 99.5 99.9 99.95]);
                percentile0_5 = percentiles(1);
                percentile1 = percentiles(2);
                percentile99_5 = percentiles(3);
                percentile99_9 = percentiles(4);
                percentile99_95 = percentiles(5);

                if percentile99_5 <= percentile1
                    percentile1 = limits(1);
                    percentile99_5 = limits(2);
                end
                if percentile99_95 <= percentile0_5
                    percentile0_5 = limits(1);
                    percentile99_9 = limits(2);
                    percentile99_95 = limits(2);
                end
            end

            if limits(2) <= limits(1)
                limits(2) = limits(1)+max(1,eps(limits(1)));
            end

            obj.DisplayStatistics = struct( ...
                'Minimum',limits(1), ...
                'Maximum',limits(2), ...
                'Percentile0_5',percentile0_5, ...
                'Percentile1',percentile1, ...
                'Percentile99_5',percentile99_5, ...
                'Percentile99_9',percentile99_9, ...
                'Percentile99_95',percentile99_95);
            statistics = obj.DisplayStatistics;
        end

        function S = toStruct(obj,projectFolder)
        %TOSTRUCT Capture the semantic mapping and portable external source reference.

            S = struct( ...
                'ChannelID',obj.ChannelID, ...
                'Source',oops.io.project.sourceReference(obj.Input,projectFolder), ...
                'ComponentIndex',obj.ComponentIndex, ...
                'DisplayRange',obj.DisplayRange, ...
                'DisplayStatistics',obj.DisplayStatistics);
        end

    end

end
