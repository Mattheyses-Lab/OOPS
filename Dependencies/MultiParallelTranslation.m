function ParallelLines = MultiParallelTranslation(x1,x2,y1,y2,n)
% Returns a nx1 cell array where each cell is a 2x2 double containing the coordinates
% of of a line parallel to the line formed by points (x1,y1),(x2,y2)

    ParallelLines{1,1} = [x1,y1;x2,y2];

    for i = 2:n

        [x1,x2,y1,y2] = ParallelTranslation(x1,x2,y1,y2,1);

        ParallelLines{i,1} = [x1,y1;x2,y2];

    end

end