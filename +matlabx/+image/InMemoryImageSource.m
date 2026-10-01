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

classdef InMemoryImageSource < matlabx.image.ImageSource
    %INMEMORYIMAGESOURCE ImageSource implementation backed by MATLAB arrays.
    %
    %   This source normalizes one or more in-memory component arrays into
    %   ImageComponent objects. It mirrors the role of BioFormatsImageSource
    %   for file-backed images: the source owns source-specific setup, while
    %   Image5D remains a small public wrapper around any ImageSource.

    properties (Access = private)
        Components_ (1,:) matlabx.image.ImageComponent = matlabx.image.ImageComponent.empty(1,0)
        Source_ string = ""
    end

    methods
        function obj = InMemoryImageSource(data, opts)
            %INMEMORYIMAGESOURCE Construct an in-memory image source.
            %
            %   SRC = matlabx.image.InMemoryImageSource(DATA) accepts a
            %   single numeric/logical array or a cell array of component
            %   arrays. Component arrays use the Image5D dimension order
            %   [Y X C Z T], where C is 1 for scalar components and 3 for RGB.
            %
            %   SRC = matlabx.image.InMemoryImageSource(DATA, Names=NAMES,
            %   Kinds=KINDS, Source=SOURCE) applies optional component names,
            %   component kinds, and source description.
            arguments
                data
                opts.Names string = matlabx.string.empty()
                opts.Kinds string = matlabx.string.empty()
                opts.Source string = ""
            end

            if isa(data, 'matlabx.image.ImageComponent')
                obj.Components_ = reshape(data, 1, []);
                obj.Source_ = opts.Source;
                return
            end

            obj.Components_ = obj.createComponents_(data, opts.Names, opts.Kinds);
            obj.Source_ = opts.Source;
        end

        function comps = getComponents(obj)
            %GETCOMPONENTS Return the normalized in-memory components.
            comps = obj.Components_;
        end

        function tf = isLoaded(~)
            %ISLOADED Return true because array-backed data are already loaded.
            tf = true;
        end

        function tf = isFileBacked(obj)
            %ISFILEBACKED Return true only when a source descriptor was supplied.
            tf = strlength(obj.Source_) > 0;
        end

        function load(~)
            %LOAD No-op for in-memory data.
            % No-op for in-memory source.
        end

        function unload(~)
            %UNLOAD No-op for in-memory data.
            % No-op for in-memory source.
        end

        function I = getPlane(obj, idx, z, t)
            %GETPLANE Return one Z/T plane from one component.
            I = obj.Components_(idx).getPlane(z, t);
        end

        function md = getOriginalMetadata(~)
            %GETORIGINALMETADATA Return empty metadata for in-memory data.
            md = struct();
        end
        
        function md = getOMEMetadata(~)
            %GETOMEMETADATA Return empty OME metadata for in-memory data.
            md = struct();
        end

        function md = getCoreMetadata(~)
            %GETCOREMETADATA Return empty core metadata for in-memory data.
            md = struct();
        end
        
        function md = getGraphicsFileMetadata(~)
            %GETGRAPHICSFILEMETADATA Return empty graphics metadata.
            md = struct();
        end
    end

    methods (Static, Access = private)
        function comps = createComponents_(data, names, kinds)
            %CREATECOMPONENTS_ Convert component arrays into ImageComponent objects.
            if ~iscell(data)
                data = {data};
            end

            n = numel(data);
            if n == 0
                error('matlabx:image:InMemoryImageSource:EmptyInput', ...
                    'At least one component is required.');
            end

            % Validate component compatibility first so partially-created
            % sources are never exposed after a bad input.
            sizes = zeros(n, 5);
            inferredKinds = strings(1, n);
            refSize = [];

            for k = 1:n
                A = data{k};

                if ~(isnumeric(A) || islogical(A))
                    error('matlabx:image:InMemoryImageSource:InvalidComponentType', ...
                        'Component %d must be numeric or logical.', k);
                end

                stackSize = matlabx.image.InMemoryImageSource.inferComponentSize_(A);
                sizes(k, :) = stackSize;
                inferredKinds(k) = matlabx.image.InMemoryImageSource.inferComponentKind_(stackSize);

                if isempty(refSize)
                    refSize = stackSize;
                elseif ~isequal(stackSize([1, 2, 4, 5]), refSize([1, 2, 4, 5]))
                    error('matlabx:image:InMemoryImageSource:InconsistentComponentSize', ...
                        ['All components must have matching Y, X, Z, and T size. ' ...
                         'Component 1 is [%d %d %d %d %d], component %d is [%d %d %d %d %d].'], ...
                        refSize, k, stackSize);
                end
            end

            kinds = matlabx.image.InMemoryImageSource.normalizeKinds_(kinds, inferredKinds, n);
            names = matlabx.image.InMemoryImageSource.normalizeNames_(names, kinds, n);

            comps(1, n) = matlabx.image.ImageComponent();
            for k = 1:n
                A = data{k};
                comps(k) = matlabx.image.ImageComponent( ...
                    [], ...
                    Name=names(k), ...
                    Kind=kinds(k), ...
                    Class=string(class(A)), ...
                    Size=sizes(k, :), ...
                    NativeDisplayRange=getrangefromclass(A), ...
                    DataRange=[double(min(A(:))), double(max(A(:)))]);
                comps(k).Data = A;
            end
        end

        function names = normalizeNames_(names, kinds, n)
            %NORMALIZENAMES_ Apply BioFormats-like fallback component names.
            names = reshape(string(names), 1, []);

            for k = 1:n
                if numel(names) < k || strlength(names(k)) == 0
                    names(k) = matlabx.image.InMemoryImageSource.defaultComponentName_(kinds(k), k, n);
                end
            end
        end

        function kinds = normalizeKinds_(kinds, inferredKinds, n)
            %NORMALIZEKINDS_ Fill missing kinds with values inferred from size.
            kinds = reshape(string(kinds), 1, []);

            for k = 1:n
                if numel(kinds) < k || strlength(kinds(k)) == 0
                    kinds(k) = inferredKinds(k);
                end
            end
        end

        function name = defaultComponentName_(kind, idx, n)
            %DEFAULTCOMPONENTNAME_ Match BioFormats defaults where practical.
            if n == 1 && strcmpi(kind, "rgb")
                name = "RGB";
            else
                name = "Component " + idx;
            end
        end

        function kind = inferComponentKind_(sz)
            %INFERCOMPONENTKIND_ Infer scalar or RGB kind from component size.
            if sz(3) == 1
                kind = "scalar";
                return
            end

            if sz(3) == 3
                kind = "rgb";
                return
            end

            error('matlabx:image:InMemoryImageSource:InvalidComponentSize', ...
                'Component must have size [Y X 1 Z T] (scalar) or [Y X 3 Z T] (truecolor).');
        end

        function sz = inferComponentSize_(A)
            %INFERCOMPONENTSIZE_ Return Image5D-style size [Y X C Z T].
            sz = size(A, 1:5);
        end
    end

end
