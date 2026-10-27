% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectMeasurements
%OBJECTMEASUREMENTS Catalog object measurement names and display labels.
% Internal names remain stable identifiers in settings and model code. This
% catalog provides the corresponding human-readable text for user interfaces.

    methods (Static)

        function names = names()
        %NAMES Return the canonical names of stored object measurements.

            names = ["Area" ...
                "Circularity" ...
                "ConvexArea" ...
                "Eccentricity" ...
                "EquivDiameter" ...
                "Extent" ...
                "FilledArea" ...
                "MajorAxisLength" ...
                "MinorAxisLength" ...
                "Perimeter" ...
                "Solidity" ...
                "MaxFeretDiameter" ...
                "MinFeretDiameter" ...
                "CentroidX" ...
                "CentroidY" ...
                "MeanSignalIntensity" ...
                "MeanBackgroundIntensity" ...
                "SignalToBackgroundRatio" ...
                "OrderMean" ...
                "OrderStandardDeviation" ...
                "OrderMinimum" ...
                "OrderMaximum" ...
                "AzimuthMean" ...
                "AzimuthCircularStandardDeviation" ...
                "AzimuthCircularAngularDeviation" ...
                "MidlineRelativeAzimuthMean" ...
                "NormalRelativeAzimuthMean" ...
                "MidlineLength" ...
                "Tortuosity" ...
                "MidlineOrientationMean"];
        end

        function overrides = labelOverrides()
        %LABELOVERRIDES Return explicit internal-name to display-label mappings.
        % Add entries here when a measurement needs terminology that cannot be
        % produced clearly by the general PascalCase conversion.

            internalNames = ["EquivDiameter" ...
                "MaxFeretDiameter" ...
                "MinFeretDiameter" ...
                "CentroidX" ...
                "CentroidY" ...
                "MeanSignalIntensity" ...
                "MeanBackgroundIntensity" ...
                "SignalToBackgroundRatio"];

            displayLabels = ["Equivalent diameter" ...
                "Maximum Feret diameter" ...
                "Minimum Feret diameter" ...
                "Centroid X" ...
                "Centroid Y" ...
                "Mean signal intensity" ...
                "Mean BG intensity" ...
                "S/B ratio"];

            overrides = dictionary(internalNames,displayLabels);
        end

        function names = plottableNames(project)
        %PLOTTABLENAMES Return fixed measurements plus project auxiliary channels.

            names = oops.model.ObjectMeasurements.names();

            if nargin < 1 || isempty(project)
                return;
            end

            % Semantic auxiliary roles define the available channel measurements.
            % Registry order keeps the corresponding plot menus predictable.
            channels = project.Channels.Channels;
            channels = channels([channels.IsAuxiliary]);

            for channel = reshape(channels,1,[])
                names(end+1) = oops.model.ObjectMeasurements.auxiliaryName(channel.ID); %#ok<AGROW>
            end
        end

        function name = auxiliaryName(channelID)
        %AUXILIARYNAME Build a stable plot-variable ID from a semantic channel ID.

            name = "AuxiliarySignalMean:" + string(channelID);
        end

        function [tf,channelID] = isAuxiliary(name)
        %ISAUXILIARY Identify and decode an auxiliary signal-mean variable ID.

            prefix = "AuxiliarySignalMean:";
            name = string(name);
            tf = startsWith(name,prefix);
            channelID = "";

            if tf
                channelID = extractAfter(name,strlength(prefix));
                tf = channelID ~= "";
            end
        end

        function label = label(name,project)
        %LABEL Convert one internal measurement name to a display label.

            arguments
                name (1,1) string
                project = oops.model.Project.empty(0,1)
            end

            if ~isempty(project)
                [auxiliary,channelID] = oops.model.ObjectMeasurements.isAuxiliary(name);

                if auxiliary
                    channel = project.Channels.findByID(channelID);

                    if isempty(channel)
                        label = "Missing channel signal mean";
                    else
                        label = channel.Name + " signal mean";
                    end
                    return;
                end
            end

            overrides = oops.model.ObjectMeasurements.labelOverrides();

            if isKey(overrides,name)
                label = overrides(name);
                return
            end

            label = oops.model.ObjectMeasurements.pascalCaseLabel(name);
        end

        function labels = labels(names,project)
        %LABELS Convert an array of internal measurement names to display labels.

            arguments
                names string
                project = oops.model.Project.empty(0,1)
            end

            % Preserve the input shape so labels remain aligned with ItemsData.
            labels = strings(size(names));

            for k = 1:numel(names)
                labels(k) = oops.model.ObjectMeasurements.label(names(k),project);
            end
        end

    end

    methods (Static, Access=private)

        function label = pascalCaseLabel(name)
        %PASCALCASELABEL Split a PascalCase identifier into sentence-case words.

            % Separate acronym-to-word and lowercase-to-uppercase boundaries.
            label = regexprep(char(name),'([A-Z])([A-Z][a-z])','$1 $2');
            label = regexprep(label,'([a-z0-9])([A-Z])','$1 $2');

            % Use sentence case for labels generated without an explicit override.
            label = string(lower(label));

            if strlength(label) > 0
                text = char(label);
                text(1) = upper(text(1));
                label = string(text);
            end
        end

    end

end
