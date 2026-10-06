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

classdef ViolinData
%VIOLINDATA Normalized, validated data for grouped violin/swarm rendering.
% Values and their color data remain aligned within each logical group.

    properties (SetAccess=private)
        Values (:,1) cell = {NaN}
        SeriesNames (:,1) string = "No data"
        CData (:,1) cell = {NaN}
    end

    methods

        function obj = ViolinData(opts)
        %VIOLINDATA Normalize values and validate group/color alignment.

            arguments
                opts.Values cell = {NaN}
                opts.SeriesNames string = "No data"
                opts.CData cell = {NaN}
            end

            obj.Values = normalizeNumericCells(opts.Values,"Values");
            obj.SeriesNames = string(opts.SeriesNames(:));
            obj.CData = normalizeColorCells(opts.CData);
            obj.validateAlignment();
        end

    end

    methods (Access=private)

        function validateAlignment(obj)
        %VALIDATEALIGNMENT Require one name and color payload per violin group.

            count = numel(obj.Values);

            if numel(obj.SeriesNames) ~= count || numel(obj.CData) ~= count
                error('matlabx:ui:axes:plot:ViolinDataGroupCountMismatch', ...
                    'Values, SeriesNames, and CData must have equal group counts.');
            end

            for k = 1:count
                validateColorCount(obj.CData{k},numel(obj.Values{k}),k);
            end
        end

    end

end

function values = normalizeNumericCells(values,name)
%NORMALIZENUMERICCELLS Validate numeric cells and normalize vectors to rows.

    values = values(:);

    for k = 1:numel(values)

        if ~isnumeric(values{k}) || (~isvector(values{k}) && ~isempty(values{k}))
            error('matlabx:ui:axes:plot:InvalidViolinData', ...
                '%s group %d must contain a numeric vector.',name,k);
        end

        values{k} = reshape(values{k},1,[]);
    end
end

function values = normalizeColorCells(values)
%NORMALIZECOLORCELLS Validate numeric color payloads and preserve RGB matrices.

    values = values(:);

    for k = 1:numel(values)

        if ~isnumeric(values{k}) || ndims(values{k}) > 2
            error('matlabx:ui:axes:plot:InvalidViolinColorData', ...
                'CData group %d must contain a numeric vector or matrix.',k);
        end

        if isvector(values{k})
            values{k} = reshape(values{k},1,[]);
        end
    end
end

function validateColorCount(colors,valueCount,index)
%VALIDATECOLORCOUNT Accept scalar, RGB, or value-aligned color data.

    valid = isscalar(colors) || isequal(size(colors),[1 3]) || ...
        ((isvector(colors) || isempty(colors)) && numel(colors) == valueCount) || isequal(size(colors),[valueCount 3]);

    if ~valid
        error('matlabx:ui:axes:plot:ViolinColorCountMismatch', ...
            'CData in group %d must be scalar, RGB, or aligned with its values.',index);
    end
end
