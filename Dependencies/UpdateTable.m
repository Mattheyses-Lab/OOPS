function DataTableS = UpdateTable(data,DataTableS)
    
    try
        DataTableS.ImageName = data.pol_shortname;
    end
    try
        DataTableS.ImageDimensions = [num2str(data.cols), 'x', num2str(data.rows)];
    end
    try
        DataTableS.MaskThreshold = data.level;
    end
    try
        DataTableS.NObjects = data.N;
    end
    try
        DataTableS.NFilteredObjects = data.N_filtered;
    end
    try
        DataTableS.ImageAverageOrderFactor = data.OF_avg;
    end
    try
        DataTableS.FilteredImageAverageOrderFactor = data.Filtered_OF_avg;
    end    
    try
        DataTableS.MaxOrderFactor = data.OF_max;
    end
    try
        DataTableS.MinOrderFactor = data.OF_min;
    end
    try
        DataTableS.AverageAnisotropy = data.Anisotropy_avg;
    end
    try
        DataTableS.ObjectAverageSB = data.ObjectAverageOF;
    end
    
    return
end