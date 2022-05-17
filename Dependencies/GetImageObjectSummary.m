function TableOut = GetImageObjectSummary(cImage)


PODSDataOut = struct('ImageName',[],...
    'ObjectIdx',0,...
    'ObjectAvgOF',0,...
    'SBRatio',0,...
    'Area',0,...
    'Perimeter',0,...
    'SignalAvg',0,...
    'BGAvg',0,...
    'SubarrayIdx',{},...
    'PixelIdxList',[],...
    'Circularity',0,...
    'Centroid',[],...
    'BoundingBox',[]);

for k = 1:cImage.nObjects
    
    PODSDataOut(k).ImageName = cImage.pol_shortname;
    PODSDataOut(k).ObjectIdx = k;
    PODSDataOut(k).Area =  cImage.Object(k).Area;
    PODSDataOut(k).Perimeter =  cImage.Object(k).Perimeter;
    PODSDataOut(k).ObjectAvgOF =  cImage.Object(k).OFAvg;    
    PODSDataOut(k).SignalAvg =  cImage.Object(k).SignalAverage;
    PODSDataOut(k).BGAvg =  cImage.Object(k).BGAverage;
    PODSDataOut(k).SBRatio = cImage.Object(k).SBRatio;
    PODSDataOut(k).SubarrayIdx = cImage.Object(k).SubarrayIdx;
    PODSDataOut(k).PixelIdxList = cImage.Object(k).PixelIdxList;
    PODSDataOut(k).Circularity = cImage.Object(k).Circularity;
    PODSDataOut(k).Centroid = cImage.Object(k).Centroid;
    PODSDataOut(k).BoundingBox = cImage.Object(k).BoundingBox;

end % end objects


TableOut = struct2table(PODSDataOut);
clear PODSDataOut




end