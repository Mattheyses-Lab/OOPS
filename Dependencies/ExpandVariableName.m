function NameOut = ExpandVariableName(NameIn)
    switch NameIn
        case 'OFAvg'
            NameOut = 'Average Order Factor';
        case 'SBRatio'
            NameOut = 'Local Signal to Background Ratio';
        case 'Area'
            NameOut = 'Object Pixel Area';
        case 'Perimeter'
            NameOut = 'Object Perimeter';
        case 'Circularity'
            NameOut = 'Object Circularity';
    end
end