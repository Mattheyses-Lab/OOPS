% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function Output = structureTensorMap(I,Options)

arguments
    % image to process
    I (:,:) double = im2double(imread("coins.png"));
    % gradient method
    Options.method (1,:) char {mustBeMember(Options.method,{'sobel','prewitt','central','intermediate'})} = 'sobel'
    % number of lines in the quiver plot
    Options.nLines (1,:) char {mustBeMember(Options.nLines,{'all','half','quarter'})} = 'all'
    % whether to display output plots
    Options.ShowPlots (1,1) logical = false
end

    %% use imgradient to get Gmag and Gdir

    % get the rows and columns of the input
    [rows,cols] = size(I);

    % Calculate gradients (Gx and Gy) with the chosen method
    [Gx, Gy] = imgradientxy(I, Options.method);

    % get gradient magnitude and direction
    %[Gmag,Gdir] = imgradient(Gx,Gy);

    %% compute the structure tensor map

    % compute components of the structure tensor

    % Apply Gaussian filter for smoothing
    Gx2 = imgaussfilt(Gx.^2, 1); 
    Gy2 = imgaussfilt(Gy.^2, 1);
    Gxy = imgaussfilt(Gx.*Gy, 1);

    % no smoothing
    % Gx2 = Gx.^2; 
    % Gy2 = Gy.^2;
    % Gxy = Gx.*Gy;
    
    % preallocate the structure tensor map
    structureTensorMap_ = zeros(rows, cols, 2, 2);

    % add the tensor to each 'pixel' in the map
    for r = 1:rows
        for c = 1:cols
            structureTensorMap_(r, c, :, :) = [Gx2(r, c), Gxy(r, c); Gxy(r, c), Gy2(r, c)];
        end
    end

    %% compute the gradient orientation map (ambiguous directions)

    % preallocate the orientation map
    gradientOrientationMap = zeros(rows, cols);

    for i = 1:rows
        for j = 1:cols
            % Extract the structure tensor for this pixel (remove singleton dimensions)
            tensor = squeeze(structureTensorMap_(i, j, :, :));
            % Compute eigenvalues and eigenvectors of the structure tensor
            [V, D] = eig(tensor);
            % Find index of the largest eigenvalue
            [~, maxIndex] = max(diag(D));
            % Extract the eigenvector corresponding to the largest eigenvalue
            dominantEigenvector = V(:, maxIndex);
            % Calculate orientation of the gradient in each pixel (angle with the x-axis)
            % negate the result to account for y-axis inversion when MATLAB displays images
            gradientOrientationMap(i, j) = -atan2(dominantEigenvector(2), dominantEigenvector(1));
        end
    end

    %% compute gradient orientation map (true gradient direction, points towards increasing intensity)

    %gradientOrientationMapTrue = -atan2(Gy,Gx);
    gradientOrientationMapTrue = gradientOrientationMap;

    %% compute edge orientation map

    edgeOrientationMap = gradientOrientationMap;

    % add pi/2 because edges are orthogonal to gradients
    edgeOrientationMap = edgeOrientationMap + pi/2;
    % wrap directions to [-pi/2,pi/2] since edges are bidirectional
    edgeOrientationMap(edgeOrientationMap<-pi/2) = edgeOrientationMap(edgeOrientationMap<-pi/2) + pi;
    edgeOrientationMap(edgeOrientationMap>pi/2) = edgeOrientationMap(edgeOrientationMap>pi/2) - pi;

    %% compute the coherence map
    
    coherenceMap = zeros(rows, cols);
    
    for i = 1:rows
        for j = 1:cols
            % Extract the structure tensor for this pixel
            tensor = squeeze(structureTensorMap_(i, j, :, :));
    
            % Compute eigenvalues
            eigenvalues = eig(tensor);
    
            % Sort eigenvalues in descending order
            eigenvalues = sort(eigenvalues, 'descend');
    
            % Calculate coherence
            lambda1 = eigenvalues(1);
            lambda2 = eigenvalues(2);
            if lambda1 + lambda2 == 0
                coherence = 0;
            else
                coherence = ((lambda1 - lambda2)^2) / ((lambda1 + lambda2)^2);
            end
    
            coherenceMap(i, j) = coherence;
        end
    end

    %% compute gradient magnitude map

    gradientMagnitudeMap = sqrt(Gx.^2+Gy.^2);

    %% collect the output
    Output.structureTensorMap = structureTensorMap_;
    Output.gradientOrientationMap = gradientOrientationMap;
    Output.edgeOrientationMap = edgeOrientationMap;
    Output.coherenceMap = coherenceMap;
    Output.gradientMagnitudeMap = gradientMagnitudeMap;
    Output.gradientOrientationMapTrue = gradientOrientationMapTrue;
    Output.gradientX = Gx;
    Output.gradientY = Gy;

    %% display results

    if Options.ShowPlots
        %% plot the original input image
    
        % [~,hAx] = imshow4(I,'Title','Intensity (edge orientation overlay)');

        ax = matlabx.app.quickshow(I);
   
        hAx = ax.getAxes();

        % set the color limits
        ax.CLim = [0,1];
    
        %% plot the orientation lines
    
        LineMask = true(size(I));
    
        % determine number of lines to plot
        switch Options.nLines
            case 'all'
                LineScaleDown = 1;
            case 'half'
                LineScaleDown = 2;
            case 'quarter'
                LineScaleDown = 4;
        end
        
        if LineScaleDown > 1
            ScaleDownMask = matlabx.image.mask.checkerboard(size(LineMask),LineScaleDown);
            LineMask = LineMask & logical(ScaleDownMask);
        end
    
        % positional coordinates
        [y,x] = find(LineMask==1);
    
        % edge direction data
        theta = edgeOrientationMap(LineMask);
    
        % magnitude data
        %rho = gradientMagnitudeMap(LineMask);
    
        rho = ones(size(theta));
        ColorMode = 'Direction';
        LineWidth = 1;
        LineAlpha = 0.5;
        LineScale = 1;
        Colormap = repmat(hsv,2,1);
        
        LinePlot = matlabx.plot.patch.quiverx(hAx,...
            x,...
            y,...
            theta,...
            rho,...
            ColorMode,...
            Colormap,...
            LineWidth,...
            LineAlpha,...
            LineScale);
    
        %% plot the circular colorbar
    
        % add a dynamic property to hold the circular colorbar
        addprop(hAx,'CircularColorbar');
    
        padding = 0.025*rows;
        % inner and outer radii
        outerRadius = 0.1*rows;
        innerRadius = outerRadius/(pi/2);
        % center coordinates
        centerX = rows-outerRadius-padding;
        centerY = centerX;
    
        hAx.CircularColorbar = matlabx.plot.ui.circularColorbar(hAx, ...
            'centerX',centerX, ...
            'centerY',centerY, ...
            'Colormap',repmat(hsv,2,1), ...
            'innerRadius',innerRadius, ...
            'outerRadius',outerRadius, ...
            'nRepeats',1, ...
            'Visible','on', ...
            'FontSize',11);
    
        %% plot the coherence map image
        matlabx.app.quickshow(coherenceMap);
    
        %% plot the gradient magnitude map
        matlabx.app.quickshow(rescale(gradientMagnitudeMap));

    end

end