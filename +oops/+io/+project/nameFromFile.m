function name = nameFromFile(file)
%NAMEFROMFILE Derive a project name from its saved filename.

    file = string(file);
    [~,stem,extension] = fileparts(file);
    stem = string(stem);

    if strcmpi(extension,'.mat') && endsWith(stem,'.oops','IgnoreCase',true)
        stem = extractBefore(stem,strlength(stem)-strlength(".oops")+1);
    end

    if stem == ""
        stem = "Untitled";
    end

    name = stem;
end
