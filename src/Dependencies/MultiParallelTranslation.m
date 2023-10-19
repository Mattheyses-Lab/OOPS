function ParallelLines = MultiParallelTranslation(x1,x2,y1,y2,n)
% Returns an (n+1,1) cell array where each cell is a 2x2 double containing the coordinates
% of either the original line (first cell | (x1,y1),(x2,y2)) or a line parallel to it
% n is the number of lines created from the first line

    ParallelLines{1,1} = [x1,y1;x2,y2];

    for i = 2:n+1

        [x1,x2,y1,y2] = ParallelTranslation(x1,x2,y1,y2,1);

        ParallelLines{i,1} = [x1,y1;x2,y2];

    end

end