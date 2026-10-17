classdef ViolinData
%VIOLINDATA Normalized, validated data for grouped violin/swarm rendering.
% Values and their color data remain aligned within each logical group.
%
%   data = matlabx.ui.axes.plot.ViolinData( ...
%       Values={randn(1,100),randn(1,80)+1}, ...
%       SeriesNames=["Control","Treatment"], ...
%       CData={[0.2 0.5 0.8],[0.8 0.3 0.2]});
%
% CData entries may be one RGB triplet, one scalar per value, or one RGB
% triplet per value. DataTipCells and SummaryDataTipCells optionally supply
% one {labels,values[,formats]} template per group; empty entries use generated
% defaults. Empty row formats use ViolinStyle.DataTipFormat.
%
%   data = matlabx.ui.axes.plot.ViolinData( ...
%       Values={values},SeriesNames="Control",CData={[0 0.45 0.74]}, ...
%       DataTipCells={{{"Sample","Value"},{sampleIDs,values}, ...
%       {"","%.2f"}}}, ...
%       SummaryDataTipCells={{{"Condition","Score"},{"Control",score}, ...
%       {"","%.3g"}}});
%
% See also matlabx.ui.axes.plot.ViolinRenderer,
% matlabx.ui.axes.plot.ViolinStyle

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

    % Normalized group-aligned payload consumed by ViolinRenderer.
    properties (SetAccess=private)
        % Numeric observations, stored as one row vector per group.
        Values (:,1) cell = {NaN}
        % Display names with one entry per violin group.
        SeriesNames (:,1) string = "No data"
        % Scalar or RGB color payload with one entry per group.
        CData (:,1) cell = {NaN}
        % Optional point data-tip template for each violin group.
        DataTipCells (:,1) cell = {[]}
        % Optional central-line summary template for each violin group.
        SummaryDataTipCells (:,1) cell = {[]}
    end

    methods

        function obj = ViolinData(opts)
        %VIOLINDATA Normalize values and validate group/color alignment.

            arguments
                opts.Values cell = {NaN}
                opts.SeriesNames string = "No data"
                opts.CData cell = {NaN}
                opts.DataTipCells cell = {}
                opts.SummaryDataTipCells cell = {}
            end

            obj.Values = normalizeNumericCells(opts.Values,"Values");
            obj.SeriesNames = string(opts.SeriesNames(:));
            obj.CData = normalizeColorCells(opts.CData);
            count = numel(obj.Values);
            obj.DataTipCells = normalizeDataTipCells(opts.DataTipCells,count);
            obj.SummaryDataTipCells = normalizeDataTipCells( ...
                opts.SummaryDataTipCells,count);
            obj.validateAlignment();
        end

    end

    methods (Access=private)

        function validateAlignment(obj)
        %VALIDATEALIGNMENT Require one name and color payload per violin group.

            count = numel(obj.Values);

            if numel(obj.SeriesNames) ~= count || numel(obj.CData) ~= count || ...
                    numel(obj.DataTipCells) ~= count || ...
                    numel(obj.SummaryDataTipCells) ~= count
                error('matlabx:ui:axes:plot:ViolinDataGroupCountMismatch', ...
                    ['Values, SeriesNames, CData, DataTipCells, and ' ...
                    'SummaryDataTipCells must have equal group counts.']);
            end

            for k = 1:count
                validateColorCount(obj.CData{k},numel(obj.Values{k}),k);
                validateDataTipCell(obj.DataTipCells{k},numel(obj.Values{k}),k,"point");
                validateDataTipCell(obj.SummaryDataTipCells{k},[],k,"summary");
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

function validateDataTipCell(template,valueCount,index,kind)
%VALIDATEDATATIPCELL Validate one optional point or summary template.
    if isempty(template)
        return;
    end
    if ~iscell(template) || size(template,1) ~= 1 || ...
            ~any(size(template,2) == [2 3]) || ...
            ~iscell(template{1}) || ~iscell(template{2}) || ...
            isempty(template{1}) || numel(template{1}) ~= numel(template{2})
        error('matlabx:ui:axes:plot:InvalidViolinDataTipCell', ...
            '%s DataTipCells group %d must contain a nonempty {labels,values} template.', ...
            kind,index);
    end
    validateDataTipFormats(template,index,kind);
    if kind == "summary"
        return;
    end
    for row = 1:numel(template{2})
        value = template{2}{row};
        if ischar(value) || isscalar(value) || isa(value,'function_handle')
            continue;
        end
        if numel(value) ~= valueCount
            error('matlabx:ui:axes:plot:ViolinDataTipCountMismatch', ...
                'Data-tip row %d in group %d must be scalar or value-aligned.',row,index);
        end
    end
end

function validateDataTipFormats(template,index,kind)
%VALIDATEDATATIPFORMATS Validate optional per-row format text.
    if numel(template) < 3
        return;
    end
    formats = template{3};
    if ~iscell(formats) || numel(formats) ~= numel(template{1}) || ...
            ~all(cellfun(@(x) (ischar(x) || (isstring(x) && isscalar(x))),formats))
        error('matlabx:ui:axes:plot:InvalidViolinDataTipFormats', ...
            '%s DataTipCells group %d formats must contain one text scalar per row.', ...
            kind,index);
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
