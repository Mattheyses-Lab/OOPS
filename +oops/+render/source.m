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

% Empty display source until the requested image data are available.
data = matlabx.image.Image5D.empty(0,1);

% Source title, availability, colormap, and display-limit metadata for the caller.
info = struct('Title',name,'Available',false,'Reason',"No active image", ...
    'Colormap',gray(256),'CLim',[],'Domain',"", ...
    'ComponentCLims',{{}},'ComponentColors',{{}},'ComponentColormaps',{{}});
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
            data = matlabx.image.Image5D.fromComponents( ...
                arrayfun(@(k) values(:,:,k),1:4,'UniformOutput',false), ...
                Names=["0 deg","45 deg","90 deg","135 deg"]);
            info.CLim = [0 1];
        case "Corrected"
            % Corrected data are a disposable runtime product, calculated on demand.
            values = oops.analysis.Analyzer.correctedStack(image);

            % Detector-class display copy; the stored analytical result remains double.
            values = detectorDisplayValues(image,values);
            data = matlabx.image.Image5D.fromComponents( ...
                arrayfun(@(k) values(:,:,k),1:4,'UniformOutput',false), ...
                Names=["0 deg","45 deg","90 deg","135 deg"]);
        case "Average intensity"
            % Reuse the durable average when it matches the current calibration.
            if isempty(image.Parent.CalibrationIDs) && isfield(image.Results,'AverageIntensity')
                values = image.Results.AverageIntensity;
            elseif oops.model.internal.hasCurrentCorrection(image)
                values = image.Results.AverageIntensity;
            else
                values = mean(oops.analysis.Analyzer.correctedStack(image),3);
            end

            % Quantize only the display copy; the durable analytical average remains double.
            values = detectorDisplayValues(image,values);
            data = matlabx.image.Image5D.fromComponents(values,Names="Average intensity");
        case "Channels"
            [data,channelInfo] = auxiliaryChannels(image);

            if isempty(data)
                info.Reason = channelInfo.Reason;
                return;
            end

            info.ComponentCLims = channelInfo.ComponentCLims;
            info.ComponentColors = channelInfo.ComponentColors;
            info.ComponentColormaps = channelInfo.ComponentColormaps;
            info.Title = image.Name + " — Auxiliary channels";
        case "Mask"

            if isempty(image.Mask)
                info.Reason = "Mask has not been produced";
                return;
            end

            data = matlabx.image.Image5D.fromComponents(image.Mask,Names="Mask");
            info.CLim = [0 1];
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
    elseif name == "Order"
        info.Domain = "Order";
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
end

function [data,info] = auxiliaryChannels(image)
%AUXILIARYCHANNELS Build a registry-ordered display stack with missing placeholders.

    data = matlabx.image.Image5D.empty(0,1);
    info = struct('Reason',"No auxiliary channels are registered", ...
        'ComponentCLims',{{}},'ComponentColors',{{}},'ComponentColormaps',{{}});

    definitions = image.Parent.Parent.AuxiliaryChannels.Channels;

    if isempty(definitions)
        return;
    end

    % Registry order defines stable component positions across every image.
    planes = cell(1,numel(definitions));
    names = strings(1,numel(definitions));
    limits = cell(1,numel(definitions));
    colors = cell(1,numel(definitions));
    colormaps = repmat({gray(256)},1,numel(definitions));
    available = false(1,numel(definitions));

    for k = 1:numel(definitions)
        definition = definitions(k);
        assignment = image.getAuxiliaryChannel(definition.ID);
        names(k) = definition.Name;
        colors{k} = definition.Color;

        if isempty(assignment)
            planes{k} = zeros(image.Input.SizeY,image.Input.SizeX,'single');
            limits{k} = [0 1];
            continue;
        end

        % Single precision is a render-only common class that preserves uint16 counts
        % exactly and permits composites across heterogeneous detector classes.
        values = single(assignment.getPlane());
        planes{k} = values;
        available(k) = true;

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

    data = matlabx.image.Image5D.fromComponents(planes,Names=names);

    % ImageAxes initializes exact composite colors from component metadata.
    for k = 1:numel(definitions)
        data.Components(k).Color = colors{k};
    end

    info.Reason = "";
    info.ComponentCLims = limits;
    info.ComponentColors = colors;
    info.ComponentColormaps = colormaps;
end

function values = detectorDisplayValues(image,values)
%DETECTORDISPLAYVALUES Quantize a render-only copy to the raw detector class.

    [limits,className] = oops.analysis.detectorRange(image.Input);

    if isempty(limits)
        return;
    end

    % Integer casts round and saturate outside the class range. Model-owned
    % analytical arrays are never modified by this display conversion.
    values = cast(round(values),className);
end
