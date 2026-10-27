% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [path,series] = sourceInfo(input)
%SOURCEINFO Read optional file-backed source metadata without loading pixels.
path = ""; series = NaN;
if isempty(input) || isempty(input.Source), return; end
source = input.Source;
if isstruct(source)
    if isfield(source,'FilePath'), path = string(source.FilePath); end
    if isfield(source,'SeriesIndex'), series = double(source.SeriesIndex); end
else
    if isprop(source,'FilePath'), path = string(source.FilePath); end
    if isprop(source,'SeriesIndex'), series = double(source.SeriesIndex); end
end
end
