% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef View < handle
%VIEW Independent, nonduplicated sources for the two main content panels.
% Events carry Domain, Name, OldValue, and NewValue like DesmoSTORM.

    properties (Access=private)
        LeftSource_ (1,1) string = "Input"
        RightSource_ (1,1) string = "Corrected"
    end

    properties (Dependent)
        LeftSource
        RightSource
    end

    events
        Changed
        ViewChanged
    end

    methods

        function v = get.LeftSource(obj)
        %GET.LEFTSOURCE Return the requested left viewer source.

            v = obj.LeftSource_;
        end

        function set.LeftSource(obj,v)
        %SET.LEFTSOURCE Validate and publish the requested left source.

            obj.setValue("LeftSource",v);
        end

        function v = get.RightSource(obj)
        %GET.RIGHTSOURCE Return the requested right viewer source.

            v = obj.RightSource_;
        end

        function set.RightSource(obj,v)
        %SET.RIGHTSOURCE Validate and publish the requested right source.

            obj.setValue("RightSource",v);
        end

        function S = toStruct(obj)
        %TOSTRUCT Serialize viewer choices for project-wide settings persistence.

            % Plain settings snapshot containing values only, without listeners.
            S = struct('LeftSource',obj.LeftSource,'RightSource',obj.RightSource);
        end

        function fromStruct(obj,S)
        %FROMSTRUCT Apply recognized settings through their validated setters.

            % Names of the serialized fields to apply through the public setters.
            names = fieldnames(obj.toStruct());

            % Apply serialized fields through their validated public setting setters.
            for k = 1:numel(names)

                if isfield(S,names{k}) && ismember(string(S.(names{k})),obj.sources())
                    obj.(names{k}) = S.(names{k});
                end

            end

        end

    end

    methods (Access=private)

        function setValue(obj,name,value)
        %SETVALUE Validate the backing property before emitting change events.

            try

                value = string(value);
                allowed = oops.config.View.sources();

                if name == "LeftSource"
                    allowed(allowed == "Objects") = [];
                end

                if ~isscalar(value) || ~ismember(value,allowed)
                    error('oops:config:InvalidViewSource', ...
                        '%s must be one of: %s.',name,strjoin(allowed,', '));
                end

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

                % A source has one persistent graphics owner. Moving it into this
                % panel clears the opposite panel instead of creating a duplicate.
                if value ~= "Empty"
                    otherName = "RightSource";

                    if name == "RightSource"
                        otherName = "LeftSource";
                    end

                    otherProperty = char(otherName + "_");

                    if obj.(otherProperty) == value
                        otherOld = obj.(otherProperty);
                        obj.(otherProperty) = "Empty";
                        otherEvent = oops.config.ChangeEvent( ...
                            "View",otherName,otherOld,"Empty");
                        notify(obj,'ViewChanged',otherEvent);
                        notify(obj,'Changed',otherEvent);
                    end
                end

                % Publish the requested panel after duplicate ownership is resolved.
                ev = oops.config.ChangeEvent("View",name,old,value);
                notify(obj,'ViewChanged',ev);
                notify(obj,'Changed',ev);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    methods (Static)

        function values = sources()
        %SOURCES List content identities supported by either main panel.

            definitions = oops.config.View.sourceDefinitions();
            values = [definitions.ID];
        end

        function definitions = sourceDefinitions()
        %SOURCEDEFINITIONS Map stable source identities to display labels.

            definitions = [ ...
                struct('ID',"Empty",'Label',"Empty"), ...
                struct('ID',"Input",'Label',"Input"), ...
                struct('ID',"Calibration",'Label',"Calibration"), ...
                struct('ID',"Corrected",'Label',"Corrected"), ...
                struct('ID',"AverageIntensity",'Label',"Average intensity"), ...
                struct('ID',"AuxiliaryChannels",'Label',"Auxiliary channels"), ...
                struct('ID',"Mask",'Label',"Mask"), ...
                struct('ID',"Order",'Label',"Order"), ...
                struct('ID',"Azimuth",'Label',"Azimuth"), ...
                struct('ID',"IntensityWeightedOrder",'Label',"Intensity-weighted order"), ...
                struct('ID',"IntensityWeightedAzimuth",'Label',"Intensity-weighted azimuth"), ...
                struct('ID',"AzimuthOrderIntensityHSV",'Label',"Azimuth–order–intensity HSV"), ...
                struct('ID',"Scatterplot",'Label',"Scatterplot"), ...
                struct('ID',"Swarmplot",'Label',"Swarmplot"), ...
                struct('ID',"PolarHistogram",'Label',"Polar histogram"), ...
                struct('ID',"Objects",'Label',"Objects")];
        end

        function labels = sourceLabels(ids)
        %SOURCELABELS Resolve stable source identities for user-facing display.

            arguments
                ids string
            end

            definitions = oops.config.View.sourceDefinitions();
            knownIDs = [definitions.ID];
            labels = strings(size(ids));

            for k = 1:numel(ids)
                index = find(knownIDs == ids(k),1);

                if isempty(index)
                    error('oops:config:UnknownViewSource', ...
                        'Unknown view source identity: %s',ids(k));
                end

                labels(k) = definitions(index).Label;
            end
        end

    end
end
