% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef PolarizationProvenance
%POLARIZATIONPROVENANCE Describe the inputs and algorithm behind FPM images.

    properties (SetAccess=private)
        Calculated (1,1) logical = false
        Parameters (1,1) oops.analysis.polarization.Parameters = ...
            oops.analysis.polarization.Parameters()
        Correction (1,1) oops.model.CorrectionProvenance = ...
            oops.model.CorrectionProvenance.raw()
    end

    properties (Dependent, SetAccess=private)
        Algorithm
    end

    methods

        function obj = PolarizationProvenance(correction,parameters)
        %POLARIZATIONPROVENANCE Construct an immutable analysis description.

            arguments
                correction (1,1) oops.model.CorrectionProvenance = ...
                    oops.model.CorrectionProvenance.raw()
                parameters (1,1) oops.analysis.polarization.Parameters = ...
                    oops.analysis.polarization.Parameters()
            end

            if nargin == 0
                return;
            end

            obj.Calculated = true;
            obj.Correction = correction;
            obj.Parameters = parameters;
        end

        function value = get.Algorithm(obj)
        %GET.ALGORITHM Expose the selected recipe ID for concise diagnostics.

            value = obj.Parameters.Algorithm;
        end

        function tf = isCurrent(obj,correction,parameters)
        %ISCURRENT Test whether results match the current corrected intensities.

            arguments
                obj (1,1) oops.model.PolarizationProvenance
                correction (1,1) oops.model.CorrectionProvenance
                parameters (1,1) oops.analysis.polarization.Parameters = ...
                    oops.analysis.polarization.Parameters()
            end

            tf = obj.Calculated && obj.Parameters.matches(parameters) && ...
                obj.Correction.matches(correction);
        end

        function S = toStruct(obj)
        %TOSTRUCT Return compact diagnostic metadata for this analysis.

            S = struct( ...
                'Calculated',obj.Calculated, ...
                'Parameters',obj.Parameters.toStruct(), ...
                'Correction',obj.Correction.toStruct());
        end

    end

    methods (Static)

        function obj = calculated(correction,parameters)
        %CALCULATED Describe outputs generated with a resolved recipe.

            arguments
                correction (1,1) oops.model.CorrectionProvenance
                parameters (1,1) oops.analysis.polarization.Parameters = ...
                    oops.analysis.polarization.Parameters()
            end

            obj = oops.model.PolarizationProvenance( ...
                correction,parameters);
        end

        function obj = fromStruct(S)
        %FROMSTRUCT Restore a saved polarization-analysis description.

            if ~logical(S.Calculated)
                obj = oops.model.PolarizationProvenance();
                return;
            end

            parameters = oops.analysis.polarization.Parameters.fromStruct( ...
                S.Parameters);
            correction = oops.model.CorrectionProvenance.fromStruct( ...
                S.Correction);
            obj = oops.model.PolarizationProvenance.calculated( ...
                correction,parameters);
        end

    end

end
