function [project,resolution] = load(file,opts)
%LOAD Restore a project snapshot, resolving image sources without stored pixels.

    arguments
        file (1,1) string
        opts.SearchRoot (1,1) string = ""
    end

    oops.Log.DEBUG("Reading project snapshot: " + file);
    data = load(file,'snapshot');

    if ~isfield(data,'snapshot')
        error('oops:project:InvalidFile','The selected file does not contain an OOPS project.');
    end

    projectFolder = string(fileparts(file));
    oops.Log.DEBUG("Project snapshot loaded; starting source preflight.");
    [project,resolution] = oops.model.Project.fromStruct( ...
        data.snapshot,projectFolder,opts.SearchRoot);
    project.SourcePath = file;
    oops.Log.INFO("Opened project: " + file);
end
