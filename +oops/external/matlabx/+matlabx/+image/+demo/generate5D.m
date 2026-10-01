% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function imageData = generate5D(Y, X, C, Z, T, imgClass)
%GENERATE5D  Generate synthetic data for a 5-D image viewer
%
%   imageData = generate5D()
%   imageData = generate5D(Y, X, C, Z, T, imgClass)
%
%   INPUTS
%       Y           - Image height in pixels
%       X           - Image width in pixels
%       C           - Number of channels/components
%       Z           - Number of Z slices
%       T           - Number of time frames
%       imgClass    - Output image class:
%                     'uint8', 'uint16', 'single', or 'double'
%
%   OUTPUT
%       imageData   - 1-by-C cell array. Each cell contains a numeric array
%                     of size [Y, X, 1, Z, T].
%
%   Each channel contains a distinct spatial pattern. The pattern changes
%   with both Z position and time so navigation through any dimension is
%   visually apparent.

    arguments
        Y        (1,1) double {mustBeInteger, mustBePositive} = 256
        X        (1,1) double {mustBeInteger, mustBePositive} = 256
        C        (1,1) double {mustBeInteger, mustBePositive} = 3
        Z        (1,1) double {mustBeInteger, mustBePositive} = 10
        T        (1,1) double {mustBeInteger, mustBePositive} = 10
        imgClass (1,:) char   {mustBeMember(imgClass, ...
                     {'uint8','uint16','single','double'})} = 'uint8'
    end

    % Normalized image coordinates.
    [xGrid, yGrid] = meshgrid( ...
        linspace(-1, 1, X), ...
        linspace(-1, 1, Y));

    imageData = cell(1, C);

    for c = 1:C
        component = zeros(Y, X, 1, Z, T, imgClass);

        % Give each channel a distinct angular orientation.
        channelAngle = 2*pi*(c - 1)/C;

        for z = 1:Z
            zNorm = normalizedIndex(z, Z);

            for t = 1:T
                tNorm = normalizedIndex(t, T);

                % Moving Gaussian feature.
                centerX = 0.45*cos(2*pi*tNorm + channelAngle);
                centerY = 0.45*sin(2*pi*tNorm + channelAngle) ...
                        + 0.20*zNorm;

                sigma = 0.12 + 0.04*(c - 1)/max(C - 1, 1);

                gaussian = exp( ...
                    -((xGrid - centerX).^2 + (yGrid - centerY).^2) ...
                    /(2*sigma^2));

                % Oriented stripe pattern unique to each channel.
                rotatedCoordinate = ...
                    xGrid*cos(channelAngle) + ...
                    yGrid*sin(channelAngle);

                stripeFrequency = 2 + c;
                stripes = 0.5 + 0.5*cos( ...
                    2*pi*stripeFrequency*rotatedCoordinate ...
                    + 2*pi*tNorm + pi*zNorm);

                % Ring whose radius changes through Z.
                radius = hypot(xGrid, yGrid);
                ringRadius = 0.20 + 0.45*(z - 1)/max(Z - 1, 1);
                ring = exp(-((radius - ringRadius).^2)/(2*0.035^2));

                % Smooth Z- and T-dependent background gradients.
                zGradient = 0.5 + 0.5*zNorm*yGrid;
                tGradient = 0.5 + 0.5*sin(2*pi*tNorm + pi*xGrid);

                % Channel-specific weighting makes components recognizable.
                switch mod(c - 1, 3)
                    case 0
                        image = ...
                            0.55*gaussian + ...
                            0.20*stripes + ...
                            0.15*ring + ...
                            0.10*zGradient;

                    case 1
                        image = ...
                            0.25*gaussian + ...
                            0.45*stripes + ...
                            0.20*ring + ...
                            0.10*tGradient;

                    case 2
                        image = ...
                            0.25*gaussian + ...
                            0.15*stripes + ...
                            0.50*ring + ...
                            0.10*zGradient;
                end

                % Add a small channel-dependent offset and normalize.
                image = image + 0.03*(c - 1);
                image = rescale(image, 0, 1);

                component(:, :, 1, z, t) = castNormalizedImage( ...
                    image, imgClass);
            end
        end

        imageData{c} = component;
    end
end


function value = normalizedIndex(index, count)
%NORMALIZEDINDEX  Map an array index to the range [-1, 1].

    if count == 1
        value = 0;
    else
        value = 2*(index - 1)/(count - 1) - 1;
    end
end


function image = castNormalizedImage(image, imgClass)
%CASTNORMALIZEDIMAGE  Convert normalized image data to the requested class.

    switch imgClass
        case 'uint8'
            image = uint8(image * double(intmax('uint8')));

        case 'uint16'
            image = uint16(image * double(intmax('uint16')));

        case 'single'
            image = single(image);

        case 'double'
            image = double(image);
    end
end