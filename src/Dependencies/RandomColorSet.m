function RGBValues = RandomColorSet(n)

    % count main for loop
    count = 1;
    % tracks used indices
    IdxList = [];
    
    mycmap = hsv(16);

    for i = 1:n
        if count == 1
            IdxList(i) = randi(16);
            
        else
            num = randi(16);
            while any(IdxList(:) == num)
                num = randi(16);
            end
            
            IdxList(i) = num;
        end
        
        RGBValues(i,:) = mycmap(IdxList(i),:);

    end

end