function OutputArray = Interleave2DArrays(array1,array2,mode)
   
    array1_size = size(array1);
    
    if size(array2) ~= array1_size
        error("Arrays must have the same size");
    end
    
    nRows = array1_size(1);
    nCols = array1_size(2);
    
    switch mode
        case 'row'
            OutputArray = zeros(nRows*2,nCols);
            OutputArray(1:2:end,:) = array1;
            OutputArray(2:2:end,:) = array2;
        case 'column'
            OutputArray = zeros(nRows,nCols*2);
            OutputArray(:,1:2:end) = array1;
            OutputArray(:,2:2:end) = array2;
    end

end