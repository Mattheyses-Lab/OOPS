% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef CorrectionProvenance
%CORRECTIONPROVENANCE Describe the intensity correction represented by image results.

    properties (SetAccess=private)
        Method (1,1) string = "Raw"
        CalibrationIDs (:,1) string = strings(0,1)
        Algorithm (1,1) string = "Identity"
    end

    methods

        function obj = CorrectionProvenance(method,calibrationIDs,algorithm)
        %CORRECTIONPROVENANCE Construct an immutable correction description.

            if nargin == 0
                return;
            end

            method = string(method);

            if ~ismember(method,["Raw","FlatField"])
                error('oops:model:InvalidCorrectionMethod', ...
                    'Unknown correction provenance method: %s',method);
            end

            obj.Method = method;
            obj.CalibrationIDs = string(calibrationIDs(:));
            obj.Algorithm = string(algorithm);
        end

        function tf = matchesAssignments(obj,calibrationIDs)
        %MATCHESASSIGNMENTS Test whether this provenance represents assigned files.

            calibrationIDs = string(calibrationIDs(:));

            if isempty(calibrationIDs)
                tf = obj.Method == "Raw";
            else
                tf = obj.Method == "FlatField" && ...
                    isequal(obj.CalibrationIDs,calibrationIDs);
            end
        end

        function S = toStruct(obj)
        %TOSTRUCT Return the small durable correction description.

            S = struct( ...
                'Method',obj.Method, ...
                'CalibrationIDs',obj.CalibrationIDs, ...
                'Algorithm',obj.Algorithm);
        end

    end

    methods (Static)

        function obj = raw()
        %RAW Describe uncorrected detector intensities.

            obj = oops.model.CorrectionProvenance( ...
                "Raw",strings(0,1),"Identity");
        end

        function obj = flatField(calibrationIDs)
        %FLATFIELD Describe intensities corrected by assigned calibration inputs.

            calibrationIDs = string(calibrationIDs(:));

            if isempty(calibrationIDs)
                obj = oops.model.CorrectionProvenance.raw();
            else
                obj = oops.model.CorrectionProvenance( ...
                    "FlatField",calibrationIDs,"FlatFieldCorrection");
            end
        end

        function obj = fromStruct(S)
        %FROMSTRUCT Restore correction provenance from a project snapshot.

            obj = oops.model.CorrectionProvenance( ...
                string(S.Method),string(S.CalibrationIDs),string(S.Algorithm));
        end

    end
end
