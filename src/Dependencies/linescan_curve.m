function [D, Y] = linescan_curve(I, P, opts)
%LINESCAN_CURVE  Mean-intensity line scan along an open curve with thickness.
%
%   [D, Y] = linescan_curve(I, P)
%   [D, Y] = linescan_curve(I, P, Name=Value, ...)
%
%   Inputs
%   ------
%   I : 2D numeric array OR cell array of 2D numeric arrays
%       Intensity image(s). NaNs are allowed (and are omitted from the mean).
%       If you pass RGB, convert to grayscale first.
%
%       If I is a cell array (e.g., multiple channels/images), the output Y is
%       a cell array the same size as I, where each cell contains the profile
%       along the same distance vector D.
%
%   P : Nx2 numeric array
%       Open curve polyline in image coordinates: P(:,1)=x (column), P(:,2)=y (row).
%       Points do not need to be uniformly spaced.
%
%   Name-Value options (opts)
%   -------------------------
%   AlongStep : positive scalar, default 1
%       Desired spacing (pixels) between samples along the curve after reinterpolation.
%
%   Width : positive scalar, default 3
%       Full scan width (pixels) perpendicular to the curve.
%       The scan samples from -Width/2 to +Width/2 along the local normal direction.
%
%   CrossStep : positive scalar, default 0.5
%       Spacing (pixels) between samples across the width.
%
%   InterpMethod : string, default "linear"
%       Interpolation used for sampling the image via interp2: "linear", "cubic", "nearest".
%
%   FillValue : scalar, default NaN
%       Value used for out-of-bounds samples during interpolation. Using NaN pairs well
%       with mean(...,'omitnan') so edge samples don't bias the average.
%
%   FillGaps : logical, default false
%       If true, fill NaN gaps in the output profile(s) using fillmissing.
%
%   FillMethod : string, default "linear"
%       Method passed to fillmissing (e.g., "linear", "pchip", "makima").
%
%   MaxGap : positive scalar, default Inf
%       Maximum gap size to fill in the output profile(s), in PIXELS along the curve.
%       Internally converted to a maximum number of samples based on AlongStep.
%
%   Outputs
%   -------
%   D : Kx1 double
%       Distance along the curve (arc length) with D(1)=0 and D(end)=curve length.
%
%   Y : Kx1 double OR cell array of Kx1 doubles
%       Mean intensity in a band of given Width centered on the curve at each D.
%       If I is a cell array, Y is a cell array matching I.
%
%   Notes
%   -----
%   - Coordinates: x increases to the right (columns), y increases downward (rows).
%   - This function is vectorized per-image: it builds a sampling "strip" and calls
%     interp2 once per image (looping only over the cell array, if provided).
%
%   Example
%   -------
%   [D,Y] = linescan_curve(I, P, Width=5, AlongStep=0.5, FillGaps=true, MaxGap=2);
%   plot(D, Y);

arguments
    I
    P (:,2) double {mustBeFinite, mustHaveAtLeast2Points, mustNotHaveRepeatedConsecutivePoints}
    opts.AlongStep (1,1) double {mustBePositive} = 1
    opts.Width     (1,1) double {mustBePositive} = 3
    opts.CrossStep (1,1) double {mustBePositive} = 0.5
    opts.InterpMethod (1,1) string {mustBeMember(opts.InterpMethod, ["linear","nearest","cubic"])} = "linear"
    opts.FillValue (1,1) double = NaN

    opts.FillGaps   (1,1) logical = false
    opts.FillMethod (1,1) string  = "linear"

    % maximum size of gap to fill in output profile (in pixels)
    opts.MaxGap     (1,1) double  {mustBePositive} = Inf
end

% --- Validate I: allow numeric 2D OR cell array of numeric 2D
isCellI = iscell(I);
if isCellI
    if isempty(I)
        error("If I is a cell array, it must not be empty.");
    end
    for k = 1:numel(I)
        mustBeNumeric2D(I{k});
    end
else
    mustBeNumeric2D(I);
end

