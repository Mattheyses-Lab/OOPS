function SubarrayIdxOut = padSubarrayIdx(SubarrayIdxIn,Padding)

    X = SubarrayIdxIn{1,1};
    Y = SubarrayIdxIn{1,2};
    
    % linearly extend X and Y subarrays by 5 elements in both directions
    XMax = X(end)+Padding;
    XMin = X(1)-Padding;
    NewX = XMin:1:XMax;
    
    YMax = Y(end)+Padding;
    YMin = Y(1)-Padding;
    NewY = YMin:1:YMax;

    clear YMax YMin XMax XMin

    % odd # of elements
    if mod(length(NewX),2)
        % make even by adding element
        NewX(end+1) = NewX(end) + 1;
    end

    % odd # of elements
    if mod(length(NewY),2)
        % make even by adding element
        NewY(end+1) = NewY(end) + 1;
    end

    if length(NewX) > length(NewY)
        % extend Y to match length of X
        delta = (length(NewX) - length(NewY)) / 2;
        YMax = min(NewY(end)+delta,1024);
        YMin = max(NewY(1)-delta,1);
        clear NewY
        NewY = YMin:1:YMax;
    elseif length(NewX) < length(NewY)
        % extend X to match length of Y
        delta = (length(NewY) - length(NewX)) / 2;
        XMax = min(NewX(end)+delta,1024);
        XMin = max(NewX(1)-delta,1);
        clear NewX
        NewX = XMin:1:XMax;
    end

    SubarrayIdxOut = {NewX,NewY};

end