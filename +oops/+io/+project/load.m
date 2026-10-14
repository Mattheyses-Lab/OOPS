function [project,resolution] = load(file,opts)
%LOAD Restore a project snapshot, resolving image sources without stored pixels.

    arguments
        file (1,1) string
        opts.SearchRoot (1,1) string = ""
        opts.Progress = []
    end

    oops.runtime.updateProgress(opts.Progress,"Reading project file...",.02);
    oops.Log.DEBUG("Reading project snapshot: " + file);
    data = load(file,'snapshot');

    if ~isfield(data,'snapshot')
        error('oops:project:InvalidFile','The selected file does not contain an OOPS project.');
    end

    projectFolder = string(fileparts(file));
    oops.Log.DEBUG("Project snapshot loaded; starting source preflight.");
    oops.runtime.updateProgress(opts.Progress,"Checking project image sources...",.08);
    [project,resolution] = oops.model.Project.fromStruct( ...
        data.snapshot,projectFolder,opts.SearchRoot,Progress=opts.Progress);
    project.SourcePath = file;
    oops.Log.INFO("Opened project: " + file);
end
