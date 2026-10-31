% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [data,info] = source(image,sourceID,settings)
%SOURCE Wrap numerical sources for ImageAxes/exports without changing model data.
% Azimuth remains scalar degrees with a cyclic LUT so inspection reports angles.

arguments
    image (:,1) oops.model.Image
    sourceID (1,1) string
    settings (1,1) oops.config.Settings
end

% Render-source timing includes cache lookup, file reads, conversion, and wrapping.
started = tic;
imageLabel = "none";

if ~isempty(image)
    imageLabel = image.Name;
end

if ~ismember(sourceID,oops.config.View.sources())
    error('oops:render:UnknownSource','Unknown image source: %s',sourceID);
end

label = oops.config.View.sourceLabels(sourceID);
oops.Log.DEBUG("Resolving display source '" + sourceID + "' for image '" + imageLabel + "'.");
traceGuard = onCleanup(@() logSourceTiming(sourceID,imageLabel,started)); %#ok<NASGU>

% Empty display source until the requested image data are available.
data = matlabx.image.Image5D.empty(0,1);

% Source title, availability, colormap, and display-limit metadata for the caller.
info = struct('Title',label,'Available',false,'Reason',"No active image", ...
    'Colormap',gray(256),'CLim',[],'Domain',"", ...
    'ComponentColorMode',"luts",'ComponentCLims',{{}}, ...
    'ComponentColors',{{}},'ComponentColormaps',{{}});
