% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef AnalysisCache < handle
%ANALYSISCACHE Retain disposable calibration and corrected-image arrays.
% Calibration entries are shared by every group using the same ordered set
% of project calibration IDs. Corrected stacks use a small least-recently-used
% cache so navigating between images does not make every result permanent.

    properties
        CorrectedCapacity (1,1) double {mustBeInteger,mustBePositive} = 2
    end

    properties (Access=private)
        CalibrationKeys (:,1) string = strings(0,1)
        CalibrationValues (:,1) cell = cell(0,1)
        CorrectedKeys (:,1) string = strings(0,1)
        CorrectedImageIDs (:,1) string = strings(0,1)
        CorrectedValues (:,1) cell = cell(0,1)
    end

    methods

        function [value,found] = getCalibration(obj,ids)
        %GETCALIBRATION Return a normalized response for one calibration-ID set.

            % Stable identity for this exact ordered calibration assignment.
            key = obj.calibrationKey(ids);

            % Matching cache entry, when this response has already been computed.
            index = find(obj.CalibrationKeys == key,1);
            found = ~isempty(index);

            if found
                value = obj.CalibrationValues{index};
            else
                value = [];
            end

        end

        function putCalibration(obj,ids,value)
        %PUTCALIBRATION Store one response shared by matching group assignments.

            % Stable identity for this exact ordered calibration assignment.
            key = obj.calibrationKey(ids);

            % Existing entry to replace, or a new slot appended to the cache.
            index = find(obj.CalibrationKeys == key,1);

            if isempty(index)
                obj.CalibrationKeys(end+1,1) = key;
                obj.CalibrationValues{end+1,1} = value;
            else
                obj.CalibrationValues{index} = value;
            end

        end

        function [value,found] = getCorrected(obj,imageID,calibrationIDs)
        %GETCORRECTED Return one corrected stack and mark it most recently used.

            % Cache identity includes both the raw image and applied calibration set.
            key = obj.correctedKey(imageID,calibrationIDs);

            % Matching corrected stack, when it remains inside the bounded cache.
            index = find(obj.CorrectedKeys == key,1);
            found = ~isempty(index);

            if ~found
                value = [];
                return;
            end

            value = obj.CorrectedValues{index};

            % Move the accessed entry to the front of each aligned cache array.
            obj.CorrectedKeys = [obj.CorrectedKeys(index);obj.CorrectedKeys([1:index-1 index+1:end])];
            obj.CorrectedImageIDs = [obj.CorrectedImageIDs(index);obj.CorrectedImageIDs([1:index-1 index+1:end])];
            obj.CorrectedValues = [obj.CorrectedValues(index);obj.CorrectedValues([1:index-1 index+1:end])];
        end

        function putCorrected(obj,imageID,calibrationIDs,value)
        %PUTCORRECTED Store a corrected stack and enforce the LRU capacity.

            % Cache identity includes both the raw image and applied calibration set.
            key = obj.correctedKey(imageID,calibrationIDs);

            % Remove an older copy before inserting the entry as most recently used.
            existing = obj.CorrectedKeys == key;
            obj.CorrectedKeys(existing) = [];
            obj.CorrectedImageIDs(existing) = [];
            obj.CorrectedValues(existing) = [];

            obj.CorrectedKeys = [key;obj.CorrectedKeys];
            obj.CorrectedImageIDs = [string(imageID);obj.CorrectedImageIDs];
            obj.CorrectedValues = [{value};obj.CorrectedValues];

            % Entries beyond the configured capacity are the least recently used.
            keep = 1:min(obj.CorrectedCapacity,numel(obj.CorrectedKeys));
            obj.CorrectedKeys = obj.CorrectedKeys(keep);
            obj.CorrectedImageIDs = obj.CorrectedImageIDs(keep);
            obj.CorrectedValues = obj.CorrectedValues(keep);
        end

        function removeImage(obj,imageID)
        %REMOVEIMAGE Release every corrected entry belonging to a removed image.

            % Corrected entries associated with the image leaving the project.
            remove = obj.CorrectedImageIDs == string(imageID);
            obj.CorrectedKeys(remove) = [];
            obj.CorrectedImageIDs(remove) = [];
            obj.CorrectedValues(remove) = [];
        end

        function clear(obj)
        %CLEAR Release all cached numerical arrays.

            obj.CalibrationKeys = strings(0,1);
            obj.CalibrationValues = cell(0,1);
            obj.CorrectedKeys = strings(0,1);
            obj.CorrectedImageIDs = strings(0,1);
            obj.CorrectedValues = cell(0,1);
        end

    end

    methods (Static, Access=private)

        function key = calibrationKey(ids)
        %CALIBRATIONKEY Encode an ordered calibration-ID set without ambiguity.

            % Length-prefixed IDs prevent different ID sequences from colliding.
            ids = string(ids(:));
            parts = strings(size(ids));

            % Prefix each ID with its length so delimiters inside IDs remain harmless.
            for k = 1:numel(ids)
                parts(k) = string(strlength(ids(k))) + ":" + ids(k);
            end

            key = strjoin(parts,"|");
        end

        function key = correctedKey(imageID,calibrationIDs)
        %CORRECTEDKEY Combine image identity with its calibration assignment.

            key = string(imageID) + "@" + oops.runtime.AnalysisCache.calibrationKey(calibrationIDs);
        end

    end

end
