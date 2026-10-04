% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

classdef Images < handle
    properties
        DefaultColormap (1,:) char = 'gray'
        Interpolation   (1,:) char = 'nearest'
        ShowPixelInfo   (1,1) logical = true
    end

    methods
        function S = toStruct(obj)
            S = struct( ...
                'DefaultColormap', obj.DefaultColormap, ...
                'Interpolation', obj.Interpolation, ...
                'ShowPixelInfo', obj.ShowPixelInfo);
        end

        function fromStruct(obj,S)
            if isfield(S,'DefaultColormap')
                obj.DefaultColormap = S.DefaultColormap;
            end
            if isfield(S,'Interpolation')
                obj.Interpolation = S.Interpolation;
            end
            if isfield(S,'ShowPixelInfo')
                obj.ShowPixelInfo = S.ShowPixelInfo;
            end
        end
    end
end