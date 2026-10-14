% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef MaskProvenance
%MASKPROVENANCE Describe how object membership was defined and its dependencies.

    properties (SetAccess=private)
        Method (1,1) string = "Unknown"
        InputDomain (1,1) string = "Unknown"
        CalibrationIDs (:,1) string = strings(0,1)
        Source (1,1) struct = struct()
    end

    methods

        function obj = MaskProvenance(method,inputDomain,calibrationIDs,source)
        %MASKPROVENANCE Construct an immutable mask-definition description.

            if nargin == 0
                return;
            end

            method = string(method);
            inputDomain = string(inputDomain);

            if ~ismember(method,["Unknown","Segmentation","Imported","Manual"])
                error('oops:model:InvalidMaskMethod', ...
                    'Unknown mask provenance method: %s',method);
            end

            if ~ismember(inputDomain, ...
                    ["Unknown","CorrectedIntensity","RawIntensity","ExternalMask"])
                error('oops:model:InvalidMaskInputDomain', ...
                    'Unknown mask input domain: %s',inputDomain);
            end

            obj.Method = method;
            obj.InputDomain = inputDomain;
            obj.CalibrationIDs = string(calibrationIDs(:));
            obj.Source = source;
        end

        function tf = isCurrent(obj,correction)
        %ISCURRENT Compare only the correction dependency declared by this mask.

            arguments
                obj
                correction (1,1) oops.model.CorrectionProvenance
            end

            switch obj.InputDomain
                case "RawIntensity"
                    tf = correction.Method == "Raw";
                case "CorrectedIntensity"
                    tf = correction.Method == "FlatField" && ...
                        isequal(obj.CalibrationIDs,correction.CalibrationIDs);
                case "ExternalMask"
                    tf = true;
                otherwise
                    tf = false;
            end
        end

        function S = toStruct(obj)
        %TOSTRUCT Return the durable mask-definition description.

            S = struct( ...
                'Method',obj.Method, ...
                'InputDomain',obj.InputDomain, ...
                'CalibrationIDs',obj.CalibrationIDs, ...
                'Source',obj.Source);
        end

    end

    methods (Static)

        function obj = unknown()
        %UNKNOWN Describe a mask whose origin predates provenance tracking.

            obj = oops.model.MaskProvenance();
        end

        function obj = segmented(correction)
        %SEGMENTED Describe segmentation from the current raw or corrected intensity.

            arguments
                correction (1,1) oops.model.CorrectionProvenance
            end

            if correction.Method == "FlatField"
                domain = "CorrectedIntensity";
                ids = correction.CalibrationIDs;
            else
                domain = "RawIntensity";
                ids = strings(0,1);
            end

            obj = oops.model.MaskProvenance( ...
                "Segmentation",domain,ids,struct());
        end

        function obj = imported(source)
        %IMPORTED Describe externally supplied membership independent of correction.

            arguments
                source (1,1) struct = struct()
            end

            obj = oops.model.MaskProvenance( ...
                "Imported","ExternalMask",strings(0,1),source);
        end

        function obj = manual()
        %MANUAL Describe user-defined membership independent of correction.

            obj = oops.model.MaskProvenance( ...
                "Manual","ExternalMask",strings(0,1),struct());
        end

        function obj = fromStruct(S)
        %FROMSTRUCT Restore mask provenance from a project snapshot.

            obj = oops.model.MaskProvenance( ...
                string(S.Method),string(S.InputDomain), ...
                string(S.CalibrationIDs),S.Source);
        end

    end
end
