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

classdef ScatterData
%SCATTERDATA Normalized, validated data for grouped scatter rendering.
% Each cell represents one logical scatter group. Numeric arrays are stored
% as row vectors so low-level plot primitives receive a consistent shape.

    properties (SetAccess=private)
        XData (:,1) cell = {NaN}
        YData (:,1) cell = {NaN}
        SeriesNames (:,1) string = "No data"
        CData (:,1) cell = {NaN}
    end

    methods

        function obj = ScatterData(opts)
        %SCATTERDATA Normalize data and validate alignment between groups.

            arguments
                opts.XData cell = {NaN}
                opts.YData cell = {NaN}
                opts.SeriesNames string = "No data"
                opts.CData cell = {NaN}
            end

            obj.XData = normalizeNumericCells(opts.XData,"XData");
            obj.YData = normalizeNumericCells(opts.YData,"YData");
            obj.SeriesNames = string(opts.SeriesNames(:));
            obj.CData = normalizeColorCells(opts.CData);
            obj.validateAlignment();
        end

    end

    methods (Access=private)

        function validateAlignment(obj)
        %VALIDATEALIGNMENT Require one aligned payload entry per scatter group.

            count = numel(obj.XData);

            if numel(obj.YData) ~= count || ...
                    numel(obj.SeriesNames) ~= count || numel(obj.CData) ~= count
                error('matlabx:ui:axes:plot:ScatterDataGroupCountMismatch', ...
                    'XData, YData, SeriesNames, and CData must have equal group counts.');
            end

            for k = 1:count
                pointCount = numel(obj.XData{k});

                if numel(obj.YData{k}) ~= pointCount
                    error('matlabx:ui:axes:plot:ScatterDataPointCountMismatch', ...
                        'XData and YData must have equal lengths in group %d.',k);
                end

                validateColorCount(obj.CData{k},pointCount,k);
            end
        end

    end

end

function values = normalizeNumericCells(values,name)
%NORMALIZENUMERICCELLS Validate numeric cells and normalize vectors to rows.

    values = values(:);

    for k = 1:numel(values)

        if ~isnumeric(values{k}) || (~isvector(values{k}) && ~isempty(values{k}))
            error('matlabx:ui:axes:plot:InvalidScatterData', ...
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
            error('matlabx:ui:axes:plot:InvalidScatterColorData', ...
                'CData group %d must contain a numeric vector or matrix.',k);
        end

        if isvector(values{k})
            values{k} = reshape(values{k},1,[]);
        end
    end
end

function validateColorCount(colors,pointCount,index)
%VALIDATECOLORCOUNT Accept scalar, RGB, or point-aligned color data.

    valid = isscalar(colors) || isequal(size(colors),[1 3]) || ...
        ((isvector(colors) || isempty(colors)) && numel(colors) == pointCount) || isequal(size(colors),[pointCount 3]);

    if ~valid
        error('matlabx:ui:axes:plot:ScatterColorCountMismatch', ...
            'CData in group %d must be scalar, RGB, or aligned with its points.',index);
    end
end
