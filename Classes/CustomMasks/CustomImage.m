classdef CustomImage < handle
    %CustomImage - simple handle class for images for use with CustomMask.m
    % created so that operation classes can access the image data without redundant memory usage
    % may be expanded in the future for other purposes
    
    properties

        % matrix holding the image data
        ImageData

    end

    properties (Dependent = true)

        ImageClass

    end
    
    methods
        
        % constructor method
        function obj = CustomImage(ImageData)
            obj.ImageData = ImageData;
        end

        function delete(obj)
            delete(obj)
        end

        function ImageClass = get.ImageClass(obj)
            ImageClass = class(obj.ImageData);
        end


    end

    





end