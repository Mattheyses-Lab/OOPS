classdef ControlTableColumn
%CONTROLTABLECOLUMN Definition of one ControlTable column.
%
%   C = matlabx.ui.control.ControlTableColumn(Name="Format", ...
%       Label="Format",Width=120,ControlType="dropdown", ...
%       Items=["PNG","OME-TIFF"],ItemsData=["png","ome-tiff"])
%
%   ControlType may be dropdown, checkbox, text, numeric, or color. A color
%   column stores one RGB triplet per table row and uses a uicolorpicker.
%
%   ItemsFcn receives (rowData,rowIndex,tableData) and returns
%   [items,itemsData]. EnabledFcn receives the same inputs and returns one
%   logical value.

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

    % Public declarative description of one ControlTable column.
    properties
        % Table variable name read and written by this column.
        Name (1,1) string = ""
        % Human-readable text displayed in the column header.
        Label (1,1) string = ""
        % Grid width expressed as pixels, "fit", or a weighted value.
        Width = "1x"
        % Native control kind: dropdown, checkbox, text, numeric, or color.
        ControlType (1,1) string = "text"
        % Static display labels used by dropdown columns.
        Items = string.empty(1,0)
        % Optional values corresponding to static dropdown Items.
        ItemsData = []
        % Optional callback returning row-dependent Items and ItemsData.
        ItemsFcn = []
        % Optional callback returning whether a row control is enabled.
        EnabledFcn = []
        % Whether controls in this column permit user edits.
        Editable (1,1) logical = true
    end

    methods
        function obj = ControlTableColumn(opts)
        %CONTROLTABLECOLUMN Construct and validate one column definition.
        %
        %   Name identifies the authoritative Data table variable. ItemsFcn
        %   and EnabledFcn receive (rowData,rowIndex,tableData), allowing a
        %   column to depend on values in its row or elsewhere in the table.
            arguments
                opts.Name (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.Width = "1x"
                opts.ControlType (1,1) string = "text"
                opts.Items = string.empty(1,0)
                opts.ItemsData = []
                opts.ItemsFcn = []
                opts.EnabledFcn = []
                opts.Editable (1,1) logical = true
            end
            obj.Name = opts.Name;
            obj.Label = opts.Label;
            obj.Width = opts.Width;
            obj.ControlType = lower(opts.ControlType);
            obj.Items = opts.Items;
            obj.ItemsData = opts.ItemsData;
            obj.ItemsFcn = opts.ItemsFcn;
            obj.EnabledFcn = opts.EnabledFcn;
            obj.Editable = opts.Editable;
            obj = obj.validate();
        end

        function obj = validate(obj)
        %VALIDATE Validate and normalize this definition.
            if strlength(obj.Name) == 0 || ~isvarname(char(obj.Name))
                error('matlabx:ui:control:ControlTableColumn:InvalidName', ...
                    'Name must be a nonempty valid MATLAB variable name.');
            end
            if strlength(obj.Label) == 0
                obj.Label = obj.Name;
            end
            obj.Width = normalizeWidth_(obj.Width);
            if ~ismember(obj.ControlType,["dropdown","checkbox","text","numeric","color"])
                error('matlabx:ui:control:ControlTableColumn:InvalidControlType', ...
                    'ControlType must be dropdown, checkbox, text, numeric, or color.');
            end
            validateFcn_(obj.ItemsFcn,'ItemsFcn');
            validateFcn_(obj.EnabledFcn,'EnabledFcn');
            if ~isempty(obj.ItemsData) && numel(obj.Items) ~= numel(obj.ItemsData)
                error('matlabx:ui:control:ControlTableColumn:ItemsSizeMismatch', ...
                    'Items and ItemsData must have equal lengths.');
            end
        end
    end

    methods (Static)
        function columns = normalize(value)
        %NORMALIZE Convert column objects or a struct array to definitions.
            if isempty(value)
                columns = matlabx.ui.control.ControlTableColumn.empty(1,0);
                return
            end
            if isa(value,'matlabx.ui.control.ControlTableColumn')
                columns = reshape(value,1,[]);
                for i = 1:numel(columns)
                    columns(i) = columns(i).validate();
                end
                return
            end
            if ~isstruct(value)
                error('matlabx:ui:control:ControlTableColumn:InvalidDefinitions', ...
                    'Columns must be ControlTableColumn objects or a struct array.');
            end
            columns = matlabx.ui.control.ControlTableColumn.empty(1,0);
            fields = ["Name","Label","Width","ControlType","Items", ...
                "ItemsData","ItemsFcn","EnabledFcn","Editable"];
            for i = 1:numel(value)
                args = {};
                for field = fields
                    if isfield(value(i),field)
                        args(end+1:end+2) = {char(field),value(i).(field)};
                    end
                end
                columns(end+1) = matlabx.ui.control.ControlTableColumn(args{:}); %#ok<AGROW>
            end
        end
    end
end

function width = normalizeWidth_(width)
%NORMALIZEWIDTH_ Validate and normalize a grid-layout column width.
    if isnumeric(width)
        if ~isscalar(width) || ~isfinite(width) || width < 0
            error('matlabx:ui:control:ControlTableColumn:InvalidWidth', ...
                'Numeric Width must be a finite nonnegative scalar.');
        end
        width = double(width);
        return
    end
    if ~(ischar(width) || (isstring(width) && isscalar(width)))
        error('matlabx:ui:control:ControlTableColumn:InvalidWidth', ...
            'Width must be numeric, "fit", or a positive weighted value such as "1x".');
    end
    width = lower(strtrim(string(width)));
    if width == "fit"
        width = 'fit';
        return
    end
    token = regexp(width,'^(\d*\.?\d+)x$','tokens','once');
    if isempty(token) || str2double(token{1}) <= 0
        error('matlabx:ui:control:ControlTableColumn:InvalidWidth', ...
            'Text Width must be "fit" or a positive weighted value such as "1x".');
    end
    width = char(width);
end

function validateFcn_(value,name)
%VALIDATEFCN_ Require an optional column callback to be a function handle.
    if ~isempty(value) && ~isa(value,'function_handle')
        error('matlabx:ui:control:ControlTableColumn:InvalidFunction', ...
            '%s must be empty or a function handle.',name);
    end
end
