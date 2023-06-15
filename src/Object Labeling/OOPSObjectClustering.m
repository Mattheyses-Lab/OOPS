function [ClusterIdxs,nClusters] = OOPSObjectClustering(ObjectData,...
    nClusters,...
    nReplicates,...
    nClustersMode,...
    Criterion,...
    DistanceMetric,...
    NormalizationMethod,...
    DisplayEvalutation)

% set rng to known state for consistent performance
rng(6,'twister');

% if a normalization method was selected
if ~strcmp(NormalizationMethod,'none')
    % normalize the data using the specified method
    ObjectData = normalize(ObjectData,1,NormalizationMethod);
end


%% perform k-means clustering with the specified parameters

maxK = 15;

% add the following to use parallel: 'Options',statset('UseParallel',1)

switch nClustersMode
    case 'Manual'
        disp(['Performing k-means clustering with ',num2str(nClusters),' clusters...']);
    case 'Auto'
        disp(['Determining the optimal value of k (max=',num2str(maxK),') with the ',Criterion,' criterion...']);
        clust = zeros(size(ObjectData,1),maxK);
        Sums = zeros(1,maxK);
        for i=1:maxK
            % run kmeans clustering with i clusters
            [clust(:,i),~,S,~] = kmeans(ObjectData,i,'replicate',nReplicates,'Distance',DistanceMetric);
            % save the within-cluster sums of point-to-centroid distances
            Sums(1,i) = sum(S);
        end

        % % plot Sums of within-cluster point-to-centroid distances
        % figure('Name','Within-Cluster Sums');
        % plot(1:10,Sums);
        % xlabel('Number of clusters (k)');
        % ylabel('Sum of within-cluster point-to-centroid distances');

        % evaluate the clusters using the user-selected criterion


        switch Criterion
            case 'CalinskiHarabasz'
                ClusterEvalObj = evalclusters(ObjectData,clust,Criterion);
                nClusters = ClusterEvalObj.OptimalK;
            case 'DaviesBouldin'
                ClusterEvalObj = evalclusters(ObjectData,clust,Criterion);
                nClusters = ClusterEvalObj.OptimalK;
            case 'silhouette'
                ClusterEvalObj = evalclusters(ObjectData,clust,Criterion,'Distance',DistanceMetric);
                nClusters = ClusterEvalObj.OptimalK;
        end


        if DisplayEvalutation
            fH_ClusterEvaluation = uifigure(...
                'Name','Cluster evaluation',...
                'HandleVisibility','on',...
                'WindowStyle','alwaysontop',...
                'Visible','off');
            uiaxes(fH_ClusterEvaluation,...
                "Units","normalized",...
                "OuterPosition",[0 0 1 1]);
            plot(ClusterEvalObj);
            movegui(fH_ClusterEvaluation,"center");
            fH_ClusterEvaluation.Visible = 'On';
        end

        disp(['Optimal number of clusters: ',num2str(nClusters)]);
end

% use 'replicates' name-value pair to repeat the clustering algorithm
%   for different randomly selected centroids for each replicate
[clust,C,sumd] = kmeans(ObjectData,nClusters,...
    'replicates',nReplicates,...
    'Distance',DistanceMetric,...
    'display','final');
ClusterIdxs = clust;


% C = cluster centroid locations

% testing below
% if just one variable was selected, attempt to resort the idxs based on centroid locations
if size(C,2)==1
    % sort the cluster centroids
    [Csort,sortIdx] = sort(C);
    % preallocate a new array to hold the sorted cluster idxs
    clustSort = zeros(size(clust));
    % for each element of the sorted centroid locations
    for i = 1:numel(Csort)
        % set the new sorted cluster idx
        clustSort(clust==sortIdx(i)) = i;
    end
    % any idxs originally set to NaN -> set to NaN
    clustSort(isnan(clust)) = NaN;
    % replaced the cluster idxs with the sorted idxs
    ClusterIdxs = clustSort;
end
% end testing



if DisplayEvalutation
    fH_Silhouette = uifigure(...
        'Name','Silhouette',...
        'HandleVisibility','on',...
        'WindowStyle','alwaysontop',...
        'Visible','off');
    uiaxes(fH_Silhouette,...
        "Units","normalized",...
        "OuterPosition",[0 0 1 1]);
    silhouette(ObjectData,ClusterIdxs);
    movegui(fH_Silhouette,"center");
    fH_Silhouette.Visible = 'On';
end


end