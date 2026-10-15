% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef CacheManager < handle
%CACHEMANAGER Own project-wide policy for disposable image buffers.
% Model-owned analysis outputs are deliberately excluded. This manager only
% retains data that can be reconstructed from project sources and recipes.

    properties (SetAccess=private)
        RawInputLimitBytes (1,1) double {mustBeNonnegative} = 0
        CorrectedStackLimitBytes (1,1) double {mustBeNonnegative} = 0
        CalibrationLimitBytes (1,1) double {mustBeNonnegative} = Inf
        AuxiliaryLimitBytes (1,1) double {mustBeNonnegative} = 0
    end

    properties (Access=private)
        RawImageIDs (:,1) string = strings(0,1)
        RawBytes (:,1) double = zeros(0,1)

        CalibrationKeys (:,1) string = strings(0,1)
        CalibrationValues (:,1) cell = cell(0,1)
        CalibrationBytes (:,1) double = zeros(0,1)

        CorrectedKeys (:,1) string = strings(0,1)
        CorrectedImageIDs (:,1) string = strings(0,1)
        CorrectedValues (:,1) cell = cell(0,1)
        CorrectedBytes (:,1) double = zeros(0,1)
    end

    methods

        function obj = CacheManager(opts)
        %CACHEMANAGER Read app-wide byte budgets unless explicitly supplied.

            arguments
                opts.RawInputLimitMiB (1,1) double {mustBeNonnegative} = ...
                    oops.Preferences.get("RawInputCacheLimitMiB",0)
                opts.CorrectedStackLimitMiB (1,1) double {mustBeNonnegative} = ...
                    oops.Preferences.get("CorrectedStackCacheLimitMiB",0)
                opts.CalibrationLimitMiB (1,1) double {mustBeNonnegative} = ...
                    oops.Preferences.get("CalibrationCacheLimitMiB",Inf)
                opts.AuxiliaryLimitMiB (1,1) double {mustBeNonnegative} = ...
                    oops.Preferences.get("AuxiliaryCacheLimitMiB",0)
            end

            bytesPerMiB = 1024^2;
            obj.RawInputLimitBytes = opts.RawInputLimitMiB*bytesPerMiB;
            obj.CorrectedStackLimitBytes = opts.CorrectedStackLimitMiB*bytesPerMiB;
            obj.CalibrationLimitBytes = opts.CalibrationLimitMiB*bytesPerMiB;
            obj.AuxiliaryLimitBytes = opts.AuxiliaryLimitMiB*bytesPerMiB;
        end

        function activateInput(obj,image,images)
        %ACTIVATEINPUT Apply raw-input residency policy after navigation.

            arguments
                obj
                image (:,1) oops.model.Image
                images (:,1) oops.model.Image
            end

            if isempty(image) || obj.RawInputLimitBytes == 0
                oops.Log.DEBUG(sprintf( ...
                    'Raw input cache bypassed: active=%s, budget=%.3f MiB.', ...
                    imageName(image),obj.RawInputLimitBytes/(1024^2)));
                obj.releaseRawInputs(images);
                return;
            end

            % Only file-backed sources are disposable. In-memory sources own
            % their arrays permanently and Image5D intentionally cannot unload them.
            if ~image.Input.IsFileBacked
                oops.Log.DEBUG("Raw input cache ignored memory-backed image: " + image.Name + ".");
                obj.enforceRawLimit(images);
                return;
            end

            bytes = obj.imageBytes(image.Input);

            if bytes > obj.RawInputLimitBytes
                oops.Log.DEBUG(sprintf( ...
                    'Raw input exceeds cache budget: %s is %.3f MiB; limit is %.3f MiB.', ...
                    image.Name,bytes/(1024^2),obj.RawInputLimitBytes/(1024^2)));
                image.unloadInput();
                obj.removeRawRecord(image.ID);
                obj.enforceRawLimit(images);
                return;
            end

            image.loadInput();
            obj.removeRawRecord(image.ID);
            obj.RawImageIDs = [image.ID;obj.RawImageIDs];
            obj.RawBytes = [bytes;obj.RawBytes];
            oops.Log.DEBUG(sprintf('Cached raw input: %s (%.3f MiB).', ...
                image.Name,bytes/(1024^2)));
            obj.enforceRawLimit(images);
        end

        function [value,found] = getCalibration(obj,ids)
        %GETCALIBRATION Return a normalized response and update its LRU position.

            key = obj.calibrationKey(ids);
            index = find(obj.CalibrationKeys == key,1);
            found = ~isempty(index);

            if ~found
                oops.Log.DEBUG("Normalized calibration cache miss: " + key + ".");
                value = [];
                return;
            end

            oops.Log.DEBUG(sprintf( ...
                'Normalized calibration cache hit: %s (%.3f MiB).', ...
                key,obj.CalibrationBytes(index)/(1024^2)));
            value = obj.CalibrationValues{index};
            obj.CalibrationKeys = obj.moveFirst(obj.CalibrationKeys,index);
            obj.CalibrationValues = obj.moveFirst(obj.CalibrationValues,index);
            obj.CalibrationBytes = obj.moveFirst(obj.CalibrationBytes,index);
        end

        function putCalibration(obj,ids,value)
        %PUTCALIBRATION Retain one shared response within the calibration budget.

            key = obj.calibrationKey(ids);
            bytes = obj.valueBytes(value);
            existing = obj.CalibrationKeys == key;
            obj.CalibrationKeys(existing) = [];
            obj.CalibrationValues(existing) = [];
            obj.CalibrationBytes(existing) = [];

            if obj.CalibrationLimitBytes == 0 || bytes > obj.CalibrationLimitBytes
                oops.Log.DEBUG(sprintf( ...
                    'Normalized calibration not cached: %.3f MiB value, %.3f MiB limit.', ...
                    bytes/(1024^2),obj.CalibrationLimitBytes/(1024^2)));
                return;
            end

            obj.CalibrationKeys = [key;obj.CalibrationKeys];
            obj.CalibrationValues = [{value};obj.CalibrationValues];
            obj.CalibrationBytes = [bytes;obj.CalibrationBytes];
            keep = obj.lruKeep(obj.CalibrationBytes,obj.CalibrationLimitBytes);

            for evicted = reshape(setdiff(1:numel(obj.CalibrationKeys),keep,'stable'),1,[])
                oops.Log.DEBUG(sprintf( ...
                    'Evicting normalized calibration: %s (%.3f MiB).', ...
                    obj.CalibrationKeys(evicted), ...
                    obj.CalibrationBytes(evicted)/(1024^2)));
            end

            obj.CalibrationKeys = obj.CalibrationKeys(keep);
            obj.CalibrationValues = obj.CalibrationValues(keep);
            obj.CalibrationBytes = obj.CalibrationBytes(keep);
            oops.Log.DEBUG(sprintf( ...
                'Cached normalized calibration: %s (%.3f MiB; total %.3f MiB).', ...
                key,bytes/(1024^2),sum(obj.CalibrationBytes)/(1024^2)));
        end

        function [value,found] = getCorrected(obj,imageID,calibrationIDs)
        %GETCORRECTED Return one corrected stack and update its LRU position.

            key = obj.correctedKey(imageID,calibrationIDs);
            index = find(obj.CorrectedKeys == key,1);
            found = ~isempty(index);

            if ~found
                oops.Log.DEBUG("Corrected-stack cache miss: image " + string(imageID) + ".");
                value = [];
                return;
            end

            oops.Log.DEBUG(sprintf('Corrected-stack cache hit: image %s (%.3f MiB).', ...
                string(imageID),obj.CorrectedBytes(index)/(1024^2)));
            value = obj.CorrectedValues{index};
            obj.CorrectedKeys = obj.moveFirst(obj.CorrectedKeys,index);
            obj.CorrectedImageIDs = obj.moveFirst(obj.CorrectedImageIDs,index);
            obj.CorrectedValues = obj.moveFirst(obj.CorrectedValues,index);
            obj.CorrectedBytes = obj.moveFirst(obj.CorrectedBytes,index);
        end

        function putCorrected(obj,imageID,calibrationIDs,value)
        %PUTCORRECTED Retain one corrected stack when its byte budget permits.

            key = obj.correctedKey(imageID,calibrationIDs);
            bytes = obj.valueBytes(value);
            existing = obj.CorrectedKeys == key;
            obj.CorrectedKeys(existing) = [];
            obj.CorrectedImageIDs(existing) = [];
            obj.CorrectedValues(existing) = [];
            obj.CorrectedBytes(existing) = [];

            if obj.CorrectedStackLimitBytes == 0 || bytes > obj.CorrectedStackLimitBytes
                oops.Log.DEBUG(sprintf( ...
                    'Corrected stack not cached: image %s, %.3f MiB value, %.3f MiB limit.', ...
                    string(imageID),bytes/(1024^2), ...
                    obj.CorrectedStackLimitBytes/(1024^2)));
                return;
            end

            obj.CorrectedKeys = [key;obj.CorrectedKeys];
            obj.CorrectedImageIDs = [string(imageID);obj.CorrectedImageIDs];
            obj.CorrectedValues = [{value};obj.CorrectedValues];
            obj.CorrectedBytes = [bytes;obj.CorrectedBytes];
            keep = obj.lruKeep(obj.CorrectedBytes,obj.CorrectedStackLimitBytes);

            for evicted = reshape(setdiff(1:numel(obj.CorrectedKeys),keep,'stable'),1,[])
                oops.Log.DEBUG(sprintf( ...
                    'Evicting corrected stack: image %s (%.3f MiB).', ...
                    obj.CorrectedImageIDs(evicted), ...
                    obj.CorrectedBytes(evicted)/(1024^2)));
            end

            obj.CorrectedKeys = obj.CorrectedKeys(keep);
            obj.CorrectedImageIDs = obj.CorrectedImageIDs(keep);
            obj.CorrectedValues = obj.CorrectedValues(keep);
            obj.CorrectedBytes = obj.CorrectedBytes(keep);
            oops.Log.DEBUG(sprintf( ...
                'Cached corrected stack: image %s (%.3f MiB; total %.3f MiB).', ...
                string(imageID),bytes/(1024^2),sum(obj.CorrectedBytes)/(1024^2)));
        end

        function removeImage(obj,imageID)
        %REMOVEIMAGE Release disposable entries belonging to one model image.

            obj.removeRawRecord(imageID);
            remove = obj.CorrectedImageIDs == string(imageID);
            obj.CorrectedKeys(remove) = [];
            obj.CorrectedImageIDs(remove) = [];
            obj.CorrectedValues(remove) = [];
            obj.CorrectedBytes(remove) = [];
        end

        function tf = hasCorrected(obj,imageID)
        %HASCORRECTED Report whether any corrected entry belongs to an image.

            tf = any(obj.CorrectedImageIDs == string(imageID));
        end

        function bytes = correctedBytes(obj,imageID)
        %CORRECTEDBYTES Return resident corrected bytes belonging to an image.

            bytes = sum(obj.CorrectedBytes(obj.CorrectedImageIDs == string(imageID)));
        end

        function T = calibrationStatus(obj)
        %CALIBRATIONSTATUS Describe shared normalized responses in LRU order.

            Key = obj.CalibrationKeys;
            MiB = obj.CalibrationBytes/(1024^2);
            T = table(Key,MiB);
        end

        function S = summary(obj)
        %SUMMARY Report budgets and current disposable-cache occupancy.

            S = struct( ...
                'RawInputLimitMiB',obj.RawInputLimitBytes/(1024^2), ...
                'RawInputMiB',sum(obj.RawBytes)/(1024^2), ...
                'CorrectedStackLimitMiB',obj.CorrectedStackLimitBytes/(1024^2), ...
                'CorrectedStackMiB',sum(obj.CorrectedBytes)/(1024^2), ...
                'CalibrationLimitMiB',obj.CalibrationLimitBytes/(1024^2), ...
                'CalibrationMiB',sum(obj.CalibrationBytes)/(1024^2), ...
                'AuxiliaryLimitMiB',obj.AuxiliaryLimitBytes/(1024^2));
        end

        function clear(obj,images)
        %CLEAR Release all disposable entries and manager-owned raw buffers.

            arguments
                obj
                images (:,1) oops.model.Image = oops.model.Image.empty(0,1)
            end

            obj.releaseRawInputs(images);
            obj.CalibrationKeys = strings(0,1);
            obj.CalibrationValues = cell(0,1);
            obj.CalibrationBytes = zeros(0,1);
            obj.CorrectedKeys = strings(0,1);
            obj.CorrectedImageIDs = strings(0,1);
            obj.CorrectedValues = cell(0,1);
            obj.CorrectedBytes = zeros(0,1);
        end

    end

    methods (Access=private)

        function enforceRawLimit(obj,images)
        %ENFORCERAWLIMIT Evict least-recently-used raw buffers over budget.

            while sum(obj.RawBytes) > obj.RawInputLimitBytes && ~isempty(obj.RawImageIDs)
                id = obj.RawImageIDs(end);
                candidate = oops.model.internal.resolve(images,id);

                if ~isempty(candidate)
                    oops.Log.DEBUG("Evicting raw input from cache: " + candidate.Name + ".");
                    candidate.unloadInput();
                end

                obj.RawImageIDs(end) = [];
                obj.RawBytes(end) = [];
            end
        end

        function releaseRawInputs(obj,images)
        %RELEASERAWINPUTS Unload every file-backed buffer tracked by the manager.

            for k = 1:numel(obj.RawImageIDs)
                candidate = oops.model.internal.resolve(images,obj.RawImageIDs(k));

                if ~isempty(candidate)
                    candidate.unloadInput();
                end
            end

            obj.RawImageIDs = strings(0,1);
            obj.RawBytes = zeros(0,1);
        end

        function removeRawRecord(obj,imageID)
        %REMOVERAWRECORD Remove one image from the raw-buffer LRU bookkeeping.

            remove = obj.RawImageIDs == string(imageID);
            obj.RawImageIDs(remove) = [];
            obj.RawBytes(remove) = [];
        end

    end

    methods (Static)

        function bytes = imageBytes(input)
        %IMAGEBYTES Estimate full Image5D residency from component metadata.

            bytes = 0;

            for component = reshape(input.Components,1,[])
                bytes = bytes + prod(double(component.Size))* ...
                    oops.runtime.CacheManager.classBytes(component.Class);
            end
        end

        function bytes = valueBytes(value)
        %VALUEBYTES Return dense numeric/logical array storage without copying it.

            bytes = numel(value)* ...
                oops.runtime.CacheManager.classBytes(class(value));

            if ~isreal(value)
                bytes = 2*bytes;
            end
        end

    end

    methods (Static, Access=private)

        function count = classBytes(className)
        %CLASSBYTES Return bytes per numeric or logical array element.

            switch string(className)
                case {"logical","int8","uint8"}
                    count = 1;
                case {"int16","uint16"}
                    count = 2;
                case {"int32","uint32","single"}
                    count = 4;
                case {"int64","uint64","double"}
                    count = 8;
                otherwise
                    count = 8;
            end
        end

        function keep = lruKeep(bytes,limit)
        %LRUKEEP Select the newest prefix whose cumulative size fits the budget.

            if isinf(limit)
                keep = 1:numel(bytes);
                return;
            end

            keep = find(cumsum(bytes) <= limit);
        end

        function values = moveFirst(values,index)
        %MOVEFIRST Move one aligned LRU entry to the most-recent position.

            values = [values(index);values([1:index-1 index+1:end])];
        end

        function key = calibrationKey(ids)
        %CALIBRATIONKEY Encode an ordered calibration-ID set without ambiguity.

            ids = string(ids(:));
            parts = strings(size(ids));

            for k = 1:numel(ids)
                parts(k) = string(strlength(ids(k))) + ":" + ids(k);
            end

            key = strjoin(parts,"|");
        end

        function key = correctedKey(imageID,calibrationIDs)
        %CORRECTEDKEY Combine image identity with its calibration assignment.

            key = string(imageID) + "@" + ...
                oops.runtime.CacheManager.calibrationKey(calibrationIDs);
        end

    end

end

function name = imageName(image)
%IMAGENAME Format an optional active image for cache diagnostics.

if isempty(image)
    name = "none";
else
    name = image.Name;
end
end
