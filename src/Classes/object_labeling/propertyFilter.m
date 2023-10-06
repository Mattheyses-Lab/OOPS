classdef propertyFilter < handle
% handle class used by OOPS to filter and sort object based on their properties

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