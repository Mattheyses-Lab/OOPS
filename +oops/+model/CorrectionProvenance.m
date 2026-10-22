% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef CorrectionProvenance
%CORRECTIONPROVENANCE Record the correction recipe and calibration sources.

    properties (SetAccess=private)
        Parameters (1,1) oops.analysis.correction.Parameters = ...
            oops.analysis.correction.Parameters("Identity/1")
        CalibrationIDs (:,1) string = strings(0,1)
    end

    properties (Dependent, SetAccess=private)
        Algorithm
    end

    methods
        function obj = CorrectionProvenance(parameters,calibrationIDs)
        %CORRECTIONPROVENANCE Construct an immutable correction description.
            arguments
                parameters (1,1) oops.analysis.correction.Parameters = ...
                    oops.analysis.correction.Parameters("Identity/1")
                calibrationIDs (:,1) string = strings(0,1)
            end
            obj.Parameters = parameters;
            obj.CalibrationIDs = calibrationIDs(:);
        end

        function value = get.Algorithm(obj)
        %GET.ALGORITHM Expose the correction recipe ID.
            value = obj.Parameters.Algorithm;
        end

        function tf = matchesAssignments(obj,calibrationIDs)
        %MATCHESASSIGNMENTS Test the default recipe against assigned sources.
            calibrationIDs = string(calibrationIDs(:));
            if isempty(calibrationIDs)
                expected = oops.analysis.correction.Parameters("Identity/1");
            else
                expected = oops.analysis.correction.Parameters();
            end
            tf = obj.Parameters.matches(expected) && ...
                isequal(obj.CalibrationIDs,calibrationIDs);
        end

        function tf = matches(obj,other)
        %MATCHES Test whether two correction recipes and sources are identical.
            tf = obj.Parameters.matches(other.Parameters) && ...
                isequal(obj.CalibrationIDs,other.CalibrationIDs);
        end

        function S = toStruct(obj)
        %TOSTRUCT Return the durable correction description.
            S = struct('Parameters',obj.Parameters.toStruct(), ...
                'CalibrationIDs',obj.CalibrationIDs);
        end
    end

    methods (Static)
        function obj = raw()
        %RAW Describe uncorrected detector intensities.
            obj = oops.model.CorrectionProvenance( ...
                oops.analysis.correction.Parameters("Identity/1"),strings(0,1));
        end

        function obj = flatField(calibrationIDs)
        %FLATFIELD Describe the default correction and calibration inputs.
            calibrationIDs = string(calibrationIDs(:));
            if isempty(calibrationIDs)
                obj = oops.model.CorrectionProvenance.raw();
            else
                obj = oops.model.CorrectionProvenance( ...
                    oops.analysis.correction.Parameters(),calibrationIDs);
            end
        end

        function obj = fromStruct(S)
        %FROMSTRUCT Restore correction metadata from the current schema.
            parameters = oops.analysis.correction.Parameters.fromStruct(S.Parameters);
            obj = oops.model.CorrectionProvenance( ...
                parameters,string(S.CalibrationIDs));
        end
    end
end
