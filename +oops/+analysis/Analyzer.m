% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Analyzer
%ANALYZER Programmatic orchestration and stable facade over numerical algorithms.
% Models only validate/store outputs; every processing step is callable without GUI.

    methods (Static)

        function corrected = flatField(stack,calibration)
        %FLATFIELD Delegate the numerical correction algorithm.

            corrected = oops.analysis.flatFieldCorrection(stack,calibration);
        end

        function [order,azimuth] = orderOrientation(stack)
        %ORDERORIENTATION Delegate four-angle FPM analysis.

            [order,azimuth] = oops.analysis.fpm(stack);
        end

        function [mask,lists,diagnostics] = segment(average,settings)
        %SEGMENT Delegate the configured algorithm to the segmentation package.

            [mask,lists,diagnostics] = oops.analysis.segment.mask(average,settings);
        end

        function result = midline(mask)
        %MIDLINE Delegate legacy centerline and tangent analysis.

            result = oops.analysis.midline.analyze(mask);
        end

        function flat = calibration(project,ids,opts)
        %CALIBRATION Average project-owned stacks and normalize their shared response.

            arguments
                project (1,1) oops.model.Project
                ids
                opts.Progress = []
            end

            % Validated IDs of project-owned calibration inputs to combine.
            ids = oops.model.internal.validateIDs(ids,project.Calibrations,'oops:model:UnknownCalibration',false);

            % Normalized response, empty when no calibration inputs were supplied.
            flat = [];

            if isempty(ids)
                return;
            end

            % Previously computed response shared by every matching group assignment.
            [flat,cached] = project.CacheManager.getCalibration(ids);

            if cached
                return;
            end

            oops.Log.INFO(sprintf('Computing flat field from %d calibration stacks.',numel(ids)));

            % Cell array collecting the four-angle numeric calibration stacks.
            stacks = cell(1,numel(ids));

            % Read each shared calibration stack, rejecting mismatched dimensions.
            for k = 1:numel(ids)

                % Registered calibration source resolved from the current ID.
                item = oops.model.internal.resolve(project.Calibrations,ids(k));
                oops.runtime.updateProgress(opts.Progress, ...
                    sprintf('Calibration %d/%d: %s\nReading flat-field input...',k,numel(ids),item.Name),[]);
                stacks{k} = oops.analysis.readStack(item.Input);

                if k > 1 && ~isequal(size(stacks{k}),size(stacks{1}))
                    error('oops:analysis:CalibrationSizeMismatch','Calibration stacks must have identical dimensions.');
                end

            end

            oops.runtime.updateProgress(opts.Progress,"Computing flat field...",[]);
            flat = oops.analysis.normalizeCalibration(stacks);
            project.CacheManager.putCalibration(ids,flat);
            oops.Log.INFO("Flat-field computation complete.");
        end

        function assignCalibrations(project,groups,ids,opts)
        %ASSIGNCALIBRATIONS Assign shared files and correct groups after a complete preflight.
        % Controllers suppress their automatic event response while calling this API.

            arguments
                project (1,1) oops.model.Project
                groups (:,1) oops.model.Group
                ids
                opts.Progress = []
            end
            try
                oops.model.internal.validateIDs(groups,project.Groups,'oops:model:UnknownGroup',false);

                % Shared normalized response computed once for the full group assignment.
                flat = oops.analysis.Analyzer.calibration(project,ids,Progress=opts.Progress);

                % Check all target groups before publishing any new assignment.
                for group = reshape(groups,1,[])

                    % Verify each image can accept the computed calibration response.
                    for image = reshape(group.Images,1,[])
                        oops.analysis.Analyzer.validateCalibrationSize(image,flat);
                    end

                end

                % Assign the shared IDs and correct each target group.
                for k = 1:numel(groups)
                    groups(k).setCalibrations(ids);
                    oops.analysis.Analyzer.correctGroup(groups(k),Progress=opts.Progress,Calibration=flat);
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function correctGroup(group,opts)
        %CORRECTGROUP Recompute each image when a group's calibration assignment changes.

            arguments
                group (1,1) oops.model.Group
                opts.Progress = []
                opts.Calibration = []
            end

            % Supplied normalized response, or one computed from this group's registry IDs.
            flat = opts.Calibration;

            if isempty(flat) && ~isempty(group.CalibrationIDs)
                flat = oops.analysis.Analyzer.calibration(group.Parent,group.CalibrationIDs,Progress=opts.Progress);
            end

            % Correct each owned image while reporting its group/name and batch position.
            for k = 1:numel(group.Images)
                oops.runtime.updateProgress(opts.Progress, ...
                    sprintf('Group: %s\nImage %d/%d: %s\nPerforming flat-field correction...', ...
                        group.Name,k,numel(group.Images),group.Images(k).Name),(k-1)/max(1,numel(group.Images)));
                oops.analysis.Analyzer.correctImage(group.Images(k),Calibration=flat);
            end

            oops.runtime.updateProgress(opts.Progress,"Correction complete",1);
        end

        function correctImage(image,opts)
        %CORRECTIMAGE Cache correction and commit its durable average intensity.

            arguments
                image (1,1) oops.model.Image
                opts.Calibration = []
            end

            oops.Log.INFO("Applying flat-field correction to " + image.Name + ".");

            % Disposable corrected stack retained only when its runtime byte
            % budget permits; the default zero-byte budget discards it.
            corrected = oops.analysis.Analyzer.correctedStack(image,Calibration=opts.Calibration);

            % Only downstream analysis products and provenance remain on the model.
            image.setCorrectionResults(mean(corrected,3),image.Parent.CalibrationIDs);
            oops.Log.INFO("Correction complete for " + image.Name + ".");
        end

        function average = ensureAverageIntensity(image)
        %ENSUREAVERAGEINTENSITY Return or reconstruct the durable average cache.

            if isfield(image.Results,'AverageIntensity') && ...
                    image.CorrectionProvenance.matchesAssignments( ...
                    image.Parent.CalibrationIDs)
                average = image.Results.AverageIntensity;
                return;
            end

            corrected = oops.analysis.Analyzer.correctedStack(image);
            average = mean(corrected,3);
            ids = image.Parent.CalibrationIDs;

            if image.CorrectionProvenance.matchesAssignments(ids)
                image.setAverageIntensity(average);
            else
                image.setCorrectionResults(average,ids);
            end
        end

        function corrected = correctedStack(image,opts)
        %CORRECTEDSTACK Return a cached correction or compute it on demand.

            arguments
                image (1,1) oops.model.Image
                opts.Calibration = []
            end

            % Calibration assignment participating in corrected-cache identity.
            ids = image.Parent.CalibrationIDs;

            % A budgeted LRU entry or active-view pin may satisfy either the
            % calibrated recipe or the empty-calibration raw fallback.
            [corrected,cached] = image.Parent.Parent.CacheManager.getCorrected(image.ID,ids);

            if cached
                return;
            end

            if isempty(ids)
                corrected = oops.analysis.readStack(image.Input);
                image.Parent.Parent.CacheManager.putCorrected(image.ID,ids,corrected);
                return;
            end

            % Supplied shared response, or the response cached by calibration ID set.
            flat = opts.Calibration;

            if isempty(flat)
                flat = oops.analysis.Analyzer.calibration(image.Parent.Parent,ids);
            end

            oops.analysis.Analyzer.validateCalibrationSize(image,flat);

            % Raw detector frames promoted by readStack before numerical correction.
            stack = oops.analysis.readStack(image.Input);
            corrected = oops.analysis.Analyzer.flatField(stack,flat);
            oops.analysis.Analyzer.warnOutsideDetectorRange(image,corrected);
            image.Parent.Parent.CacheManager.putCorrected(image.ID,ids,corrected);
        end

        function segmentImages(images,settings,opts)
        %SEGMENTIMAGES Build masks/objects from corrected inputs, falling back to raw data.

            arguments
                images (:,1) oops.model.Image
                settings (1,1) oops.config.Settings
                opts.Progress = []
            end
            oops.analysis.Analyzer.processImages( ...
                images,settings,"ObjectDetection",Progress=opts.Progress);
        end

        function adjustSegmentation(image,name,value,settings)
        %ADJUSTSEGMENTATION Commit an image-local override or restore automatic values.
        % Common filters come from the stored recipe, not subsequently edited defaults.

            try
                % Pending calibration invalidates enhancement and its recipe.
                % Otherwise adjustment needs only the stored average/enhancement,
                % avoiding disk reads, normalization, opening, median, and Otsu.
                if ~isempty(image.Parent.CalibrationIDs) && ...
                        ~oops.model.internal.hasCurrentCorrection(image)
                    oops.analysis.Analyzer.correctImage(image);
                end

                % Committed image-local parameters to adjust without replacing project defaults.
                recipe = image.SegmentationParameters;

                if isempty(recipe)
                    error('oops:analysis:NoSegmentation','Segment this image before adjusting it.');
                end

                % Saved projects retain the recipe and mask but omit the large,
                % reconstructible enhancement image. Restore it on first use.
                oops.analysis.Analyzer.ensureSegmentationCache(image);

                if string(name) == "Automatic"
                    recipe = recipe.resetToAutomatic();
                else
                    recipe = recipe.withParameter(name,value);
                end

                % Mask and object membership regenerated from cached enhancement.
                [mask,lists,diagnostics] = oops.analysis.segment.adjust( ...
                    image.Results.AverageIntensity,image.Results.Segmentation,recipe);
                summary = struct( ...
                    'CandidateCount',diagnostics.CandidateCount, ...
                    'RetainedCount',diagnostics.RetainedCount);
                provenance = oops.model.MaskProvenance.segmented( ...
                    image.CorrectionProvenance,diagnostics.Parameters,summary);
                image.setMask(mask,lists,provenance);

                % Copy of image outputs updated with the committed segmentation cache.
                results = image.Results;
                results.Segmentation = rmfield(diagnostics,'Parameters');
                image.setResults(results);
                oops.analysis.Analyzer.measureObjects(image,settings);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function ensureSegmentationCache(image)
        %ENSURESEGMENTATIONCACHE Rebuild omitted enhancement data on first use.

            arguments
                image (1,1) oops.model.Image
            end

            recipe = image.SegmentationParameters;

            if isempty(recipe)
                error('oops:analysis:NoSegmentation', ...
                    'Segment this image before adjusting it.');
            end

            hasAverage = isfield(image.Results,'AverageIntensity') && ...
                isequal(size(image.Results.AverageIntensity), ...
                [image.Input.SizeY,image.Input.SizeX]);
            hasEnhancement = isfield(image.Results,'Segmentation') && ...
                isfield(image.Results.Segmentation,'Algorithm') && ...
                string(image.Results.Segmentation.Algorithm) == recipe.Algorithm && ...
                isfield(image.Results.Segmentation,'Enhanced') && ...
                isequal(size(image.Results.Segmentation.Enhanced), ...
                [image.Input.SizeY,image.Input.SizeX]);

            if hasAverage && hasEnhancement
                return;
            end

            % Current corrected stack, or raw input when no calibration is assigned.
            stack = oops.analysis.Analyzer.workingStack(image);
            average = mean(stack,3);

            % Run the stored algorithm only to recover its disposable enhancement.
            % The returned mask and membership are intentionally not committed.
            [~,~,diagnostics] = oops.analysis.Analyzer.segment(average,recipe);
            image.setSegmentationCache(average,rmfield(diagnostics,'Parameters'));
            oops.Log.INFO("Rebuilt segmentation adjustment cache for " + ...
                image.Name + ".");
        end

        function analyzeImages(images,settings,opts)
        %ANALYZEIMAGES Calculate order/azimuth for all pixels and summarize existing objects.

            arguments
                images (:,1) oops.model.Image
                settings (1,1) oops.config.Settings
                opts.Progress = []
            end
            oops.analysis.Analyzer.processImages( ...
                images,settings,"Polarization",Progress=opts.Progress);
        end

        function processImages(images,settings,stages,opts)
        %PROCESSIMAGES Run requested stages while sharing each image's working stack.

            arguments
                images (:,1) oops.model.Image
                settings (1,1) oops.config.Settings
                stages (1,:) string
                opts.Progress = []
                opts.SkipCurrentPolarization (1,1) logical = false
            end

            % Small fixed stage vocabulary keeps dispatch explicit while allowing
            % later processing steps to join this per-image pipeline.
            stages = unique(stages,'stable');
            supported = ["Polarization","ObjectDetection"];

            if any(~ismember(stages,supported))
                error('oops:analysis:UnknownProcessingStage', ...
                    'Unknown processing stage: %s',stages(find(~ismember(stages,supported),1)));
            end

            runPolarization = ismember("Polarization",stages);
            runObjectDetection = ismember("ObjectDetection",stages);

            try

                % Process each image completely before releasing its working stack.
                for k = 1:numel(images)
                    image = images(k);
                    prefix = sprintf('Image %d/%d: %s\n',k,numel(images),image.Name);
                    fraction = (k-1)/max(1,numel(images));
                    oops.runtime.updateProgress(opts.Progress, ...
                        prefix + "Reading analysis input...",fraction);

                    % Corrected four-angle data and its mean are shared by every
                    % requested stage for this image.
                    stack = oops.analysis.Analyzer.workingStack(image);
                    average = mean(stack,3);
                    polarizationChanged = false;

                    if runPolarization
                        polarizationCurrent = ...
                            oops.model.internal.hasCurrentPolarization(image);

                        if opts.SkipCurrentPolarization && polarizationCurrent
                            oops.Log.INFO("Polarization analysis is current for " + ...
                                image.Name + "; keeping existing results.");
                        else
                            oops.runtime.updateProgress(opts.Progress, ...
                                prefix + "Calculating order and orientation...",fraction);
                            oops.Log.INFO("Computing order/orientation for " + image.Name + ".");
                            parameters = oops.analysis.polarization.Parameters();
                            result = oops.analysis.polarization.analyze( ...
                                stack,parameters);
                            image.setPolarizationResults( ...
                                average,result,parameters);
                            polarizationChanged = true;
                        end
                    end

                    if runObjectDetection
                        oops.runtime.updateProgress(opts.Progress, ...
                            prefix + "Segmenting image and detecting objects...",fraction);
                        oops.Log.INFO("Segmenting " + image.Name + " using " + ...
                            settings.Segmentation.Algorithm + ".");
                        [mask,lists,diagnostics] = ...
                            oops.analysis.Analyzer.segment(average,settings.Segmentation);
                        summary = struct( ...
                            'CandidateCount',diagnostics.CandidateCount, ...
                            'RetainedCount',diagnostics.RetainedCount);
                        provenance = oops.model.MaskProvenance.segmented( ...
                            image.CorrectionProvenance,diagnostics.Parameters,summary);
                        image.setMask(mask,lists,provenance);

                        % Preserve any polarization results committed above while
                        % retaining the reconstructible segmentation diagnostics.
                        results = image.Results;
                        results.AverageIntensity = average;
                        results.Segmentation = rmfield(diagnostics,'Parameters');
                        image.setResults(results);
                    end

                    if runObjectDetection || polarizationChanged

                        if ~runObjectDetection && ~isempty(image.Objects) && ...
                                ~image.MaskProvenance.isCurrent(image.CorrectionProvenance)
                            oops.Log.WARN("Objects in " + image.Name + ...
                                " were defined from a different intensity correction; " + ...
                                "preserving membership and updating measurements.");
                        end

                        oops.runtime.updateProgress(opts.Progress, ...
                            prefix + "Measuring objects and local S/B...",fraction);
                        oops.analysis.Analyzer.measureObjects(image,settings);
                    end

                    if polarizationChanged
                        oops.Log.INFO("Order/orientation analysis complete for " + ...
                            image.Name + ".");
                    end
                end

                oops.runtime.updateProgress(opts.Progress,"Processing complete",1);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    methods (Static, Access=private)

        function warnOutsideDetectorRange(image,corrected)
        %WARNOUTSIDEDETECTORRANGE Report finite corrected values beyond input range.

            % Integer detector range inferred from the four raw input planes.
            [limits,className] = oops.analysis.detectorRange(image.Input);

            if isempty(limits)
                return;
            end

            % Pixels whose finite corrected estimates exceed the detector maximum.
            exceeded = isfinite(corrected) & corrected > limits(2);

            if ~any(exceeded,'all')
                return;
            end

            count = nnz(exceeded);
            maximum = max(corrected(exceeded),[],'all');
            oops.Log.WARN(sprintf([ ...
                'Corrected intensity exceeds the %s input range in %s: ' ...
                '%d pixels exceed %.0f; maximum corrected value is %.6g. ' ...
                'Check calibration compatibility, illumination power, exposure, gain, and saturation.'], ...
                className,image.Name,count,limits(2),maximum));
        end

        function validateCalibrationSize(image,flat)
        %VALIDATECALIBRATIONSIZE Reject mismatched geometry before changing any model data.

            if ~isempty(flat) && ~isequal(size(flat),[image.Input.SizeY image.Input.SizeX 4])
                error('oops:analysis:CalibrationSizeMismatch','Calibration does not match image %s.',image.Name);
            end

        end

        function stack = workingStack(image)
        %WORKINGSTACK Use a current correction, or warn and analyze raw planes.

            if isempty(image.Parent.CalibrationIDs)
                oops.Log.WARN("No calibration assigned to " + image.Parent.Name + "; analyzing raw input for " + image.Name + ".");

                % Numeric input used for analysis, selected from raw or current corrected data.
                stack = oops.analysis.readStack(image.Input);

                if ~image.CorrectionProvenance.matchesAssignments(strings(0,1))
                    image.setCorrectionResults(mean(stack,3),strings(0,1));
                end
            else
                % Acquire the corrected stack once. When durable correction
                % metadata is stale, commit its average from this same array
                % instead of invoking a separate correction pass first.
                stack = oops.analysis.Analyzer.correctedStack(image);

                if ~oops.model.internal.hasCurrentCorrection(image)
                    image.setCorrectionResults( ...
                        mean(stack,3),image.Parent.CalibrationIDs);
                end
            end

        end

        function measureObjects(image,settings)
        %MEASUREOBJECTS Commit scalar outputs calculated in the analysis package.

            if isempty(image.Objects)
                return;
            end

            oops.Log.INFO(sprintf('Measuring %d objects in %s.',numel(image.Objects),image.Name));

            % Cell array of immutable pixel membership for the image's current objects.
            lists = arrayfun(@(x) x.PixelIdxList,image.Objects,'UniformOutput',false);

            % Cell array of per-pixel midline tangents aligned with each membership list.
            pixelTangents = cell(1,numel(image.Objects));

            % Trace geometry once for newly constructed objects. Subsequent FPM
            % analysis reuses it because object membership has not changed.
            for k = 1:numel(image.Objects)

                % Current object whose local padded mask feeds the legacy tracer.
                object = image.Objects(k);

                if isempty(object.Midline)

                    % Object-only square crop and its parent-coordinate transform.
                    [localMask,geometry] = object.getMask(Margin=5,Square=true);

                    % Legacy centerline, tangents, and geometry scalar results.
                    midline = oops.analysis.Analyzer.midline(localMask);

                    % Convert local [x y] curve coordinates into parent [x y].
                    parentRC = geometry.toParent(midline.Coordinates(:,[2 1]));
                    coordinates = parentRC(:,[2 1]);

                    % Scalar subset stored through the model's measurement API.
                    scalars = struct( ...
                        'MidlineLength',midline.Length, ...
                        'Tortuosity',midline.Tortuosity, ...
                        'MidlineOrientationMean',midline.OrientationMean);
                    object.setMidlineResult(coordinates,midline.PixelTangents,scalars);
                end

                pixelTangents{k} = object.PixelMidlineTangentList;
            end

            % Computed scalar-measurement structs, one per object.
            values = oops.analysis.objectMeasurements(image.Mask,reshape(lists,1,[]), ...
                image.Results.AverageIntensity,image.Order,image.Azimuth,settings.LocalBackground, ...
                pixelTangents);

            % Store the computed scalar measurement struct on each corresponding object.
            for k = 1:numel(image.Objects)
                image.Objects(k).setMeasurements(values{k});
            end

            oops.Log.INFO("Object measurements complete for " + image.Name + ".");
        end

    end
end
