function [colormapsStruct,colorPalettesStruct] = ColorBrewerHelper()
%%  ColorBrewerHelper  returns a struct containing MATLAB format colormaps from 
%       Cynthia Brewer's sequential and divergent ColorBrewer color schemes
%
%       also returns a struct containing a list of colors from the qualitative
%       ColorBrewer color schemes

colormapsStruct = struct();

colorPalettesStruct = struct();

sequantialColormaps = {...
    'Blues'; ...
    'BuGn'; ...
    'BuPu'; ...
    'GnBu'; ...
    'Greens'; ...
    'Greys'; ...
    'Oranges'; ...
    'OrRd'; ...
    'PuBu'; ...
    'PuBuGn'; ...
    'PuRd'; ...
    'Purples'; ...
    'RdPu'; ...
    'Reds'; ...
    'YlGn'; ...
    'YlGnBu'; ...
    'YlOrBr'; ...
    'YlOrRd'};

for i = 1:numel(sequantialColormaps)
    colormapsStruct.(sequantialColormaps{i}) = brewermap(256,sequantialColormaps{i});
end

% divergent colormaps
divergentColormaps = {...
    'BrBG'; ...     
    'PiYG'; ...     
    'PRGn'; ...     
    'PuOr'; ...     
    'RdBu'; ...     
    'RdGy'; ...     
    'RdYlBu'; ...   
    'RdYlGn'; ... 	
    'Spectral'};

for i = 1:numel(divergentColormaps)
    colormapsStruct.(divergentColormaps{i}) = brewermap(256,divergentColormaps{i});
end
    
% qualitative colormaps
qualitativeColormaps = {...
    'Accent'; ...   
    'Dark2'; ...    
    'Paired'; ...   
    'Pastel1'; ...  
    'Pastel2'; ...  
    'Set1'; ...     
    'Set2'; ...     
    'Set3'};

nNodes = [8,8,12,9,8,9,8,12];

for i = 1:numel(qualitativeColormaps)
    colorPalettesStruct.(qualitativeColormaps{i}) = brewermap(nNodes(i),qualitativeColormaps{i});
end

end