function folderNames = getFolderNames(queryFolder)
%  getFolderNames  lists folders in specified directory

    % get the contents of the queryFolder
    fList = dir(queryFolder);
    % extract list of non-hidden folder names (those that do not start with '.')
    folderNames = {fList([fList.isdir] & ~cellfun(@(x) strcmp('.',x(1)),{fList.name},'UniformOutput',true)).name};

end