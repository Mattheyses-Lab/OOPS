function [Vertices,Faces,FaceVertexCData] = getColorbarPatchData(cmap,origin,cbarWidth,cbarLength)

    %% horizontal orientation running from left to right

    % coordinates of each vertex along the bottom of colorbar
    bottomX = (linspace(0,cbarLength,256) + origin(1)).';
    bottomY = zeros(size(bottomX)) + origin(2);

    % coordinates of each vertex along the top of colorbar
    topX = bottomX;
    topY = bottomY + cbarWidth;
    
    % 256 total vertices, one per color in the colormap
    Vertices = [bottomX,bottomY;topX,topY];

    % 255 total faces, each made of 4 vertices (vectorized to avoid loop)
    Faces = repmat([0,1,257,256],255,1) + (1:255).';

    % RGB triplets for each vertex, such that the color of the vertex at Vertices(n,:) is FaceVertexCData(n,:)
    FaceVertexCData = repmat(cmap,2,1);

end