function matrix_out = makeSpacedCheckerboard(sz,Spacing)
% makes evenly spaced 'checkerboard' style matrix
% 'Spacing' must be an even, positive integer
    nrows = sz(1);
    ncols = sz(2);
    
    counter = 1;

    matrix_out = zeros(nrows,ncols);
    
    for i = 1:(Spacing/2):nrows % for each row
    
        switch iseven(counter)
    
            case true

                for j = (Spacing/2+1):Spacing:ncols
    
                    matrix_out(i,j) = 1;
    
                end

                counter = 1;

            case false

                for j = 1:Spacing:ncols
    
                    matrix_out(i,j) = 1;
    
                end

                counter = 2;
    
        end
    
    end

end