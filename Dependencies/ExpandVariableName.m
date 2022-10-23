function NameOut = ExpandVariableName(NameIn)
    switch NameIn
        case 'OFAvg'
            NameOut = 'Object-Average Order Factor';
        case 'SBRatio'
            NameOut = 'Local Signal to Background Ratio';
        case 'Area'
            NameOut = 'Object Pixel Area';
        case 'Perimeter'
            NameOut = 'Object Perimeter';
        case 'Circularity'
            NameOut = 'Object Circularity';
        case 'SignalAverage'
            NameOut = 'Average Raw Intensity';
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
        case 'AvgColocIntensity'
            NameOut = 'Average Colocalization Channel Intensity';
        case 'ROIPearsons'
            NameOut = 'Single Object (ROI) Pearsons';
        case 'AvgReferenceChannelIntensity'
            NameOut = 'Average Reference Channel Intensity';
        case 'IntegratedReferenceChannelIntensity'
            NameOut = 'Integrated Reference Channel Intensity';
        case 'BGAverage'
            NameOut = 'Average BG Intensity';
        case 'AzimuthAverage'
            NameOut = 'Average Azimuth';
        case 'AzimuthStd'
            NameOut = 'Azimuth Standard Deviation';
    end
end