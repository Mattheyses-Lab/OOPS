%% script to import .pal as matlab colormap vector

files = [dir('*FWD-10.pal'); dir('*10-FWD.pal')];
map = struct;

for ii = 1:numel(files)
    raw = readmatrix(files(ii).name, 'FileType', 'text');
    map(ii).data = raw(33:145,2:4);
    

    name_comps = split(files(ii).name,["-","."]);
    map_name = [];

    for jj = 3:numel(name_comps)-1
        map_name = [map_name name_comps{jj}];
    end

    map(ii).name = map_name;
end

save WesAndersonColors map