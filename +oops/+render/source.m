% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [data,info] = source(image,name,settings)
%SOURCE Wrap numerical sources for ImageAxes/exports without changing model data.
% Azimuth remains scalar degrees with a cyclic LUT so inspection reports angles.

arguments
    image (:,1) oops.model.Image
    name (1,1) string
    settings (1,1) oops.config.Settings
end

% Render-source timing includes cache lookup, file reads, conversion, and wrapping.
started = tic;
imageLabel = "none";

if ~isempty(image)
    imageLabel = image.Name;
end

oops.Log.DEBUG("Resolving display source '" + name + "' for image '" + imageLabel + "'.");
traceGuard = onCleanup(@() logSourceTiming(name,imageLabel,started)); %#ok<NASGU>

% Empty display source until the requested image data are available.
data = matlabx.image.Image5D.empty(0,1);

% Source title, availability, colormap, and display-limit metadata for the caller.
info = struct('Title',name,'Available',false,'Reason',"No active image", ...
    'Colormap',gray(256),'CLim',[],'Domain',"", ...
    'ComponentColorMode',"luts",'ComponentCLims',{{}}, ...
    'ComponentColors',{{}},'ComponentColormaps',{{}});
try

    if isempty(image)
        return;
    end

    info.Title = image.Name + " — " + name;

    % Display domain selecting the intensity, order, or azimuth colormap.
    domain = "Intensity";

    switch name
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
        case "Average intensity"
            % Reconstruct an omitted durable average once, then reuse it.
            values = oops.analysis.Analyzer.ensureAverageIntensity(image);

            % Quantize only the display copy; the durable analytical average remains double.
            values = oops.render.intensityDisplayValues(image,values);
            data = matlabx.image.Image5D.fromComponents(values,Names="Average intensity");
        case "Auxiliary channels"
            [data,channelInfo] = auxiliaryChannels(image);

            if isempty(data)
                info.Reason = channelInfo.Reason;
                return;
            end

            info.ComponentCLims = channelInfo.ComponentCLims;
            info.ComponentColors = channelInfo.ComponentColors;
            info.ComponentColormaps = channelInfo.ComponentColormaps;
            info.ComponentColorMode = channelInfo.ComponentColorMode;
            info.Title = image.Name + " — Auxiliary channels";
        case "Mask"

            if isempty(image.Mask)
                info.Reason = "Mask has not been produced";
                return;
            end

            data = matlabx.image.Image5D.fromComponents(image.Mask,Names="Mask");
            info.CLim = [0 1];
            domain = "Mask";
        case {"Order","Azimuth"}
            values = image.(name);

            if isempty(values)
                info.Reason = name + " has not been produced";
                return;
            end

            validateattributes(values,{'numeric'},{'real','2d','size',[image.Input.SizeY image.Input.SizeX]});
            domain = name;

            if name == "Azimuth"
                % Preserve the analytical axial convention for inspection:
                % one-half atan2 spans signed orientations from -90 to 90 degrees.
                values = rad2deg(values);
                info.CLim = [-90 90];
                info.Title = info.Title + " (degrees)";
            else
                info.CLim = oops.render.displayLimits(image,"Order",settings);
            end

            data = matlabx.image.Image5D.fromComponents(values,Names=name);
        otherwise
            error('oops:render:UnknownSource','Unknown image source: %s',name);
    end

    if ismember(name,["Input","Corrected","Average intensity"])
        info.CLim = oops.render.displayLimits(image,"Intensity",settings);

        % Limit integer display copies to their representable detector range.
        % The percentile-derived limits otherwise remain unchanged.
        if ismember(name,["Corrected","Average intensity"])
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

        info.ComponentColorMode = settings.Display.PrimaryIntensityColorMode;
        info.ComponentColors = repmat({char(color)},1,data.NumComponents);

        if ~isempty(image.PrimaryChannel)
            map = matlabx.colors.maps.Registry.map( ...
                image.PrimaryChannel.Colormap,image.PrimaryChannel.ColormapCategory);
            info.ComponentColormaps = repmat({map},1,data.NumComponents);
        end
    elseif name == "Order"
        info.Domain = "Order";
        info.ComponentColorMode = settings.Display.OrderColorMode;
        info.ComponentColors = {char(settings.Colormaps.OrderColor)};
    elseif name == "Azimuth"
        info.Domain = "Azimuth";
        info.ComponentColorMode = settings.Display.AzimuthColorMode;
        info.ComponentColors = {char(settings.Colormaps.AzimuthColor)};
    elseif name == "Mask"
        info.Domain = "Mask";
        info.ComponentColorMode = settings.Display.MaskColorMode;
        info.ComponentColors = {char(settings.Colormaps.MaskColor)};
    end

    if domain == "Azimuth"
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
end

function logSourceTiming(name,imageName,started)
%LOGSOURCETIMING Report total display-source construction time on every exit.

oops.Log.DEBUG(sprintf( ...
    'Resolved display source %s for %s in %.3f s.', ...
    name,imageName,toc(started)));
end

function [data,info] = auxiliaryChannels(image)
%AUXILIARYCHANNELS Build a registry-ordered display stack with missing placeholders.

    data = matlabx.image.Image5D.empty(0,1);
    info = struct('Reason',"No auxiliary channels are registered", ...
        'ComponentColorMode',"colors",'ComponentCLims',{{}}, ...
        'ComponentColors',{{}},'ComponentColormaps',{{}});

    definitions = image.Parent.Parent.Channels.Channels;
    definitions = definitions([definitions.IsAuxiliary]);

    if isempty(definitions)
        return;
    end

    % Registry order defines stable component positions across every image.
    planes = cell(1,numel(definitions));
    names = strings(1,numel(definitions));
    limits = cell(1,numel(definitions));
    colors = cell(1,numel(definitions));
    metadataColors = cell(1,numel(definitions));
    colormaps = repmat({gray(256)},1,numel(definitions));
    available = false(1,numel(definitions));
    sourceClasses = strings(1,numel(definitions));

    % Read assigned planes in their native classes. The common display class
    % cannot be selected until every available source has been inspected.
    for k = 1:numel(definitions)
        definition = definitions(k);
        assignment = image.getAuxiliaryChannel(definition.ID);
        names(k) = definition.Name;
        metadataColors{k} = definition.Color;
        color = oops.render.canonicalComponentColor(definition.Color);

        colors{k} = char(color);
        colormaps{k} = matlabx.colors.maps.Registry.map( ...
            definition.Colormap,definition.ColormapCategory);

        if isempty(assignment)
            continue;
        end

        % Preserve native detector values until the stack class is resolved.
        values = assignment.getPlane();
        planes{k} = values;
        available(k) = true;
        sourceClasses(k) = string(class(values));

        if isempty(assignment.DisplayRange)
            range = double([min(values(:)) max(values(:))]);

            if range(2) <= range(1)
                range(2) = range(1)+max(1,eps(range(1)));
            end

            limits{k} = range;
        else
            limits{k} = assignment.DisplayRange;
        end
    end

    if ~any(available)
        info.Reason = "No auxiliary channels are assigned to this image";
        return;
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
    for k = 1:numel(definitions)

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
    for k = 1:numel(definitions)
        data.Components(k).Color = metadataColors{k};
    end

    info.Reason = "";
    info.ComponentColorMode = image.Parent.Parent.Settings.Display.AuxiliaryColorMode;
    info.ComponentCLims = limits;
    info.ComponentColors = colors;
    info.ComponentColormaps = colormaps;
end
