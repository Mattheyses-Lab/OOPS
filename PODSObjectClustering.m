function [ClusterIdxs,nClusters] = PODSObjectClustering(ObjectData,...
    nClusters,...
    nReplicates,...
    VariablesList,...
    VariablesToPlot,...
    nClustersMode,...
    Criterion)

    Var1Name = VariablesList{VariablesToPlot(1)};
    Var2Name = VariablesList{VariablesToPlot(2)};
    Var3Name = VariablesList{VariablesToPlot(3)};

    % set rng to known state to replicate output from tutorial
    rng(6,'twister');

%% Euclidean distance k-means clustering

%     % call kmeans() and set desired n clusters
%     [cidx2,cmeans2] = kmeans(ObjectData,nClusters,'dist','sqeuclidean');
%     
%     figure('Name','Silhouette (Euclidean Distance)')
%     
%     % silhouette plot to visualize separation of clusters
%     [silh2,h] = silhouette(ObjectData,cidx2,'sqeuclidean');
%     
    % different symbols for each cluster
    %ptsymb = {'bs','r^','go','md','c+','ysquare'};
    
%     figure('Name','3D Scatter (Euclidean Distance)')
%     
%     % visualize in 3 dimensions
%     for i = 1:nClusters
%         clust = find(cidx2==i);
%         plot3(ObjectData(clust,VariablesToPlot(1)),...
%             ObjectData(clust,VariablesToPlot(2)),...
%             ObjectData(clust,VariablesToPlot(3)),...
%             ptsymb{i});
%         hold on
%     end
%     
%     % cluster centroids are plotted with circled x's
%     plot3(cmeans2(:,VariablesToPlot(1)),cmeans2(:,VariablesToPlot(2)),cmeans2(:,VariablesToPlot(3)),'ko');
%     plot3(cmeans2(:,VariablesToPlot(1)),cmeans2(:,VariablesToPlot(2)),cmeans2(:,VariablesToPlot(3)),'kx');
%     hold off
%     
%     % add axes labels
%     xlabel(Var1Name);
%     ylabel(Var2Name);
%     zlabel(Var3Name);
%     
%     % set view angle
%     view(-137,10);
%     
%     grid on
%     
%     % display average silhouette width
%     disp(['Mean Silhouette Width (Euclidean Distance): ',num2str(mean(silh2))])

%% Euclidean distance k-means clustering (DETERMINE OPTIMUM NUMBER OF CLUSTERS, with more replicates) BEST SO FAR

switch nClustersMode
    case 'Manual'
        disp(['Performing k-means clustering with ',num2str(nClusters),' clusters...']);
    case 'Auto'
        disp(['Determining the optimal value of k (max=10) with the ',Criterion,' criterion...']);
        clust = zeros(size(ObjectData,1),10);
        % sums of squared errors for each object - needs work
        %Distances = zeros(size(ObjectData,1),10);
        Sums = zeros(1,10);
        for i=1:10
%             [clust(:,i),~,~,D] = kmeans(ObjectData,i,'replicate',nReplicates);
%             Distances(:,i) = D(:,i);
            [clust(:,i),~,S,~] = kmeans(ObjectData,i,'replicate',nReplicates);
            Sums(1,i) = sum(S);
        end
        % within-cluster-sum of squared errors (WSS)
        % (sum of squared distances between all points and their centroids)
%         WSS = sum(Distances.^2);
        figure('Name','Within-Cluster Sums');
        plot(1:10,Sums);
        xlabel('Number of clusters (k)');
        ylabel('Sum of within-cluster point-to-centroid distances');

        ClusterEvalObj = evalclusters(ObjectData,clust,Criterion);
        nClusters = ClusterEvalObj.OptimalK;
        disp(['Optimal number of clusters: ',num2str(nClusters)]);
