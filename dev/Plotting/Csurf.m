function hsurf = Csurf(X,Y,Z,C)
% helper function to plot a surf with CData
% temporary function to help plot a curve (x,y,z) where each point is associated with a value
hsurf = surf([X(:) X(:)], [Y(:) Y(:)], [Z(:) Z(:)], [C C], ...  % Reshape and replicate data
            'FaceColor', 'none', ...    % Don't bother filling faces with color
            'EdgeColor', 'interp', ...  % Use interpolated color for edges
            'LineWidth', 10);
end