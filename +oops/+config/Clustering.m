% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Clustering < handle
%CLUSTERING Object-feature clustering options; algorithms live in analysis.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        nClustersMode_ (1,1) string = "Auto"
        nClusters_ (1,1) double {mustBeFinite,mustBeInteger,mustBePositive} = 3
        Criterion_ (1,1) string = "CalinskiHarabasz"
        DistanceMetric_ (1,1) string = "sqeuclidean"
        NormalizationMethod_ (1,1) string = "zscore"
        DisplayEvaluation_ (1,1) logical = true
        % Names of stored scalar object measurements to use as features.
        VariableList_ (1,:) string = ["Area" "BGAverage" "Circularity" "ConvexArea" "Eccentricity" "EquivDiameter" "Extent" "SBRatio" "MajorAxisLength" "MaxFeretDiameter" "MidlineLength" "MinFeretDiameter" "MinorAxisLength" "Perimeter" "SignalAverage" "Solidity" "Tortuosity"]
    end

    properties (Dependent)
        nClustersMode
        nClusters
        Criterion
        DistanceMetric
        NormalizationMethod
        DisplayEvaluation
        VariableList
    end

    events
        Changed
        ClusteringChanged
    end

    methods

        function v = get.nClustersMode(obj)
        %GET.NCLUSTERSMODE Return the stored nClustersMode setting.

            v = obj.nClustersMode_;
        end

        function set.nClustersMode(obj,v)
        %SET.NCLUSTERSMODE Validate, store, and notify a Clustering setting change.

            obj.setValue("nClustersMode",v);
        end

        function v = get.nClusters(obj)
        %GET.NCLUSTERS Return the stored nClusters setting.

            v = obj.nClusters_;
        end

        function set.nClusters(obj,v)
        %SET.NCLUSTERS Validate, store, and notify a Clustering setting change.

            obj.setValue("nClusters",v);
        end

        function v = get.Criterion(obj)
        %GET.CRITERION Return the stored Criterion setting.

            v = obj.Criterion_;
        end

        function set.Criterion(obj,v)
        %SET.CRITERION Validate, store, and notify a Clustering setting change.

            obj.setValue("Criterion",v);
        end

        function v = get.DistanceMetric(obj)
        %GET.DISTANCEMETRIC Return the stored DistanceMetric setting.

            v = obj.DistanceMetric_;
        end

        function set.DistanceMetric(obj,v)
        %SET.DISTANCEMETRIC Validate, store, and notify a Clustering setting change.

            obj.setValue("DistanceMetric",v);
        end

        function v = get.NormalizationMethod(obj)
        %GET.NORMALIZATIONMETHOD Return the stored NormalizationMethod setting.

            v = obj.NormalizationMethod_;
        end

        function set.NormalizationMethod(obj,v)
        %SET.NORMALIZATIONMETHOD Validate, store, and notify a Clustering setting change.

            obj.setValue("NormalizationMethod",v);
        end

        function v = get.DisplayEvaluation(obj)
        %GET.DISPLAYEVALUATION Return the stored DisplayEvaluation setting.

            v = obj.DisplayEvaluation_;
        end

        function set.DisplayEvaluation(obj,v)
        %SET.DISPLAYEVALUATION Validate, store, and notify a Clustering setting change.

            obj.setValue("DisplayEvaluation",v);
        end

        function v = get.VariableList(obj)
        %GET.VARIABLELIST Return the stored VariableList setting.

            v = obj.VariableList_;
        end

        function set.VariableList(obj,v)
        %SET.VARIABLELIST Validate, store, and notify a Clustering setting change.

            v = reshape(v,1,[]); % JSON decodes vector fields as columns.
            obj.setValue("VariableList",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize values without listeners or graphics objects.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('nClustersMode',obj.nClustersMode, ...
                'nClusters',obj.nClusters, ...
                'Criterion',obj.Criterion, ...
                'DistanceMetric',obj.DistanceMetric, ...
                'NormalizationMethod',obj.NormalizationMethod, ...
                'DisplayEvaluation',obj.DisplayEvaluation, ...
                'VariableList',obj.VariableList);
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
                ev = oops.config.ChangeEvent("Clustering",name,old,value);
                notify(obj,'ClusteringChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end
end
