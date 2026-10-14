function reference = sourceReference(input,projectFolder)
%SOURCEREFERENCE Describe a file-backed Image5D source without storing pixels.

    arguments
        input (1,1) matlabx.image.Image5D
        projectFolder (1,1) string = ""
    end

    if ~input.IsFileBacked
        error('oops:project:MemorySource','Project files require file-backed image inputs.');
    end

    path = string(input.Source.FilePath);
    info = dir(path);
    relative = "";

    if projectFolder ~= ""
        prefix = string(projectFolder) + filesep;

        if startsWith(path,prefix)
            relative = extractAfter(path,strlength(prefix));
        end

    end

    reference = struct( ...
        'AbsolutePath',path, ...
        'RelativePath',relative, ...
        'Name',string(info.name), ...
        'Bytes',double(info.bytes), ...
        'Modified',string(info.date), ...
        'SeriesIndex',double(input.Source.SeriesIndex));
end
