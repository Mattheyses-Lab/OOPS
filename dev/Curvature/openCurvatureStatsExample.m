function openCurvatureStatsExample(I)
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

    % get the size of the image
    Isz = size(I);
    
%% get the object midline coordinates and curvature statistics

    % get the midline of the object
    Midline = getObjectMidline(I);

    % linear arc interpolation so distance between neightboring points is ~0.5 
    Midline = approximateRespaceCurve(Midline,0.5);

    % get the curvature statistics
    [curvatureList,tangentList,tortuosity] = openCurvatureStats(Midline,5);

%% make curvature image

    % preallocate curvature image
    IC = zeros(Isz);
    % linear indices in this object mask
    objIdxs = find(I);
    % convert to row and column coordinates
    [objR,objC] = ind2sub(Isz,objIdxs);
    % get the distance between each object pixel and all midline coordinates | hypot(A,B) = sqrt(A^2+B^2)
    dist = hypot(objC'-Midline(:,1),objR'-Midline(:,2));
    % for each object pixel, get the index to the closest midline coordinate
    [~,minIdxs] = min(dist,[],1);
    % use the closest indices to set the tangent value of each object pixel
    IC(objIdxs) = curvatureList(minIdxs);

%% make tangent image

    % % preallocate curvature image
    % IT = zeros(Isz);
    % 
    % % use the closest indices to set the tangent value of each object pixel
    % IT(objIdxs) = tangentList(minIdxs);

%% show the images

    % % build the figure
    % curvatureImageFig = uifigure("Name",'Curvature image',...
    %     'HandleVisibility','on',...
    %     'Units','pixels',...
    %     'Position',[0 0 500 500],...
    %     'Visible','off',...
    %     'AutoResizeChildren','off');
    % 
    % % build uigridlayout object
    % imageGrid = uigridlayout(curvatureImageFig,[1,1],'Padding',[0 0 0 0]);
    % 
    % % build the axes
    % curvatureAxes = uiaxes(imageGrid,...
    %     'Units','Normalized',...
    %     'InnerPosition',[0 0 1 1],...
    %     'XLim',[0.5 Isz(2)+0.5],...
    %     'YLim',[0.5 Isz(1)+0.5],...
    %     'XTick',[],...
    %     'YTick',[],...
    %     'Visible','off');
    % 
    % curvatureImg = imshow(IC,'Parent',curvatureAxes);
    % 
    % curvatureAxes.PlotBoxAspectRatio = [1 1 1];
    % curvatureAxes.CLim = [0 max(max(curvatureList))];
    % curvatureAxes.Colormap = turbo;
    % colorbar();
    % 
    % % move gui to the center
    % movegui(curvatureImageFig,'center')
    % curvatureImageFig.Visible = 'on';

    IRGB = ind2rgb(im2uint8(I),gray);

    imshow3(IRGB);
    hold on;

    X = Midline(:,1);
    Y = Midline(:,2);
    Z = zeros(size(X));
    C = curvatureList;

    Csurf(X,Y,Z,C);

    set(gca,'CLim',[0 max(curvatureList)]);
    set(gca,'Colormap',turbo)

    colorbar

end