try

    if isempty(image)
        return;
    end

    info.Title = image.Name + " — " + label;

    % Display domain selecting the intensity, order, or azimuth colormap.
    domain = "Intensity";

    switch sourceID
        case "Input"
            data = image.Input;
        case "Calibration"

            % Parent group whose calibration assignment supplies this display source.
            group = image.Parent;

            if isempty(group.CalibrationIDs)
                info.Reason = "No calibration assigned";
                return;
            end

            % Numeric source planes to wrap as Image5D without altering model outputs.
            values = oops.analysis.Analyzer.calibration(group.Parent,group.CalibrationIDs);
            info.Title = group.Name + " — Calibration (normalized mean)";
            data = oops.render.polarizationStack(image,values);
            info.CLim = [0 1];
        case "Corrected"
            % Corrected data are a disposable runtime product, calculated on demand.
            values = oops.analysis.Analyzer.correctedStack(image);

            % Detector-class display copy; the stored analytical result remains double.
            values = oops.render.intensityDisplayValues(image,values);
            data = matlabx.image.Image5D.fromComponents( ...
                arrayfun(@(k) values(:,:,k),1:4,'UniformOutput',false), ...
                Names=["0 deg","45 deg","90 deg","135 deg"]);
        case "AverageIntensity"
            % Reconstruct an omitted durable average once, then reuse it.
            values = oops.analysis.Analyzer.ensureAverageIntensity(image);

            % Quantize only the display copy; the durable analytical average remains double.
            values = oops.render.intensityDisplayValues(image,values);
            data = matlabx.image.Image5D.fromComponents(values,Names="Average intensity");
        case "Channels"
            [data,channelInfo] = channels(image,settings);

            if isempty(data)
                info.Reason = channelInfo.Reason;
                return;
            end

            info.ComponentCLims = channelInfo.ComponentCLims;
            info.ComponentColors = channelInfo.ComponentColors;
            info.ComponentColormaps = channelInfo.ComponentColormaps;
            info.ComponentColorMode = channelInfo.ComponentColorMode;
            info.Title = image.Name + " — Channels";
        case "Mask"

            if isempty(image.Mask)
                info.Reason = "Mask has not been produced";
                return;
            end

            data = matlabx.image.Image5D.fromComponents(image.Mask,Names="Mask");
            info.CLim = [0 1];
            domain = "Mask";
        case {"Order","Azimuth"}
            values = image.(sourceID);

            if isempty(values)
                info.Reason = label + " has not been produced";
                return;
            end

            validateattributes(values,{'numeric'},{'real','2d','size',[image.Input.SizeY image.Input.SizeX]});
            domain = sourceID;

            if sourceID == "Azimuth"
                % Preserve the analytical axial convention for inspection:
                % one-half atan2 spans signed orientations from -90 to 90 degrees.
                values = rad2deg(values);
                info.CLim = [-90 90];
                info.Title = info.Title + " (degrees)";
            else
                info.CLim = oops.render.displayLimits(image,"Order",settings);
            end

            data = matlabx.image.Image5D.fromComponents(values,Names=label);
        case {"IntensityWeightedOrder","IntensityWeightedAzimuth", ...
                "AzimuthOrderIntensityHSV"}

            needsOrder = ismember(sourceID,["IntensityWeightedOrder", ...
                "AzimuthOrderIntensityHSV"]);
            needsAzimuth = ismember(sourceID,["IntensityWeightedAzimuth", ...
                "AzimuthOrderIntensityHSV"]);

            if needsOrder && isempty(image.Order)
                info.Reason = "Order has not been produced";
                return;
            end

            if needsAzimuth && isempty(image.Azimuth)
                info.Reason = "Azimuth has not been produced";
                return;
            end

            values = oops.render.derivedVisualization(image,sourceID,settings);
            data = matlabx.image.Image5D.fromComponents( ...
                values,Names=label,Kinds="rgb");
            domain = "Derived";
        otherwise
            error('oops:render:UnknownSource','Unknown image source: %s',sourceID);
    end

    if ismember(sourceID,["Input","Corrected","AverageIntensity"])
        info.CLim = oops.render.displayLimits(image,"Intensity",settings);

        % Limit integer display copies to their representable detector range.
        % The percentile-derived limits otherwise remain unchanged.
        if ismember(sourceID,["Corrected","AverageIntensity"])
            [detectorLimits,~] = oops.analysis.detectorRange(image.Input);

            if ~isempty(detectorLimits)
                info.CLim = [max(info.CLim(1),detectorLimits(1)) ...
                    min(info.CLim(2),detectorLimits(2))];

                if info.CLim(1) >= info.CLim(2)
                    info.CLim = detectorLimits;
                end
            end
        end

        info.Domain = "Intensity";

        % One metadata color describes the single semantic polarization
        % channel across its raw, corrected, and averaged representations.
        color = primaryComponentColor(image);

        info.ComponentColorMode = settings.Display.IntensityColorMode;
        info.ComponentColors = repmat({char(color)},1,data.NumComponents);

        if ~isempty(image.PrimaryChannel)
            map = matlabx.colors.maps.Registry.map( ...
                image.PrimaryChannel.Colormap,image.PrimaryChannel.ColormapCategory);
            info.ComponentColormaps = repmat({map},1,data.NumComponents);
        end
    elseif sourceID == "Order"
        info.Domain = "Order";
        info.ComponentColorMode = settings.Display.OrderColorMode;
        info.ComponentColors = {char(settings.Colormaps.OrderColor)};
    elseif sourceID == "Azimuth"
        info.Domain = "Azimuth";
        info.ComponentColorMode = settings.Display.AzimuthColorMode;
        info.ComponentColors = {char(settings.Colormaps.AzimuthColor)};
    elseif sourceID == "Mask"
        info.Domain = "Mask";
        info.ComponentColorMode = settings.Display.MaskColorMode;
        info.ComponentColors = {char(settings.Colormaps.MaskColor)};
    elseif ismember(sourceID,["IntensityWeightedOrder","IntensityWeightedAzimuth", ...
            "AzimuthOrderIntensityHSV"])
        info.Domain = "Derived";
    end

    if domain == "Derived"
        info.Colormap = gray(256);
    elseif domain == "Azimuth"
        info.Colormap = oops.render.azimuthImageColormap(settings.Colormaps);
    else
        info.Colormap = oops.render.colormap(settings.Colormaps,domain);
    end
    info.Available = true;
    info.Reason = "";
catch ME
    oops.Log.EXCEPTION(ME);
    rethrow(ME);
end
end

function color = primaryComponentColor(image)
%PRIMARYCOMPONENTCOLOR Resolve the first polarization frame's metadata color.

% Gray is the predictable display color when acquisition metadata does not
% provide a canonical color for the primary polarization channel.
color = "gray";

if ~isempty(image.PrimaryChannel)
    registeredColor = oops.render.canonicalComponentColor(image.PrimaryChannel.Color);

    if registeredColor ~= ""
        color = registeredColor;
        return;
    end
end

componentIndex = image.FrameLocations(1,1);

if componentIndex > numel(image.Input.Components)
    return;
end

metadataColor = oops.render.canonicalComponentColor( ...
    image.Input.Components(componentIndex).Color);

if metadataColor ~= ""
    color = metadataColor;
end
end

function logSourceTiming(name,imageName,started)
%LOGSOURCETIMING Report total display-source construction time on every exit.

oops.Log.DEBUG(sprintf( ...
    'Resolved display source %s for %s in %.3f s.', ...
    name,imageName,toc(started)));
end

