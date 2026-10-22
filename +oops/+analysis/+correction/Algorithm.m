% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Algorithm
%ALGORITHM Typed runtime definition of one intensity-correction implementation.

    properties (SetAccess=private)
        ID (1,1) string % Stable, versioned identifier stored in settings and provenance.
        Label (1,1) string % Human-readable algorithm name displayed in the interface.
        Description (1,1) string % Short explanation of the correction calculation.
        BuildFcn = [] % Optional function that builds a reusable calibration model.
        RunFcn = [] % Function that applies the correction model to an input stack.
        ParameterDefinitions (:,1) oops.analysis.ParameterDefinition = ...
            oops.analysis.ParameterDefinition.empty(0,1) % Metadata defining supported algorithm parameters.
    end

    methods
        function obj = Algorithm(opts)
        %ALGORITHM Validate and store correction algorithm metadata.
            arguments
                opts.ID (1,1) string
                opts.Label (1,1) string
                opts.Description (1,1) string
                opts.BuildFcn = []
                opts.RunFcn (1,1) function_handle
                opts.ParameterDefinitions (:,1) oops.analysis.ParameterDefinition = ...
                    oops.analysis.ParameterDefinition.empty(0,1)
            end
            obj.ID = opts.ID;
            obj.Label = opts.Label;
            obj.Description = opts.Description;
            obj.BuildFcn = opts.BuildFcn;
            obj.RunFcn = opts.RunFcn;
            obj.ParameterDefinitions = opts.ParameterDefinitions;
        end
    end
end
