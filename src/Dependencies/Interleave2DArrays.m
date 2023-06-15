function OutputArray = Interleave2DArrays(A,B,mode)
   
    % validate input
    assert(all(size(A)==size(B)),'Interleave2DArrays:incompatibleArraySizes','Array sizes must match');
    assert(numel(size(A))<=2,'Interleave2DArrays:invalidArrayDimensions','Arrays must be 2-dimensional');
    assert(all(size(A)~=0),'Interleave2DArrays:invalidDimensionLengths','Dimension lengths must be nonzero');
    
    % get the number of rows and columns
    [nRows,nCols] = size(A);

    
    if iscell(A)
        OutputArray = cell(nRows*2,nCols);
    else
        OutputArray = zeros(nRows*2,nCols);
    end

    switch mode
        case 'row'
            OutputArray(1:2:end,:) = A;
            OutputArray(2:2:end,:) = B;
        case 'column'
            OutputArray = OutputArray.';
            OutputArray(:,1:2:end) = A;
            OutputArray(:,2:2:end) = B;
    end

end