end

    % use 'replicates' name-value pair to repeat the clustering algorithm
    %   for different randomly selected centroids for each replicate 
    [cidx3,cmeans3,sumd3] = kmeans(ObjectData,nClusters,'replicates',nReplicates,'display','final');
    ClusterIdxs = cidx3;
    % 3rd output, sumd3, contains sum of distance within each cluster for the best solution

    figure('Name',['Silhouette (Euclidean Distance,',num2str(nReplicates),' replicates)'])
    
    % again use silhouette plot to visualize cluster separation
    [silh3,h] = silhouette(ObjectData,cidx3,'sqeuclidean');
    % not quite as well separated as when we used 2 clusters
    
%     figure('Name',['3D Scatter (Euclidean Distance, ',num2str(nReplicates),' replicates)'])
%     % can plot the raw data again to see how kmeans assigned points to clusters
%     %   -> upper cluster split into 2 smaller clusters
%     for i = 1:nClusters
%         clust = find(cidx3==i);
%         plot3(ObjectData(clust,VariablesToPlot(1)),...
%             ObjectData(clust,VariablesToPlot(2)),...
%             ObjectData(clust,VariablesToPlot(3)),...
%             'o');
%         hold on
%     end
%     
%     % cluster centroids are plotted with circled x's
%     plot3(cmeans3(:,VariablesToPlot(1)),cmeans3(:,VariablesToPlot(2)),cmeans3(:,VariablesToPlot(3)),'ko');
%     plot3(cmeans3(:,VariablesToPlot(1)),cmeans3(:,VariablesToPlot(2)),cmeans3(:,VariablesToPlot(3)),'kx');
%     hold off
%     
%     % add axes labels
%     xlabel(Var1Name);
%     ylabel(Var2Name);
%     zlabel(Var3Name);
%     
%     % set viewing angle
%     view(-137,10);
%     grid on

    % display average silhouette width
    disp(['Mean Silhouette Width (Euclidean Distance, ',num2str(nReplicates),' replicates): ',num2str(mean(silh3))])

%% Euclidean distance k-means clustering (user-defined nclusters, with more replicates) BEST SO FAR
    
%     % use 'replicates' name-value pair to repeat the clustering algorithm
%     %   for different randomly selected centroids for each replicate 
%     [cidx3,cmeans3,sumd3] = kmeans(ObjectData,nClusters,'replicates',nReplicates,'display','final');
%     ClusterIdxs = cidx3;
%     % 3rd output, sumd3, contains sum of distance within each cluster for the best solution
% 
%     figure('Name',['Silhouette (Euclidean Distance,',num2str(nReplicates),' replicates)'])
%     
%     % again use silhouette plot to visualize cluster separation
%     [silh3,h] = silhouette(ObjectData,cidx3,'sqeuclidean');
%     % not quite as well separated as when we used 2 clusters
%     
%     figure('Name',['3D Scatter (Euclidean Distance, ',num2str(nReplicates),' replicates)'])
%     % can plot the raw data again to see how kmeans assigned points to clusters
%     %   -> upper cluster split into 2 smaller clusters
%     for i = 1:nClusters
%         clust = find(cidx3==i);
%         plot3(ObjectData(clust,VariablesToPlot(1)),...
%             ObjectData(clust,VariablesToPlot(2)),...
%             ObjectData(clust,VariablesToPlot(3)),...
%             ptsymb{i});
%         hold on
%     end
%     
%     % cluster centroids are plotted with circled x's
%     plot3(cmeans3(:,VariablesToPlot(1)),cmeans3(:,VariablesToPlot(2)),cmeans3(:,VariablesToPlot(3)),'ko');
%     plot3(cmeans3(:,VariablesToPlot(1)),cmeans3(:,VariablesToPlot(2)),cmeans3(:,VariablesToPlot(3)),'kx');
%     hold off
%     
%     % add axes labels
%     xlabel(Var1Name);
%     ylabel(Var2Name);
%     zlabel(Var3Name);
%     
%     % set viewing angle
%     view(-137,10);
%     grid on
% 
%     % display average silhouette width
%     disp(['Mean Silhouette Width (Euclidean Distance, ',num2str(nReplicates),' replicates): ',num2str(mean(silh3))])
    %[mean(silh2) mean(silh3)]

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