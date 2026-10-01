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

function txt = prettyPrint(S, opts)
%PRETTYPRINT Format scalar struct contents as readable text.
%   txt = PRETTYPRINT(S) returns formatted text for scalar struct S.
%
%   PRETTYPRINT(S) with no output prints to the command window.
%
%   Options:
%       OutputType       - "char" (default) or "string"
%       NameAlign        - "left" (default) or "right"
%       IndentSize       - spaces per nesting level (default 4)
%       StringArrayStyle - "inline" (default) or "lines"

    arguments
        S (1,1) struct
        opts.OutputType (1,1) string {mustBeMember(opts.OutputType, ["char","string"])} = "char"
        opts.NameAlign  (1,1) string {mustBeMember(opts.NameAlign,  ["left","right"])} = "left"
        opts.IndentSize (1,1) double {mustBeInteger, mustBeNonnegative} = 4
        opts.StringArrayStyle (1,1) string {mustBeMember(opts.StringArrayStyle, ["inline","lines"])} = "inline"
    end

    lines = buildLines(S, opts.NameAlign, opts.IndentSize, opts.StringArrayStyle);
    txtChar = strjoin(lines, newline);

    if opts.OutputType == "string"
        txt = string(txtChar);
    else
        txt = txtChar;
    end

    if nargout == 0
        fprintf('%s\n', txtChar);
    end
end

function lines = buildLines(S, nameAlign, indentSize, stringArrayStyle)

    fn = fieldnames(S);

    if isempty(fn)
        lines = {'[empty struct]'};
        return
    end

    isHeader = false(size(fn));
    for k = 1:numel(fn)
        v = S.(fn{k});
        isHeader(k) = isstruct(v) && isscalar(v);
    end

    leafNames = fn(~isHeader);
    headerNames = fn(isHeader);

    if isempty(leafNames)
        maxLen = 0;
    else
        maxLen = max(cellfun(@numel, leafNames));
    end

    lines = {};

    % First pass: non-header fields
    for k = 1:numel(leafNames)
        name = leafNames{k};
        value = S.(name);
        valLines = valueToLines(value, stringArrayStyle);

        switch nameAlign
            case "left"
                nameFmt = sprintf('%-*s', maxLen, name);
            case "right"
                nameFmt = sprintf('%*s', maxLen, name);
        end

        if isscalar(valLines)
            lines{end+1} = sprintf('%s: %s', nameFmt, valLines{1}); %#ok<AGROW>
        else
            lines{end+1} = name; %#ok<AGROW>
            pad = repmat(' ', 1, indentSize);
            valLines = cellfun(@(s) [pad s], valLines, 'UniformOutput', false);
            lines = [lines, valLines]; %#ok<AGROW>
        end
    end

    % Second pass: nested structs
    for k = 1:numel(headerNames)
        name = headerNames{k};
        value = S.(name);

        lines{end+1} = name; %#ok<AGROW>

        subLines = buildLines(value, nameAlign, indentSize, stringArrayStyle);
        pad = repmat(' ', 1, indentSize);
        subLines = cellfun(@(s) [pad s], subLines, 'UniformOutput', false);

        lines = [lines, subLines]; %#ok<AGROW>
    end
end

function lines = valueToLines(v, stringArrayStyle)

    if isstring(v) && ~isscalar(v) && stringArrayStyle == "lines"
        values = cellstr(v(:).');
        lines = cellfun(@(s) ['- ' s], values, 'UniformOutput', false);
        if isempty(lines)
            lines = {'[]'};
        end
        return
    end

    lines = {valueToChar(v)};
end

function out = valueToChar(v)

    if isstring(v)
        if isscalar(v)
            out = char(v);
        else
            q = strcat('"', cellstr(v), '"');
            out = ['[' strjoin(q, ', ') ']'];
        end

    elseif ischar(v)
        out = v;

    elseif islogical(v)
        if isempty(v)
            out = '[]';
        elseif isscalar(v)
            out = lower(char(string(v)));
        elseif isvector(v)
            out = ['[' strjoin(cellstr(lower(string(v(:).'))), ', ') ']'];
        else
            out = sprintf('[logical %s]', strjoin(string(size(v)), 'x'));
            out = char(out);
        end

    elseif isnumeric(v)
        if isempty(v)
            out = '[]';
        elseif isscalar(v)
            out = num2str(v);
        elseif isvector(v)
            c = arrayfun(@num2str, v(:).', 'UniformOutput', false);
            out = ['[' strjoin(c, ',') ']'];
        else
            out = sprintf('[%s %s]', class(v), strjoin(string(size(v)), 'x'));
            out = char(out);
        end

    else
        out = sprintf('[%s]', class(v));
    end
end
