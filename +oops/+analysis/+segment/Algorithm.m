% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Algorithm
%ALGORITHM Typed runtime definition of one segmentation implementation.

    properties (SetAccess=private)
        ID (1,1) string % Stable, versioned identifier stored in settings and provenance.
        Label (1,1) string % Human-readable algorithm name displayed in the interface.
        Description (1,1) string % Short explanation of the segmentation algorithm.
        RunFcn = [] % Function that generates candidate membership and enhancement data.
        PreviewFcn = [] % Optional function that reapplies adjustable parameters to cached data.
        ParameterDefinitions (:,1) oops.analysis.ParameterDefinition = ...
            oops.analysis.ParameterDefinition.empty(0,1) % Metadata defining supported algorithm parameters.
    end

    methods
        function obj = Algorithm(opts)
        %ALGORITHM Validate and store segmentation algorithm metadata.
            arguments
                opts.ID (1,1) string
                opts.Label (1,1) string
                opts.Description (1,1) string
                opts.RunFcn (1,1) function_handle
                opts.PreviewFcn = []
                opts.ParameterDefinitions (:,1) oops.analysis.ParameterDefinition = ...
                    oops.analysis.ParameterDefinition.empty(0,1)
            end
            obj.ID = opts.ID;
            obj.Label = opts.Label;
            obj.Description = opts.Description;
            obj.RunFcn = opts.RunFcn;
            obj.PreviewFcn = opts.PreviewFcn;
            obj.ParameterDefinitions = opts.ParameterDefinitions;
        end
    end
end
