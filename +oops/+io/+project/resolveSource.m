function [path,status,candidates] = resolveSource(reference,projectFolder,searchRoot,searchIndex)
%RESOLVESOURCE Find one source using exact paths, tree context, and metadata.

    arguments
        reference (1,1) struct
        projectFolder (1,1) string = ""
        searchRoot (1,1) string = ""
        searchIndex struct = struct.empty(0,1)
    end

    exactCandidates = string.empty(0,1);
    originalPath = string(reference.AbsolutePath);
    oops.Log.DEBUG("Resolving project source: " + originalPath);

    if isfield(reference,'AbsolutePath')
        exactCandidates(end+1,1) = string(reference.AbsolutePath);
    end

    if projectFolder ~= "" && isfield(reference,'RelativePath') && ...
            string(reference.RelativePath) ~= ""
        exactCandidates(end+1,1) = fullfile(projectFolder,string(reference.RelativePath));
    end

    for candidate = exactCandidates'

        oops.Log.DEBUG("Checking exact source candidate: " + candidate);

        if isfile(candidate)
            path = candidate;
            status = "Resolved";
            candidates = path;
            oops.Log.DEBUG("Resolved source by exact path: " + path);
            return;
        end

    end

    path = "";
    status = "Missing";
    candidates = string.empty(0,1);

    if searchRoot == "" || ~isfolder(searchRoot)
        oops.Log.DEBUG("No recursive search folder is available for: " + originalPath);
        return;
    end

    if isempty(searchIndex)
        matches = dir(fullfile(searchRoot,"**",string(reference.Name)));
        matches = matches(~[matches.isdir]);
    else
        matches = searchIndex(strcmp({searchIndex.name},char(reference.Name)));
    end

    if isempty(matches)
        oops.Log.DEBUG("Recursive search found no filename matches for: " + ...
            string(reference.Name));
        return;
    end

    candidates = string(fullfile({matches.folder},{matches.name}))';
    oops.Log.DEBUG(sprintf( ...
        "Recursive search found %d filename matches for %s.", ...
        numel(candidates),string(reference.Name)));

    % Each filename match receives evidence rather than being discarded on
    % one imperfect metadata field. Folder context is the strongest signal
    % when different experimental groups reuse standard filenames.
    scores = zeros(numel(matches),1);
    original = splitPath(string(reference.AbsolutePath));

    for k = 1:numel(matches)
        candidate = splitPath(candidates(k));
        scores(k) = matchingSuffixLength(original,candidate) * 100;

        if isfield(reference,'Bytes') && matches(k).bytes == double(reference.Bytes)
            scores(k) = scores(k) + 10;
        end

        if isfield(reference,'Modified') && string(matches(k).date) == string(reference.Modified)
            scores(k) = scores(k) + 1;
        end

        oops.Log.DEBUG(sprintf( ...
            "Candidate score %g for %s.",scores(k),candidates(k)));

    end

    best = max(scores);
    winners = find(scores == best);

    if isscalar(winners)
        path = candidates(winners);
        status = "Resolved";
        oops.Log.DEBUG(sprintf( ...
            "Resolved source to unique best candidate (score %g): %s",best,path));
    else
        status = "Ambiguous";
        candidates = candidates(winners);
        oops.Log.DEBUG(sprintf( ...
            "Source remains ambiguous: %d candidates share best score %g for %s.", ...
            numel(candidates),best,originalPath));

        for candidate = candidates'
            oops.Log.DEBUG("Ambiguous source candidate: " + candidate);
        end
    end
end

function parts = splitPath(path)
%SPLITPATH Normalize a path into comparable nonempty folder components.

    path = replace(string(path),"\",'/');
    parts = split(path,'/');
    parts(parts == "") = [];
end

function count = matchingSuffixLength(a,b)
%MATCHINGSUFFIXLENGTH Count equal trailing path components, including filename.

    count = 0;
    limit = min(numel(a),numel(b));

    for k = 1:limit

        if a(end-k+1) ~= b(end-k+1)
            return;
        end

        count = count + 1;
    end
end
