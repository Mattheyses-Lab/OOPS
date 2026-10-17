classdef ScatterData
%SCATTERDATA Normalized, validated data for grouped scatter rendering.
% Each cell represents one logical scatter group. Numeric arrays are stored
% as row vectors so low-level plot primitives receive a consistent shape.
%
%   data = matlabx.ui.axes.plot.ScatterData( ...
%       XData={[1 2 3],[1 2]}, ...
%       YData={[3 1 4],[2 5]}, ...
%       SeriesNames=["A","B"], ...
%       CData={[0.2 0.5 0.8],[0.8 0.3 0.2]});
%
% CData entries may be one RGB triplet, one scalar per point, or one RGB
% triplet per point. DataTipCells optionally supplies one {labels,values}
% template per group; an empty entry uses the renderer-generated default.
% A third formats cell is optional. Empty row formats use DataTipFormat,
% while nonempty entries override it for that row.
%
%   data = matlabx.ui.axes.plot.ScatterData( ...
%       XData={x},YData={y},SeriesNames="Samples",CData={[0 0.45 0.74]}, ...
%       DataTipCells={{{"Sample","Response"},{sampleIDs,y}, ...
%       {"","%.2f"}}});
%
% See also matlabx.ui.axes.plot.ScatterRenderer,
% matlabx.ui.axes.plot.ScatterStyle

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

    % Normalized group-aligned payload consumed by ScatterRenderer.
    properties (SetAccess=private)
        % X coordinates, stored as one row vector per group.
        XData (:,1) cell = {NaN}
        % Y coordinates aligned with XData within each group.
        YData (:,1) cell = {NaN}
        % Display names with one entry per scatter group.
        SeriesNames (:,1) string = "No data"
        % Scalar or RGB color payload with one entry per group.
        CData (:,1) cell = {NaN}
        % Optional {labels,values} data-tip template for each group.
        DataTipCells (:,1) cell = {[]}
    end

    methods

        function obj = ScatterData(opts)
        %SCATTERDATA Normalize data and validate alignment between groups.

            arguments
                opts.XData cell = {NaN}
                opts.YData cell = {NaN}
                opts.SeriesNames string = "No data"
                opts.CData cell = {NaN}
                opts.DataTipCells cell = {}
            end

            obj.XData = normalizeNumericCells(opts.XData,"XData");
            obj.YData = normalizeNumericCells(opts.YData,"YData");
            obj.SeriesNames = string(opts.SeriesNames(:));
            obj.CData = normalizeColorCells(opts.CData);
            obj.DataTipCells = normalizeDataTipCells( ...
                opts.DataTipCells,numel(obj.XData));
            obj.validateAlignment();
        end

    end

    methods (Access=private)

        function validateAlignment(obj)
        %VALIDATEALIGNMENT Require one aligned payload entry per scatter group.

            count = numel(obj.XData);

            if numel(obj.YData) ~= count || ...
                    numel(obj.SeriesNames) ~= count || numel(obj.CData) ~= count || ...
                    numel(obj.DataTipCells) ~= count
                error('matlabx:ui:axes:plot:ScatterDataGroupCountMismatch', ...
                    ['XData, YData, SeriesNames, CData, and DataTipCells ' ...
                    'must have equal group counts.']);
            end

            for k = 1:count
                pointCount = numel(obj.XData{k});

                if numel(obj.YData{k}) ~= pointCount
                    error('matlabx:ui:axes:plot:ScatterDataPointCountMismatch', ...
                        'XData and YData must have equal lengths in group %d.',k);
                end

                validateColorCount(obj.CData{k},pointCount,k);
                validateDataTipCell(obj.DataTipCells{k},pointCount,k);
            end
        end

    end

end

function templates = normalizeDataTipCells(templates,count)
%NORMALIZEDATATIPCELLS Expand omitted templates to one empty entry per group.
    if isempty(templates)
        templates = repmat({[]},count,1);
    else
        templates = templates(:);
    end
end

function validateDataTipCell(template,pointCount,index)
%VALIDATEDATATIPCELL Validate one optional group-aligned point template.
    if isempty(template)
        return;
    end
    if ~iscell(template) || size(template,1) ~= 1 || ...
            ~any(size(template,2) == [2 3]) || ...
            ~iscell(template{1}) || ~iscell(template{2}) || ...
            isempty(template{1}) || numel(template{1}) ~= numel(template{2})
        error('matlabx:ui:axes:plot:InvalidScatterDataTipCell', ...
            'DataTipCells group %d must contain a nonempty {labels,values} template.',index);
    end
    validateDataTipFormats(template,index,'Scatter');
    for row = 1:numel(template{2})
        value = template{2}{row};
        if ischar(value) || isscalar(value) || isa(value,'function_handle')
            continue;
        end
        if numel(value) ~= pointCount
            error('matlabx:ui:axes:plot:ScatterDataTipCountMismatch', ...
                'Data-tip row %d in group %d must be scalar or point-aligned.',row,index);
        end
    end
end

function validateDataTipFormats(template,index,~)
%VALIDATEDATATIPFORMATS Validate optional per-row format text.
    if numel(template) < 3
        return;
    end
    formats = template{3};
    if ~iscell(formats) || numel(formats) ~= numel(template{1}) || ...
            ~all(cellfun(@(x) (ischar(x) || (isstring(x) && isscalar(x))),formats))
        error('matlabx:ui:axes:plot:InvalidScatterDataTipFormats', ...
            'DataTipCells group %d formats must contain one text scalar per row.',index);
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
