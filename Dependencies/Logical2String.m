function StringOut = Logical2String(LogicalIn)
    switch LogicalIn
        case true
            StringOut = 'True';
        case false
            StringOut = 'False';
    end
end