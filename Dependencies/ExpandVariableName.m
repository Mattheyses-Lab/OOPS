function NameOut = ExpandVariableName(NameIn)
    switch NameIn
        case 'OFAvg'
            NameOut = 'Order Factor Average';
        case 'SBRatio'
            NameOut = 'Local S/B';
        case 'Area'
            NameOut = 'Area';
        case 'Perimeter'
            NameOut = 'Perimeter';
        case 'Circularity'
            NameOut = 'Circularity';
        case 'SignalAverage'
            NameOut = 'Raw Intensity Average';
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
        case 'AvgReferenceChannelIntensity'
            NameOut = 'Reference Channel Average Intensity';
        case 'IntegratedReferenceChannelIntensity'
            NameOut = 'Reference Channel Integrated Intensity';
        case 'BGAverage'
            NameOut = 'BG Intensity Average';
        case 'AzimuthAverage'
            NameOut = 'Azimuth Average';
        case 'AzimuthStd'
            NameOut = 'Azimuth Circular Standard Deviation';
        case 'Orientation'
            NameOut = 'Orientation';
        case 'EquivDiameter'
            NameOut = 'Equivalent Diameter';
        case 'ConvexArea'
            NameOut = 'Convex Area';
        case 'MidlineRelativeAzimuth'
            NameOut = 'Azimuth Relative to Midline';
        case 'NormalRelativeAzimuth'
            NameOut = 'Azimuth Relative to Midline Normal';
        case 'MidlineLength'
            NameOut = 'Midline Length';
        case 'AzimuthAngularDeviation'
            NameOut = 'Azimuth Angular Deviation';
        otherwise
            NameOut = NameIn;
    end
end