classdef propertyFilterSet < handle
% handle class used by OOPS to filter and sort object based on their properties
% see propertyFilter.m for more details
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

        % the property filters in this filter set
        propertyFilters propertyFilter
        
    end
    
    methods
    
        % constructor
        function obj = propertyFilterSet(varargin)

            if isempty(varargin)
                return
            elseif isa(varargin{1},'propertyFilter')
                obj.propertyFilters = varargin{1};
            else
                error('First variable input must be an nx1 array of propertyFilter objects');
            end
        end
    
        % checks if objectToCheck has a property matching the filter
        % and returns a logical vetor the same size as the input
        function TF = checkMatch(obj,objectToCheck)
            % initialize an all true logical array same size as objectToCheck
            TF = true(size(objectToCheck));
            % check objects for a match with each property filter
            for filterIdx = 1:numel(obj.propertyFilters)
                TF = TF & obj.propertyFilters(filterIdx).checkMatch(objectToCheck);
            end
        end
    
        % checks if objectToCheck has a property matching the filter
        % and returns a vector of idxs matching the filter
        function Idx = checkMatchIdx(obj,objectToCheck)
            % idxs of objects to check, start by checking all objects
            checkIdx = 1:numel(objectToCheck);
            % check each filter for matches
            for filterIdx = 1:numel(obj.propertyFilters)
                % idxs of objectToCheck(checkIdx) that evaluate true
                trueIdx = obj.propertyFilters(filterIdx).checkMatch(objectToCheck(checkIdx));
                % if all objects have failed at least one filter check
                if isempty(trueIdx)
                    break % then stop checking the remaining filters
                else
                    % reset the checkIdx to avoid checking objects more than once if they fail a filter
                    checkIdx = checkIdx(trueIdx);
                end
            end
            % set the result
            Idx = checkIdx;
        end
    
        % add a filter to the filter set
        function addFilter(obj,propFullName,propRealName,propRelationship,propValue)
            arguments
                obj (1,1) propertyFilterSet
                % full, display name of the property
                propFullName (1,:) char
                % the actual name of the property in OOPSObject
                propRealName (1,:) char
                % relational operator defining the filter
                propRelationship (1,:) char {mustBeMember(propRelationship,{'>','>=','==','<','<=',''})}
                % value of the property defining the filter
                propValue (1,1) double
            end
            % add the new property filter to the set
            obj.propertyFilters(end+1,1) = propertyFilter(...
                propFullName,...
                propRealName,...
                propRelationship,...
                propValue);
        end
    
    end

end
