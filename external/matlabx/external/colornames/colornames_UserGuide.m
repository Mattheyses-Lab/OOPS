%% |COLORNAMES| User Guide
%
% The function <https://www.mathworks.com/matlabcentral/fileexchange/48155
% |COLORNAMES|> matches the input RGB values or input color names to the
% closest colors from the selected palette. |COLORNAMES| always returns
% the same outputs, regardless of whether matching RGB or names:
%
%   [names,RGB] = colornames(palette,RGB)
%   [names,RGB] = colornames(palette,names)
%
% This document shows some examples of using |COLORNAMES| to match
% RGB values or color names, and example usage of the bonus functions.
%
%% Palette Descriptions
%
% Palettes of named colors have been defined by various people and groups,
% often intended for very different applications. |COLORNAMES| supports a
% wide selection of common color palettes: a detailed list of the supported
% palettes is printed in the command window by simply calling |COLORNAMES|
% with no input arguments and no output arguments:
colornames()
%% Return Palette Names
%
% To return a cell array of the supported palettes simply call
% |COLORNAMES| with no input arguments and one output argument:
palettes = colornames()
%% Return All Color Names and RGB Values for One Palette
%
% Simply call |COLORNAMES| with the name of the required palette. If the
% palette name is string then the color names will be a string array,
% otherwise the color names will be a cell array of character vectors.
[names,rgb] = colornames("MATLAB")
%% Match Exact Color Names
%
% |COLORNAMES| attempts to match each input name to a color name from the
% specified palette. Note that CamelCase signifies separate words (for some
% palettes space characters may be significant, e.g. |Foster| and |xkcd| ).
%
% The input names may supplied as either:
%
% * one array (either a string array or a cell array of character vectors)
% * separate input arguments (string scalars or character vectors)
[names,rgb] = colornames("xkcd",["red","green","blue"])
[names,rgb] = colornames("xkcd",'eggshell',"eggShell")
%% Match Closest Color Names
%
% If |COLORNAMES| cannot match the input name exactly then |COLORNAMES|
% attempts to find the closest color name using these two steps:
%
% # the palette names are filtered for only those color names that contain
%   every character of the input name (note that the characters must be
%   in the same order, but are not required to be consecutive),
% # the shortest <https://en.wikipedia.org/wiki/Levenshtein_distance Levenshtein distance>
%   is used to select the best matching name from the filtered list.
colornames('wikipedia','azu()','azweb','azure X11','azurex','zx')
%% Match Index Number
%
% Palettes with a leading index number may be matched by just the number,
% or just the name, or both together (as given in the palette color names array):
colornames("CGA",'9','LightBlue','lightblue','9 Light Blue','9lightblue')
%% Match Initial Letter
%
% Palettes |Alphabet|, |MATLAB|, and |Natural| also match the initial
% letter to the color names (except for 'Black' which is matched by 'K'):
colornames("MATLAB","c","m","y","k")
%% Match Diacritics
%
% Letters with diacritics will be matched with or without the diacritic:
colornames('SherwinWilliams','Jalapeño','Jalapeno','Rosé','Rose')
%% Match RGB
%
% Each provided RGB triple is matched to the closest RGB triple from the
% requested palette:
[names,rgb] = colornames('HTML4', [0,0.2,1;1,0.2,0])
%% Match RGB, Selecting the Color Difference Metric
%
% Input RGB values are matched using one of several standard, well defined
% <https://en.wikipedia.org/wiki/Color_difference color difference> metrics
% known as $\Delta E$ or _deltaE_. The default deltaE is "CIE94:2",
% which provides good matching for most palettes and colors. Other deltaE
% calculations can be selected by using the third input argument:
rgb = [0,0.42,1]; % input RGB
tmp = {'CIEDE2000','DIN99','CIE94:1','CIE94:2','OKLab','CIE76','CMC2:1','CMC1:1','RGB'};
tmp(2,:) = cellfun(@(de) colornames('HTML4',rgb,de), tmp);
fprintf('%13s  %s\n',tmp{:})
% Show the input color:
image(reshape(rgb,1,1,3))
% Overlay all HTML4 palette colors:
[names,rgb] = colornames('HTML4');
X = linspace(0.5,1.5,2+numel(names));
X = num2cell(X(2:end-1));
F = @(x,y,n,c)text(x,y,n,'BackgroundColor',c,'HorizontalAlignment','center');
cellfun(F, X(:),X(:),names(:),num2cell(rgb,2))
title('Input Color vs Palette Colors')
text(X{1},X{end},{'Which palette color (diagonal tiles)',...
	'best matches the input color (background)?'},...
	'BackgroundColor',[1,1,1], 'VerticalAlignment','bottom')
%% BONUS: View the Color Difference in a Figure
%
% The bonus function |COLORNAMES_GUI_DELTAE| demonstrates how the different
% deltaE metrics match the provided RGB to the palette colors. Simply
% select the palette, provide an Nx3 RGB colormap, and all deltaE metrics
% are listed with the matched colors displayed in the columns below:
colornames_GUI_deltaE('HTML4',jet(16))
%% BONUS: View the Palette Colors in 2D
%
% The bonus function |COLORNAMES_GUI_VIEW| plots the palettes in a figure.
% Drop-down menus select the palette, and also how the colors are sorted.
% Click on any color to view its hex RGB value (value may be approximate).
colornames_GUI_view('dvips','Lab')
%% BONUS: View the Palette Colors in 3D
%
% The bonus function |COLORNAMES_GUI_CUBE| plots the palettes in a figure.
% The <http://www.mathworks.com/help/matlab/creating_plots/data-cursor-displaying-data-values-interactively.html
% data cursor> can be used to view the color names, by clicking on the nodes.
% Drop-down menus select the palette and the color space of the colorcube:
colornames_GUI_cube('CSS','Lab')
%% BONUS: Interactive Name Search (R2023b or later)
%
% The bonus function |COLORNAMES_GUI_SEARCH| is an interactive tool showing
% the input color name matching in real-time as you type. For example, here
% it shows the filtered palette colornames that contain the characters
% 'TMW' (must in that order, but are not required to be consecutive):
colornames_GUI_search('Wikipedia','TMW')
%% BONUS: Add A New Palette
%
% Adding a new color palette to the tool is easy: simply append a suitably-
% named scalar structure to |COLORNAMES.MAT| (by calling |SAVE()| with the
% |-APPEND| option). The structure must contain the following two fields:
%
% # *|names|* : an Nx1 cell array of character vectors, either written as
%               space-separated initial-capitalized words or in CamelCase.
% # *|rgb|*   : an Nx3 numeric matrix of the corresponding RGB values. The
%               values must range from zero to one for double/single
%               arrays and from zero to INTMAX() for integer arrays.
%
% and optionally also include any of the following fields:
%
% # *|license|* : CharVector, the license information for the palette.
% # *|source|*  : CharVector, a reference of the origin (e.g. URL).
% # *|notes|*   : CharVector, a short description of the palette.
% # *|index|*   : LogicalScalar, where TRUE specifies that the colornames
%                 have a leading index number. If |index| is not provided
%                 then it will be automagically determined from |names|.
%% Unmatched Input Name Error
%
% If an input name cannot be matched to a palette color name then
% |COLORNAMES| will throw an error. It displays a short list of palette
% color names that are similar to the input name:
colornames('HTML4', 'Bleu', 'Blanc', 'Rouge')