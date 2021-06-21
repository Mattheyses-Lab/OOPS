classdef PODSImage
    % Technical replicate parameters class
    properties
        % output values
        OFImgAvg double
        OFImgMax double
        OFImgMin double
        FiltOFImgAvg double
        
        % image attributes
        pol_shortname char
        Width uint16
        Height uint16
        
        % status parameters
        MaskDone logical
        OFDone logical
        
        % masking parameters
        SE char
        SESize
        SELines
        FilterType char
        ThresholdAdjusted logical
        level double
        
        % objects
        %obj.Object = PODSObject;
        ObjectNames
        CurrentObjectIdx        
        
        % vector of PODSObject class objects
        Object PODSObject
        % number of Objects identified in current replicate
        nObjects 
        
    end
    
    methods
         % assign default values
         function obj = PODSImage
             obj.OFImgAvg = 0;
             obj.OFImgMax = 0;
             obj.OFImgMin = 0;       
             obj.FiltOFImgAvg = 0;
             obj.pol_shortname = '';
             obj.nObjects = 0;
             obj.level = 0;
             obj.Width = 0;
             obj.Height = 0;
             obj.ThresholdAdjusted = logical(0);
             obj.MaskDone = logical(0);
             obj.OFDone = logical(0);
             obj.SE = 'disk';
             obj.SESize = num2str(5);
             obj.SELines = num2str(4);
             obj.FilterType = 'Median';
             %obj.Objects = []; % will hold PODSObject objects
             obj.ObjectNames = {['No Objects Found']};
             obj.CurrentObjectIdx = 0;
         end
        

    end
    
    
    
    
    
    
    
    
    
    
    

end