function [data,info] = channels(image,settings)
%CHANNELS Build primary-first channel data with registry-ordered auxiliaries.

    data = matlabx.image.Image5D.empty(0,1);
    info = struct('Reason',"Channel data are unavailable", ...
        'ComponentColorMode',"colors",'ComponentCLims',{{}}, ...
        'ComponentColors',{{}},'ComponentColormaps',{{}});

    definitions = image.Parent.Parent.Channels.Channels;
    definitions = definitions([definitions.IsAuxiliary]);

    % Component one is always the corrected average of the polarization
    % channel. Registry order defines the remaining stable component positions.
    count = numel(definitions)+1;
    planes = cell(1,count);
    names = strings(1,count);
    limits = cell(1,count);
    colors = cell(1,count);
    metadataColors = cell(1,count);
    colormaps = repmat({gray(256)},1,count);
    available = false(1,count);
    sourceClasses = strings(1,count);

    primary = oops.analysis.Analyzer.ensureAverageIntensity(image);
    primary = oops.render.intensityDisplayValues(image,primary);
    planes{1} = primary;
    available(1) = true;
    sourceClasses(1) = string(class(primary));
    names(1) = "Primary intensity";
    limits{1} = oops.render.displayLimits(image,"Intensity",settings);
    primaryColor = primaryComponentColor(image);
    colors{1} = char(primaryColor);
    metadataColors{1} = colorValue(primaryColor);
    intensityMode = settings.Display.IntensityColorMode;

    if ~isempty(image.PrimaryChannel)
        names(1) = image.PrimaryChannel.Name;
        metadataColors{1} = image.PrimaryChannel.Color;
        primaryMap = matlabx.colors.maps.Registry.map( ...
            image.PrimaryChannel.Colormap,image.PrimaryChannel.ColormapCategory);
    else
        primaryMap = gray(256);
    end

    if intensityMode == "colors"
        primaryMap = colorRamp(metadataColors{1});
    end
    colormaps{1} = primaryMap;

    % Read assigned planes in their native classes. The common display class
    % cannot be selected until every available source has been inspected.
    for k = 1:numel(definitions)
        definition = definitions(k);
        assignment = image.getAuxiliaryChannel(definition.ID);
        index = k+1;
        names(index) = definition.Name;
        metadataColors{index} = definition.Color;
        color = oops.render.canonicalComponentColor(definition.Color);

        colors{index} = char(color);
        colormaps{index} = matlabx.colors.maps.Registry.map( ...
            definition.Colormap,definition.ColormapCategory);
        if settings.Display.IntensityColorMode == "colors"
            colormaps{index} = colorRamp(definition.Color);
        end

        if isempty(assignment)
            continue;
        end

        % Preserve native detector values until the stack class is resolved.
        values = assignment.getPlane();
        planes{index} = values;
        available(index) = true;
        sourceClasses(index) = string(class(values));

        limits{index} = oops.render.auxiliaryDisplayLimits( ...
            assignment,image.Parent.Parent.Settings,values);
    end

    % Preserve the source class when every assigned channel agrees. Mixed
    % source classes use single precision so Image5D receives homogeneous
    % planes without promoting integer detector data to double precision.
    availableClasses = unique(sourceClasses(available));

    if isscalar(availableClasses)
        displayClass = availableClasses;
    else
        displayClass = "single";
    end

    % Fill absent semantic channels using the selected display class, and
    % convert available planes only when heterogeneous sources require it.
    for k = 1:count

        if available(k)

            if sourceClasses(k) ~= displayClass
                planes{k} = cast(planes{k},displayClass);
            end

        else
            planes{k} = zeros(image.Input.SizeY,image.Input.SizeX,displayClass);
            limits{k} = [0 1];
        end

    end

    data = matlabx.image.Image5D.fromComponents(planes,Names=names);

    % ImageAxes initializes exact composite colors from component metadata.
    for k = 1:count
        data.Components(k).Color = metadataColors{k};
    end

    info.Reason = "";
    info.ComponentColorMode = intensityMode;
    info.ComponentCLims = limits;
    info.ComponentColors = colors;
    info.ComponentColormaps = colormaps;
end

function value = colorValue(color)
%COLORVALUE Normalize a canonical name or triplet to RGB metadata.
[~,value] = matlabx.image.normalizeComponentColor(color);
end

function map = colorRamp(color)
%COLORRAMP Construct a linear lookup table for colors-mode equivalence.
[~,rgb] = matlabx.image.normalizeComponentColor(color);
map = linspace(0,1,256)'.*rgb;
end
