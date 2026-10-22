% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef MaskProvenance
%MASKPROVENANCE Record how membership was defined and its upstream inputs.
% Diagnostics remains a small scalar structure for now and may become a
% dedicated class as segmentation algorithms expose richer durable outcomes.

    properties (SetAccess=private)
        Method (1,1) string = "Unknown" % Mechanism used to define object membership.
        Parameters (:,1) oops.analysis.segment.Parameters = ...
            oops.analysis.segment.Parameters.empty(0,1) % Segmentation inputs captured with an algorithmic mask.
        Correction (1,1) oops.model.CorrectionProvenance = ...
            oops.model.CorrectionProvenance.raw() % Upstream intensity correction used for segmentation.
        Diagnostics (1,1) struct = struct() % Small durable outcomes from mask generation.
        Source (1,1) struct = struct() % External source metadata for imported membership.
    end

    properties (Dependent, SetAccess=private)
        Algorithm % Segmentation algorithm ID, or empty for non-algorithmic masks.
    end

    methods
        function obj = MaskProvenance( ...
                method,parameters,correction,diagnostics,source)
        %MASKPROVENANCE Construct immutable mask-definition metadata.
            arguments
                method (1,1) string = "Unknown"
                parameters (:,1) oops.analysis.segment.Parameters = ...
                    oops.analysis.segment.Parameters.empty(0,1)
                correction (1,1) oops.model.CorrectionProvenance = ...
                    oops.model.CorrectionProvenance.raw()
                diagnostics (1,1) struct = struct()
                source (1,1) struct = struct()
            end
            if ~ismember(method,["Unknown","Segmentation","Imported","Manual"])
                error('oops:model:InvalidMaskMethod', ...
                    'Unknown mask provenance method: %s',method);
            end
            if numel(parameters) > 1
                error('oops:model:InvalidParameters', ...
                    'Mask provenance accepts at most one segmentation parameter set.');
            end
            obj.Method = method;
            obj.Parameters = parameters;
            obj.Correction = correction;
            obj.Diagnostics = diagnostics;
            obj.Source = source;
        end

        function value = get.Algorithm(obj)
        %GET.ALGORITHM Return the algorithm that generated this mask, if any.

            if obj.Method == "Segmentation" && ~isempty(obj.Parameters)
                value = obj.Parameters.Algorithm;
            else
                value = "";
            end
        end

        function tf = isCurrent(obj,correction)
        %ISCURRENT Compare the correction dependency declared by this mask.
            if obj.Method == "Segmentation"
                tf = obj.Correction.matches(correction);
            elseif ismember(obj.Method,["Imported","Manual"])
                tf = true;
            else
                tf = false;
            end
        end

        function S = toStruct(obj)
        %TOSTRUCT Return the durable mask-definition description.
            parameters = struct.empty(0,1);
            if ~isempty(obj.Parameters)
                parameters = obj.Parameters.toStruct();
            end
            S = struct('Method',obj.Method, ...
                'Parameters',parameters, ...
                'Correction',obj.Correction.toStruct(), ...
                'Diagnostics',obj.Diagnostics, ...
                'Source',obj.Source);
        end
    end

    methods (Static)
        function obj = unknown()
        %UNKNOWN Describe a mask whose origin is not known.
            obj = oops.model.MaskProvenance();
        end

        function obj = segmented(correction,parameters,diagnostics)
        %SEGMENTED Describe an algorithmic mask and its corrected input.
            arguments
                correction (1,1) oops.model.CorrectionProvenance
                parameters (1,1) oops.analysis.segment.Parameters = ...
                    oops.analysis.segment.Parameters()
                diagnostics (1,1) struct = struct()
            end
            obj = oops.model.MaskProvenance( ...
                "Segmentation",parameters,correction,diagnostics,struct());
        end

        function obj = imported(source)
        %IMPORTED Describe externally supplied membership.
            arguments
                source (1,1) struct = struct()
            end
            obj = oops.model.MaskProvenance( ...
                "Imported",oops.analysis.segment.Parameters.empty(0,1), ...
                oops.model.CorrectionProvenance.raw(),struct(),source);
        end

        function obj = manual()
        %MANUAL Describe user-defined membership.
            obj = oops.model.MaskProvenance( ...
                "Manual",oops.analysis.segment.Parameters.empty(0,1), ...
                oops.model.CorrectionProvenance.raw(),struct(),struct());
        end

        function obj = fromStruct(S)
        %FROMSTRUCT Restore mask provenance from the current schema.
            if ~isempty(S.Parameters)
                parameters = oops.analysis.segment.Parameters.fromStruct(S.Parameters);
            else
                parameters = oops.analysis.segment.Parameters.empty(0,1);
            end
            correction = oops.model.CorrectionProvenance.fromStruct(S.Correction);
            obj = oops.model.MaskProvenance( ...
                string(S.Method),parameters,correction,S.Diagnostics,S.Source);
        end
    end
end
