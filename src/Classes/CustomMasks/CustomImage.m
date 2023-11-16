classdef CustomImage < handle
%CustomImage - simple handle class for images for use with CustomMask.m
% created so that operation classes can access the image data without redundant memory usage
% may be expanded in the future for other purposes
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------
    
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