% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function values = objectMeasurements(mask,pixelLists,average,order,azimuth,settings)
%OBJECTMEASUREMENTS Derive pixel-unit morphology, intensity, and axial FPM summaries.
% Background rings exclude other objects/buffers according to hidden settings.

% Connected-component description built from the supplied object pixel lists.
cc = struct('Connectivity',4,'ImageSize',size(mask),'NumObjects',numel(pixelLists), ...
    'PixelIdxList',{pixelLists});

% Morphology measurements returned by regionprops for all objects.
props = regionprops(cc,'Area','Circularity','ConvexArea','Eccentricity','EquivDiameter', ...
    'Extent','FilledArea','MajorAxisLength','MinorAxisLength','Perimeter','Solidity', ...
    'Centroid','MaxFeretProperties','MinFeretProperties');

% Cell array collecting one scalar-measurement struct per object.
values = cell(1,numel(pixelLists));

% Square dilation neighborhood defining the excluded buffer around an object.
bufferKernel = ones(2*settings.BufferRadius+1);

% Square dilation neighborhood extending the buffer into a background ring.
backgroundKernel = ones(2*settings.BackgroundWidth+1);

% Crop padding needed to accommodate both successive dilations.
margin = settings.BufferRadius+settings.BackgroundWidth;

% Combined object-buffer mask used when other objects' buffers are excluded.
allBuffers = [];

if settings.ExcludeOtherBuffers
    allBuffers = imdilate(mask,bufferKernel);
end

% Measure each object using its stored pixels and a local background crop.
for k = 1:numel(pixelLists)

    % Morphology/result struct for the current object.
    s = props(k);

    % Parent-image [x y] centroid to split into stored scalar coordinates.
    centroid = s.Centroid;
    s = rmfield(s,'Centroid');
    s.CentroidX = centroid(1);
    s.CentroidY = centroid(2);

    % Fields produced by regionprops, including extra Feret outputs to discard.
    names = fieldnames(s);

    % Measurement field names supported by the Object model.
    keep = oops.model.Object.measurementNames();
    s = rmfield(s,names(~ismember(string(names),keep)));

    % Convert this object's pixels to rows/columns for a padded local crop,
    % matching the legacy local S/B computation.
    [r,c] = ind2sub(size(mask),pixelLists{k});

    % Clipped parent-image row indices spanning the object and background margin.
    rows = max(1,min(r)-margin):min(size(mask,1),max(r)+margin);

    % Clipped parent-image column indices spanning the object and background margin.
    cols = max(1,min(c)-margin):min(size(mask,2),max(c)+margin);

    % Local binary mask containing only the current object.
    own = false(numel(rows),numel(cols));
    own(sub2ind(size(own),r-rows(1)+1,c-cols(1)+1)) = true;

    % Dilated object mask excluding the near-object neighborhood from background.
    buffer = imdilate(own,bufferKernel);

    % Local background candidates outside the buffer and inside the outer dilation.
    ring = imdilate(buffer,backgroundKernel) & ~buffer;

    if settings.ExcludeOtherObjects
        ring = ring & ~mask(rows,cols);
    end

    if settings.ExcludeOtherBuffers
        ring = ring & ~allBuffers(rows,cols);
    end

    % Average-intensity data extracted into the same local crop.
    localAverage = average(rows,cols);
    s.SignalAverage = mean(average(pixelLists{k}),'omitnan');
    s.BGAverage = mean(localAverage(ring),'omitnan');
    s.SBRatio = NaN;

    if s.BGAverage > 0
        s.SBRatio = s.SignalAverage/s.BGAverage;
    end

    if ~isempty(order)

        % Per-object pixel values from the current order or azimuth image.
        data = order(pixelLists{k});
        data = data(isfinite(data));

        if ~isempty(data)
            s.OrderAvg = mean(data);
            s.OrderStd = std(data);
            s.OrderMin = min(data);
            s.OrderMax = max(data);
        end

    end

    if ~isempty(azimuth)
        % Extract this object's axial angles and exclude undefined pixel values.
        data = azimuth(pixelLists{k});
        data = data(isfinite(data));

        if ~isempty(data)

            % Mean doubled-angle complex vector used for axial circular statistics.
            resultant = mean(exp(2i*data));

            % Resultant-vector magnitude, constrained to at most one before logarithms.
            r = min(1,abs(resultant));

            if r > eps
                s.AzimuthAverage = rad2deg(.5*angle(resultant));
            else
                s.AzimuthAverage = NaN;
            end

            s.AzimuthStd = rad2deg(.5*sqrt(-2*log(r)));
            s.AzimuthAngularDeviation = rad2deg(.5*sqrt(2*(1-r)));
        end

    end

    values{k} = s;
end

end
