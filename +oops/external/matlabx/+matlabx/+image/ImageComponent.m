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

classdef ImageComponent < handle
    %IMAGECOMPONENT One logical image component.
    %
    % Dimension order convention: [Y X C Z T]

    properties
        Data = []
        Name string = ""
        Metadata struct = struct()
        LUT = []
        Color = []
    end

    % private backing store
    properties (Access=private)
        Class_ string = ""
        % Size_ (1,5) double = [0 0 1 1 1]   % [Y X C Z T]
        Size_ (1,5) double = [NaN NaN NaN NaN NaN]
        DataRange_ (1,2) double = [NaN NaN]
        NativeDisplayRange_ (1,2) double = [0 1]
        Kind_ string = ""
    end

    properties (Dependent, SetAccess = private)
        Class
        Size                (1,5) double % [Y X C Z T]
        NativeDisplayRange
        DataRange
        Kind        % scalar, rgb, indexed, logical, label, etc.

        IsRGB
        IsLoaded
        IsScalar
        
        SizeY
        SizeX
        SizeC
        SizeZ
        SizeT
    end

    methods
        function obj = ImageComponent(data, opts)
            arguments
                data = []
                opts.Name {mustBeTextScalar} = ""
                opts.Kind {mustBeTextScalar} = "scalar"
                opts.Metadata struct = struct()
                opts.LUT = []
                opts.Color = []
                opts.Class string = ""
                opts.Size (1,5) double = [NaN NaN NaN NaN NaN]
                opts.NativeDisplayRange (1,2) double = [0 1]
                opts.DataRange (1,2) double = [NaN NaN]
            end

            obj.Name = string(opts.Name);
            obj.Metadata = opts.Metadata;
            obj.LUT = opts.LUT;
            obj.Color = opts.Color;

            if ~isempty(data)
                obj.setData(data);
                return
            end

            % only set these from input arguments if data was empty
            obj.Class_ = string(opts.Class);
            obj.Size_ = opts.Size;
            obj.NativeDisplayRange_ = opts.NativeDisplayRange;
            obj.DataRange_ = opts.DataRange;
            obj.Kind_ = string(opts.Kind);

        end

        function tf = get.IsLoaded(obj)
            tf = ~isempty(obj.Data);
        end

        function c = get.Class(obj)
            if obj.IsLoaded
                c = string(class(obj.Data));
            else
                c = obj.Class_;
            end
        end

        function r = get.DataRange(obj)
            if obj.IsLoaded
                r = [double(min(obj.Data(:))), double(max(obj.Data(:)))];
            else
                r = obj.DataRange_;
            end
        end

        function r = get.NativeDisplayRange(obj)
            if obj.IsLoaded
                r = getrangefromclass(obj.Data);
            else
                r = obj.NativeDisplayRange_;
            end
        end

        function kind = get.Kind(obj)
            if strlength(obj.Kind_) == 0
                obj.Kind_ = obj.inferKind_();
            end
            kind = obj.Kind_;
        end

        function tf = get.IsRGB(obj)
            tf = strcmpi(obj.Kind,'rgb');
        end

        function tf = get.IsScalar(obj)
            tf = strcmpi(obj.Kind,'scalar');
        end

        function s = get.Size(obj)
            % if obj.IsLoaded
            %     % s = obj.inferSize_(obj.Data, obj.Kind);
            %     s = obj.inferSize_(obj.Data);
            % else
            %     s = obj.Size_;
            % end

            if any(isnan(obj.Size_))
                obj.Size_ = size(obj.Data,1:5);
            end
            s = obj.Size_;
        end

        function v = get.SizeY(obj)
            v = obj.Size(1);
        end

        function v = get.SizeX(obj)
            v = obj.Size(2);
        end

        function v = get.SizeC(obj)
            v = obj.Size(3);
        end

        function v = get.SizeZ(obj)
            v = obj.Size(4);
        end

        function v = get.SizeT(obj)
            v = obj.Size(5);
        end

        function I = getPlane(obj, z, t)
            arguments
                obj
                z (1,1) double {mustBeInteger, mustBePositive} = 1
                t (1,1) double {mustBeInteger, mustBePositive} = 1
            end

            if isempty(obj.Data)
                error('matlabx:image:ImageComponent:NotLoaded', ...
                    'Component data are not loaded.');
            end

            if obj.IsScalar
                I = obj.Data(:, :, 1, z, t);
            elseif obj.IsRGB
                I = obj.Data(:, :, 1:3, z, t);
            end

        end


        function setData(obj, data)
            obj.Data = data;
            obj.Class_ = string(class(data));
            obj.Size_ = size(data,1:5);
            obj.Kind_ = obj.inferKind_(data);
            obj.NativeDisplayRange_ = getrangefromclass(data);
            obj.DataRange_ = [double(min(data(:))), double(max(data(:)))];
        end

        function clearData(obj)
            obj.Data = [];
        end
    end

    methods (Access = private)
        % function tf = inferIsRGB_(~, data)
        %     tf = size(data,3) == 3;
        % end

        % function sz = inferSize_(~, data)
        %     % sz = size(data);
        %     % if numel(sz) < 5
        %     %     sz = [sz, ones(1, 5-numel(sz))];
        %     % end
        % 
        %     sz = size(data,1:5);
        % end

        function kind = inferKind_(~,data)
            sz = size(data);
            if numel(sz) < 3 || sz(3) == 1
                kind = "scalar";
            elseif sz(3) == 3
                kind = "rgb";
            else
                error('matlabx:image:Image5D:InvalidComponentSize', ...
                    'Component must have size [Y X 1 Z T] (scalar) or [Y X 3 Z T] (truecolor).');
            end
        end


    end
end