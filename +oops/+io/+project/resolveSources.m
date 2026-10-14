function resolved = resolveSources(snapshot,projectFolder,searchRoot,opts)
%RESOLVESOURCES Preflight every project source before constructing the model.

    arguments
        snapshot (1,1) struct
        projectFolder (1,1) string = ""
        searchRoot (1,1) string = ""
        opts.Progress = []
    end

    resolved = struct( ...
        'Calibrations',strings(numel(snapshot.Calibrations),1), ...
        'Images',{cell(numel(snapshot.Groups),1)}, ...
        'AuxiliaryChannels',{cell(numel(snapshot.Groups),1)}, ...
        'Relinked',struct('Kind',{},'OriginalPath',{},'ResolvedPath',{}));
    problems = strings(0,1);
    searchIndex = struct.empty(0,1);

    imageCount = 0;
    auxiliaryCount = 0;

    for g = 1:numel(snapshot.Groups)
        imageCount = imageCount + numel(snapshot.Groups(g).Images);

        for i = 1:numel(snapshot.Groups(g).Images)

            if isfield(snapshot.Groups(g).Images(i),'AuxiliaryChannels')
                auxiliaryCount = auxiliaryCount + ...
                    numel(snapshot.Groups(g).Images(i).AuxiliaryChannels);
            end

        end
    end

    sourceCount = numel(snapshot.Calibrations) + imageCount + auxiliaryCount;
    sourceIndex = 0;
    oops.Log.DEBUG(sprintf( ...
        "Preflighting %d project sources (%d calibrations, %d images, %d auxiliary channels).", ...
        sourceCount,numel(snapshot.Calibrations),imageCount,auxiliaryCount));

    if searchRoot ~= "" && isfolder(searchRoot)
        oops.Log.DEBUG("Indexing relocation search folder recursively: " + searchRoot);
        oops.runtime.updateProgress(opts.Progress, ...
            "Indexing relocation search folder...",[]);
        searchIndex = dir(fullfile(searchRoot,"**","*"));
        searchIndex = searchIndex(~[searchIndex.isdir]);
        oops.Log.DEBUG(sprintf( ...
            "Indexed %d files beneath relocation search folder.",numel(searchIndex)));
    elseif searchRoot ~= ""
        oops.Log.DEBUG("Relocation search folder is unavailable: " + searchRoot);
    end

    for k = 1:numel(snapshot.Calibrations)
        sourceIndex = sourceIndex+1;
        reportResolutionProgress(opts.Progress,"calibration",sourceIndex,sourceCount);
        reference = snapshot.Calibrations(k).Source;
        [path,status,candidates] = oops.io.project.resolveSource( ...
            reference,projectFolder,searchRoot,searchIndex);
        resolved.Calibrations(k) = path;

        if status ~= "Resolved"
            problems(end+1,1) = describeProblem("Calibration",reference,status,candidates); %#ok<AGROW>
        elseif path ~= string(reference.AbsolutePath)
            resolved.Relinked(end+1) = relinkedSource( ...
                "Calibration",reference.AbsolutePath,path); %#ok<AGROW>
        end

    end

    for g = 1:numel(snapshot.Groups)
        images = snapshot.Groups(g).Images;
        resolved.Images{g} = strings(numel(images),1);
        resolved.AuxiliaryChannels{g} = cell(numel(images),1);

        for k = 1:numel(images)
            sourceIndex = sourceIndex+1;
            reportResolutionProgress(opts.Progress,"image",sourceIndex,sourceCount);
            reference = images(k).Source;
            [path,status,candidates] = oops.io.project.resolveSource( ...
                reference,projectFolder,searchRoot,searchIndex);
            resolved.Images{g}(k) = path;

            if status ~= "Resolved"
                problems(end+1,1) = describeProblem("Image",reference,status,candidates); %#ok<AGROW>
            elseif path ~= string(reference.AbsolutePath)
                resolved.Relinked(end+1) = relinkedSource( ...
                    "Image",reference.AbsolutePath,path); %#ok<AGROW>
            end

            assignments = struct.empty(0,1);

            if isfield(images(k),'AuxiliaryChannels')
                assignments = images(k).AuxiliaryChannels;
            end

            resolved.AuxiliaryChannels{g}{k} = strings(numel(assignments),1);

            for a = 1:numel(assignments)
                sourceIndex = sourceIndex+1;
                reportResolutionProgress(opts.Progress,"auxiliary channel",sourceIndex,sourceCount);
                reference = assignments(a).Source;
                [path,status,candidates] = oops.io.project.resolveSource( ...
                    reference,projectFolder,searchRoot,searchIndex);
                resolved.AuxiliaryChannels{g}{k}(a) = path;

                if status ~= "Resolved"
                    problems(end+1,1) = describeProblem( ...
                        "Auxiliary channel",reference,status,candidates); %#ok<AGROW>
                elseif path ~= string(reference.AbsolutePath)
                    resolved.Relinked(end+1) = relinkedSource( ...
                        "Auxiliary channel",reference.AbsolutePath,path); %#ok<AGROW>
                end
            end

        end

    end

    if ~isempty(problems)
        oops.Log.DEBUG(sprintf( ...
            "Source preflight failed with %d unresolved or ambiguous references.", ...
            numel(problems)));
        shown = problems(1:min(12,numel(problems)));
        message = string(numel(problems)) + " project source(s) could not be resolved:" + ...
            newline + newline + join(shown,newline);

        if numel(problems) > numel(shown)
            message = message + newline + "...and " + ...
                string(numel(problems)-numel(shown)) + " more.";
        end

        error('oops:project:MissingSources','%s',message);
    end

    oops.Log.DEBUG(sprintf( ...
        "Source preflight completed successfully for %d references.",sourceCount));

    if ~isempty(resolved.Relinked)
        oops.Log.INFO(sprintf( ...
            "Relinked %d project sources to new locations.",numel(resolved.Relinked)));
    end
end

function reportResolutionProgress(progress,kind,index,count)
%REPORTRESOLUTIONPROGRESS Report source preflight without exposing path details.

if count == 0
    value = .4;
else
    value = .1+.3*(index/count);
end

message = "Checking " + kind + " source " + string(index) + ...
    " of " + string(count) + "...";
oops.runtime.updateProgress(progress,message,value);
end

function item = relinkedSource(kind,originalPath,resolvedPath)
%RELINKEDSOURCE Create one compact entry for logs and post-load UI reporting.

    item = struct( ...
        'Kind',string(kind), ...
        'OriginalPath',string(originalPath), ...
        'ResolvedPath',string(resolvedPath));
end

function text = describeProblem(kind,reference,status,candidates)
%DESCRIBEPROBLEM Format one missing or ambiguous source with its original path.

    text = status + " " + kind + ": " + string(reference.AbsolutePath);

    if status == "Ambiguous"
        text = text + " (" + string(numel(candidates)) + " equally likely matches)";
    end
end
