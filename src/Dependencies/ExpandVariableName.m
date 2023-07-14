function NameOut = ExpandVariableName(NameIn)
    switch NameIn
        case 'OFAvg'
            NameOut = 'Mean OF';
        case 'SBRatio'
            NameOut = 'Local S/B';
        case 'Area'
            NameOut = 'Area';
        case 'Perimeter'
            NameOut = 'Perimeter';
        case 'Circularity'
            NameOut = 'Circularity';
        case 'SignalAverage'
            NameOut = 'Mean Raw Intensity';
        case 'MaxFeretDiameter'
            NameOut = 'Maximum Feret Diameter';
        case 'MinFeretDiameter'
            NameOut = 'Minimum Feret Diameter';
        case 'MajorAxisLength'
            NameOut = 'Major Axis Length';
        case 'MinorAxisLength'
            NameOut = 'Minor Axis Length';
        case 'Eccentricity'
            NameOut = 'Eccentricity';
        case 'BGAverage'
            NameOut = 'Mean BG Intensity';
        case 'AzimuthAverage'
            NameOut = 'Mean Azimuth';
        case 'AzimuthStd'
            NameOut = 'Azimuth Circular Standard Deviation';
        case 'Orientation'
            NameOut = 'Orientation';
        case 'EquivDiameter'
            NameOut = 'Equivalent Diameter';
        case 'ConvexArea'
            NameOut = 'Convex Area';
        case 'MidlineRelativeAzimuth'
            NameOut = 'Mean Azimuth (Midline)';
        case 'NormalRelativeAzimuth'
            NameOut = 'Mean Azimuth (Midline Normal)';
        case 'MidlineLength'
            NameOut = 'Midline Length';
        case 'AzimuthAngularDeviation'
            NameOut = 'Azimuth Angular Deviation';
        otherwise
            NameOut = NameIn;
    end
end