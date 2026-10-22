% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Algorithm
%ALGORITHM Typed runtime definition of one polarization implementation.

    properties (SetAccess=private)
        ID (1,1) string % Stable, versioned identifier stored in settings and provenance.
        Label (1,1) string % Human-readable algorithm name displayed in the interface.
        Description (1,1) string % Short explanation of the polarization calculation.
        RunFcn = [] % Function that calculates polarization outputs from an input stack.
        ParameterDefinitions (:,1) oops.analysis.ParameterDefinition = ...
            oops.analysis.ParameterDefinition.empty(0,1) % Metadata defining supported algorithm parameters.
        Outputs (1,:) struct = struct.empty(1,0) % Semantic definitions of the returned image fields.
    end

    methods
        function obj = Algorithm(opts)
        %ALGORITHM Validate and store polarization algorithm metadata.
            arguments
                opts.ID (1,1) string
                opts.Label (1,1) string
                opts.Description (1,1) string
                opts.RunFcn (1,1) function_handle
                opts.ParameterDefinitions (:,1) oops.analysis.ParameterDefinition = ...
                    oops.analysis.ParameterDefinition.empty(0,1)
                opts.Outputs (1,:) struct
            end
            obj.ID = opts.ID;
            obj.Label = opts.Label;
            obj.Description = opts.Description;
            obj.RunFcn = opts.RunFcn;
            obj.ParameterDefinitions = opts.ParameterDefinitions;
            obj.Outputs = opts.Outputs;
        end
    end
end
