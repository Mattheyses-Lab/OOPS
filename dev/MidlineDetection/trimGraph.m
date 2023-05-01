function trimmedGraph = trimGraph(G)
% given a weighted, undirected graph, G, extract the most central set of edges by trimming the shortest branches
% G should contain a property in the Node table called "Name"

% first identify the nodes with degree>2, these are the branchpoints
branchpointNodes = find(degree(G)>2);

% if we don't have any branchpoints, return the input graph
if isempty(branchpointNodes)
    trimmedGraph = G;
    return
end

% identify all nodes with degree==1, these are the outer ends of the branches
endpointNodes = find(degree(G)==1);

% get the distances between each endpoint and branchpoint node
endToBranchDistances = distances(G,endpointNodes,branchpointNodes);

% find the closest branchpointNode to each endpointNode, return distance to and idx of that branchpointNode
[branchLengths,branchIdxs] = min(endToBranchDistances,[],2);

% find the 2 longest branches and remove idxs to the corresponding endpointNodes and branchIdxs
% (because we do not want to remove these)
[~,longestBranches] = maxk(branchLengths,2);
branchIdxs(longestBranches) = [];
endpointNodes(longestBranches) = [];

% get the node names for our endpoints and branchpoints
endpointNodeNames = G.Nodes.Name(endpointNodes);
branchpointNodeNames = G.Nodes.Name(branchpointNodes);

% for each remaining endpointNode, cut its branch from the graph
for i = 1:numel(endpointNodes)
    % get the path from this endpointNode to the nearest branch (use node names not idxs, because idxs will change as we remove nodes)
    branchPath = shortestpath(G,findnode(G,endpointNodeNames{i}),findnode(G,branchpointNodeNames{branchIdxs(i)}));
    % remove each node along the path except for the branchpoint itself (otherwise we risk cutting our main branch)
    G = rmnode(G,branchPath(1:end-1));
end

% now recursively call to cut the next level of branches (if there are any)
trimmedGraph = trimGraph(G);

end