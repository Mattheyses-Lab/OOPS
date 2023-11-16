classdef propertyFilter < handle
% handle class used by OOPS to filter and sort object based on their properties
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
        % full, display name of the property
        propFullName (1,:) char
        % the actual name of the property in OOPSObject
        propRealName (1,:) char
        % relational operator defining the filter
        propRelationship (1,:) char {mustBeMember(propRelationship,{'>','>=','==','<','<=',''})}
        % value of the property defining the filter
        propValue (1,1) double
    end

    methods

        % constructor
        function obj = propertyFilter(propFullName,propRealName,propRelationship,propValue)
            obj.propFullName = propFullName;
            obj.propRealName = propRealName;
            obj.propRelationship = propRelationship;
            obj.propValue = propValue;
        end

        % checks if objectToCheck has a property matching the filter
        % and returns a logical vector the same size as the input
        function TF = checkMatch(obj,objectToCheck)
            switch obj.propRelationship
                case '>'
                    TF = [objectToCheck.(obj.propRealName)]' > obj.propValue;
                case '>='
                    TF = [objectToCheck.(obj.propRealName)]' >= obj.propValue;
                case '=='
                    TF = [objectToCheck.(obj.propRealName)]' == obj.propValue;
                case '<'
                    TF = [objectToCheck.(obj.propRealName)]' < obj.propValue;
                case '<='
                    TF = [objectToCheck.(obj.propRealName)]' <= obj.propValue;
            end
        end

        % checks if objectToCheck has a property matching the filter
        % and returns a vector of idxs matching the filter
        function Idx = checkMatchIdx(obj,objectToCheck)
            switch obj.propRelationship
                case '>'
                    Idx = find(objectToCheck.(obj.propRealName) > obj.propValue);
                case '>='
                    Idx = find([objectToCheck.(obj.propRealName)] >= obj.propValue);
                case '=='
                    Idx = find(objectToCheck.(obj.propRealName) == obj.propValue);
                case '<'
                    Idx = find(objectToCheck.(obj.propRealName) < obj.propValue);
                case '<='
                    Idx = find(objectToCheck.(obj.propRealName) <= obj.propValue);
            end
        end

    end

end