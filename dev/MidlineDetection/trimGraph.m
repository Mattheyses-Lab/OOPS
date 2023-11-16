function trimmedGraph = trimGraph(G)
% given a weighted, undirected graph, G, extract the most central set of edges by trimming the shortest branches
% G should contain a property in the Node table called "Name"
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

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