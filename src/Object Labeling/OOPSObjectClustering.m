function [ClusterIdxs,nClusters] = OOPSObjectClustering(ObjectData,...
    nClusters,...
    nReplicates,...
    nClustersMode,...
    Criterion,...
    DistanceMetric,...
    NormalizationMethod)

% set rng to known state for consistent performance
rng(6,'twister');

% if a normalization method was selected
if ~strcmp(NormalizationMethod,'none')
    % normalize the data using the specified method
    ObjectData = normalize(ObjectData,1,NormalizationMethod);
end


%% perform k-means clustering with the specified parameters

maxK = 15;

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

        %figure();plot(ClusterEvalObj);


        disp(['Optimal number of clusters: ',num2str(nClusters)]);
end

% use 'replicates' name-value pair to repeat the clustering algorithm
%   for different randomly selected centroids for each replicate
[cidx3,cmeans3,sumd3] = kmeans(ObjectData,nClusters,...
    'replicates',nReplicates,...
    'Distance',DistanceMetric,...
    'display','final');
ClusterIdxs = cidx3;






    % 3rd output, sumd3, contains sum of distance within each cluster for the best solution

    % % figure to show silhouette plots
    % figure('Name',['Silhouette (Euclidean Distance,',num2str(nReplicates),' replicates)'])
    % % use silhouette plot to visualize cluster separation
    % [silh3,h] = silhouette(ObjectData,cidx3,'sqeuclidean');

    % display average silhouette width
    %disp(['Mean Silhouette Width (Euclidean Distance, ',num2str(nReplicates),' replicates): ',num2str(mean(silh3))])

%% Cosine distance k-means clustering

%     % use cosine distance instead of euclidean distance
%     [cidxCos,cmeansCos] = kmeans(ObjectData,nClusters,'dist','cos');
%     
%     figure('Name','Silhouette (Cosine Distance)')
%     
%     % visualize with silhouette
%     [silhCos,h] = silhouette(ObjectData,cidxCos,'cos');
%     [mean(silh2) mean(silh3) mean(silhCos)]
%     
%     figure('Name','3D Scatter (Cosine Distance)')
%     
%     % again plot the raw data
%     for i = 1:3
%         clust = find(cidxCos==i);
%         plot3(ObjectData(clust,VariablesToPlot(1)),...
%             ObjectData(clust,VariablesToPlot(2)),...
%             ObjectData(clust,VariablesToPlot(3)),...
%             ptsymb{i});        
%         hold on
%     end
%     hold off
%     
%     % add axes labels
%     xlabel(Var1Name);
%     ylabel(Var2Name);
%     zlabel(Var3Name);
%     
%     view(-137,10);
%     grid on
%     
%     figure('Name','Parallel Coordinate Plots (Cosine Clustering)')
% 
%     % -> plots don't show centroids, as cosine distance centroids correspond to half-line from origin
%     %      in space of raw data
%     % can make a parallel coordinate plot of normalized data points to view distances between centroids
%     lnsymb = {'b-','r-','m-','g-','y-'};
%     %names = {'SL','SW','PL','PW'};
%     ObjectData0 = ObjectData ./ repmat(sqrt(sum(ObjectData.^2,2)),1,length(VariablesList));
%     
%     ymin = min(min(ObjectData0));
%     ymax = max(max(ObjectData0));
%     for i = 1:nClusters
%         subplot(1,nClusters,i);
%         plot(ObjectData0(cidxCos==i,:)',lnsymb{i});
%         hold on;
%         plot(cmeansCos(i,:)','k-','LineWidth',2);
%         hold off;
%         title(sprintf('Cluster %d',i));
%         xlim([.9, length(VariablesList)+0.1]);
%         ylim([ymin, ymax]);
%         h_gca = gca;
%         h_gca.XTick = 1:length(VariablesList);
%         h_gca.XTickLabel = VariablesList;
%     end

end