% --- Convert P to double for geometry math
P = double(P);

% --- 1) Parameterize the polyline by cumulative arc length
x = P(:,1);
y = P(:,2);
segLen = hypot(diff(x), diff(y));          % length of each segment
s = [0; cumsum(segLen)];                  % cumulative distance at each original vertex
L = s(end);                               % total curve length (pixels)

% Handle degenerate case: all points identical (or nearly) -> no curve
if L == 0
    D = 0;
    if isCellI
        Y = cell(size(I));
        for k = 1:numel(I)
            Ik = double(I{k});
            Y{k} = interp2(Ik, x(1), y(1), opts.InterpMethod, opts.FillValue);
        end
    else
        Ik = double(I);
        Y = interp2(Ik, x(1), y(1), opts.InterpMethod, opts.FillValue);
    end
    return;
end

% --- 2) Reinterpolate the curve at uniform spacing AlongStep
D = (0:opts.AlongStep:L).';
% Ensure the endpoint is included exactly (avoid floating point drop)
if D(end) < L
    D(end+1,1) = L;
end

xD = interp1(s, x, D, "linear");
yD = interp1(s, y, D, "linear");

% --- 3) Estimate tangent and normal vectors along the resampled curve
% Use numerical derivatives w.r.t. distance (D), then normalize to unit tangents.
% NOTE: use D (not AlongStep) so the endpoint spacing is handled correctly.
tx = gradient(xD, D);
ty = gradient(yD, D);

tNorm = hypot(tx, ty);
tNorm(tNorm == 0) = NaN; % guard against rare zero-norm tangents

tx = tx ./ tNorm;
ty = ty ./ tNorm;

% Unit normal (perpendicular) to tangent:
% If t = (tx,ty), a perpendicular is n = (-ty, tx)
nx = -ty;
ny =  tx;

% --- 4) Build a cross-section sampling grid in the normal direction
halfW = opts.Width / 2;
u = (-halfW : opts.CrossStep : halfW);     % 1xM offsets across width
U = reshape(u, 1, []);                     % ensure row vector

% Create a KxM grid of sample coordinates:
Xs = xD + nx .* U;
Ys = yD + ny .* U;

% --- 5) Compute profile(s)
if isCellI
    Y = cell(size(I));
    for k = 1:numel(I)
        Ik = double(I{k});

        % Sample the image on the strip
        stripVals = interp2(Ik, Xs, Ys, opts.InterpMethod, opts.FillValue);

        % Mean across width (omit NaNs, so masked/background doesn't contribute)
        yk = mean(stripVals, 2, "omitnan");

        % Optional: fill NaN gaps in output profile
        if opts.FillGaps
            maxGapSamples = floor(opts.MaxGap / opts.AlongStep); % opts.MaxGap is in pixels
            yk = fillmissing(yk, opts.FillMethod, 'MaxGap', maxGapSamples);
        end

        Y{k} = yk;
    end
else
    Ik = double(I);

    stripVals = interp2(Ik, Xs, Ys, opts.InterpMethod, opts.FillValue);
    Y = mean(stripVals, 2, "omitnan");

    if opts.FillGaps
        maxGapSamples = floor(opts.MaxGap / opts.AlongStep); % opts.MaxGap is in pixels
        Y = fillmissing(Y, opts.FillMethod, 'MaxGap', maxGapSamples);
    end
end

end

% =========================
% Local validation helpers
% =========================

function mustBeNumeric2D(A)
if ~ismatrix(A)
    error("I must be a 2D matrix (grayscale intensity image).");
end
if ~isnumeric(A)
    error("I must be numeric.");
end
if any(isinf(A(:)))
    error("I must not contain Inf values.");
end
end

function mustHaveAtLeast2Points(P)
if size(P,1) < 2
    error("P must have at least 2 points (Nx2).");
end
end

function mustNotHaveRepeatedConsecutivePoints(P)
d = diff(P,1,1);
if any(hypot(d(:,1), d(:,2)) == 0)
    error("P must not contain repeated consecutive points (zero-length segments).");
end
end