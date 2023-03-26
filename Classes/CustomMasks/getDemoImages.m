function [demoImagesPath,demoImages]=getDemoImages()
    pth = fileparts(which('cameraman.tif'));
    D = dir(pth);
    C = {'.tif';'.jp';'.png';'.bmp'};
    idx = false(size(D));
    for ii = 1:length(C)
        idx = idx | (arrayfun(@(x) any(strfind(x.name,C{ii})),D));
    end
    D = D(idx);
    demoImages = cell(numel(D),1);
    for ii = 1:numel(D)
        demoImages{ii} = D(ii).name;
        fprintf('%s\n',D(ii).name)
    end

    demoImagesPath = pth;
end