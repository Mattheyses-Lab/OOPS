function [L,...
          BoundaryPixels4,...
          bwObjProps,...
          nObjects,...
          varargout] = ObjectDetection3(bw,varargin)
%% 1 INPUT: BINARY MASK bw
    % Outputs: L,BoundaryPixels4,bwObjectProps,nObjects
      
%% 2 OR MORE INPUTS
    % Outputs: L,BoundaryPixels4,bwObjectProps,nObjects,Props1,Props2,etc..

%Create Objects from black and white mask, return Label Matrix and object
%properties struct
    % L = Label matrix where each 4-connected object in binary image is 
    % replaced by a unique number
    L = bwlabel(bw,4);
    
    % 4-connected object boundaries
    BoundaryPixels4 = bwboundaries(bw,4);
    
    % object properties of binary mask
    bwObjProps = regionprops(L,bw,'all');
    
    % number of objects
    nObjects = length(bwObjProps);
    
    % if no additional args, exit
    if nargin == 1
        return
    else
        % if # of remaining input arguments is odd
        if mod(length(varargin),2)
            return
        else
            for i = 1:2:length(varargin)
                
                switch varargin{i}
                    case 'FFCAvg'
                        % Average Intensity Image Properties
                        FFCAvgObjProps = regionprops(L,varargin{i+1},'MaxIntensity','MeanIntensity','MinIntensity');
                        varargout{1} = FFCAvgObjProps;
                end
            end
        end
    end
end