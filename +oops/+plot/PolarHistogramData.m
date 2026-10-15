% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef PolarHistogramData
%POLARHISTOGRAMDATA Normalized axial angles for polar-histogram rendering.

    properties (SetAccess=private)
        Angles (1,:) double = double.empty(1,0)
    end

    methods
        function obj = PolarHistogramData(opts)
        %POLARHISTOGRAMDATA Retain finite radians in the axial interval [0,pi).
            arguments
                opts.Angles double = double.empty(1,0)
            end

            angles = double(opts.Angles(:).');
            angles = angles(isfinite(angles));
            obj.Angles = mod(angles,pi);
        end
    end
end
