function ColormapsObjects = customColormapHelper(Colormaps)
% Colormaps is a struct where each fieldname is the name of a colormap, each variable is a 256x3 array of RGB values
% for each colormap, this function will output a struct where each variable is a customColormap object with the same name

ColormapsObjects = struct();

colormapNames = fieldnames(Colormaps);

for i = 1:numel(colormapNames)
    name = colormapNames{i};
    map = Colormaps.(name);
    newCustomColormap = customColormap("Map",map,"Name",name);
    ColormapsObjects.(name) = newCustomColormap;
end


end