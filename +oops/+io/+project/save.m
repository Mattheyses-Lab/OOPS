function save(project,file)
%SAVE Write a portable, pixel-free project snapshot to a MAT file.

    arguments
        project (1,1) oops.model.Project
        file (1,1) string
    end

    folder = string(fileparts(file));
    snapshot = project.toStruct(folder); %#ok<NASGU>
    savedName = oops.io.project.nameFromFile(file);
    snapshot.Name = savedName;
    save(file,'snapshot','-v7.3');
    project.Name = savedName;
    project.SourcePath = file;
    project.markClean();
    oops.Log.INFO("Saved project: " + file);
end
