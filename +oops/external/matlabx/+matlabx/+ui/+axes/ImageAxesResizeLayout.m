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

classdef ImageAxesResizeLayout
%IMAGEAXESRESIZELAYOUT Aspect-fit sizing helper for ImageAxes.
%
%   ImageAxes displays image content inside a titled uipanel. The panel title
%   area consumes a calibrated number of pixels at the top, so the actual image
%   area is smaller than the component height. This helper computes the 3-by-3
%   sizing grid used to center the panel and preserve the source image aspect
%   ratio.
%
%   The important policy here is integer layout. MATLAB UI containers ultimately
%   realize sizes on screen pixels, so this class rounds the target panel size
%   and then splits any leftover padding between the two sides. Some component
%   sizes cannot represent the image aspect ratio perfectly; diagnostic fields
%   expose the resulting sub-pixel/integer roundoff.
%
%   ImageAxes remains responsible for deciding when a resize should happen and
%   for remembering the last layout key. This class only computes, applies, and
%   explains a layout.

    methods (Static)
        function S = compute(component, imageHeightPx, imageWidthPx, panelTopChromePx)
        %COMPUTE Return integer layout values for the current component size.

            % getpixelposition avoids temporarily changing ImageAxes.Units. Width
            % and height are enough for layout; absolute position is diagnostic-only.
            compPos = getpixelposition(component);

            % Work in nonnegative integer pixels. The image dimensions should already
            % be integer, but rounding keeps this function robust to caller input.
            componentW = max(0, round(compPos(3)));
            componentH = max(0, round(compPos(4)));
            panelTop = max(0, round(panelTopChromePx));
            imgH = max(0, round(imageHeightPx));
            imgW = max(0, round(imageWidthPx));

            % The struct doubles as the normal layout payload and diagnostic record.
            % Initialize all fields so invalid layouts are still printable.
            S = struct( ...
                'IsValid', false, ...
                'ComponentPositionPx', compPos, ...
                'ComponentWidthPx', componentW, ...
                'ComponentHeightPx', componentH, ...
                'PanelTopChromePx', panelTop, ...
                'AvailableImageHeightPx', componentH - panelTop, ...
                'ImageWidthPx', imgW, ...
                'ImageHeightPx', imgH, ...
                'ImageAspectRatioHW', NaN, ...
                'AvailableAspectRatioHW', NaN, ...
                'FitLimitedBy', "", ...
                'IdealPanelWidthPx', NaN, ...
                'IdealPanelImageAreaHeightPx', NaN, ...
                'PanelWidthPx', NaN, ...
                'PanelHeightPx', NaN, ...
                'PanelImageAreaHeightPx', NaN, ...
                'PanelWidthRoundoffPx', NaN, ...
                'PanelImageAreaHeightRoundoffPx', NaN, ...
                'PanelImageAspectRatioHW', NaN, ...
                'PanelImageAspectRatioError', NaN, ...
                'LeftPadPx', NaN, ...
                'RightPadPx', NaN, ...
                'TopPadPx', NaN, ...
                'BottomPadPx', NaN, ...
                'HorizontalPadSymmetric', false, ...
                'VerticalPadSymmetric', false, ...
                'LayoutKey', [componentW, componentH, imgW, imgH, panelTop]);

            % Invalid or not-yet-realized UI sizes are common during construction.
            % Return IsValid=false so callers can simply skip applying the layout.
            if componentW <= 0 || componentH <= panelTop || imgH <= 0 || imgW <= 0
                return
            end

            % Aspect ratios are expressed as height/width because MATLAB image data
            % size is naturally [rows columns] == [height width].
            imageAreaH = componentH - panelTop;
            targetRatio = imgH / imgW;
            currentRatio = imageAreaH / componentW;

            % If the available area is taller than the image, width limits the fit;
            % otherwise height limits the fit. The limiting dimension remains exact
            % and the other dimension is rounded to the nearest screen pixel.
            if currentRatio > targetRatio
                fitLimitedBy = "width";
                panelW = componentW;
                idealPanelW = componentW;
                idealImageH = componentW * targetRatio;
                imageH = round(idealImageH);
            else
                fitLimitedBy = "height";
                imageH = imageAreaH;
                idealImageH = imageAreaH;
                idealPanelW = imageAreaH / targetRatio;
                panelW = round(idealPanelW);
            end

            % Clamp after rounding so pathological tiny component sizes never produce
            % a panel outside the component bounds.
            panelW = min(componentW, max(1, panelW));
            panelH = min(componentH, max(1, imageH) + panelTop);

            % Split leftover pixels explicitly. When there is an odd leftover pixel,
            % the right/bottom side gets the extra pixel; this avoids fractional grid
            % tracks and prevents one-sided drift over repeated resizes.
            leftPad = floor((componentW - panelW)/2);
            rightPad = componentW - panelW - leftPad;
            topPad = floor((componentH - panelH)/2);
            bottomPad = componentH - panelH - topPad;

            S.IsValid = true;
            S.ImageAspectRatioHW = targetRatio;
            S.AvailableAspectRatioHW = currentRatio;
            S.FitLimitedBy = fitLimitedBy;
            S.IdealPanelWidthPx = idealPanelW;
            S.IdealPanelImageAreaHeightPx = idealImageH;
            S.PanelWidthPx = panelW;
            S.PanelHeightPx = panelH;
            S.PanelImageAreaHeightPx = panelH - panelTop;
            S.PanelWidthRoundoffPx = S.PanelWidthPx - S.IdealPanelWidthPx;
            S.PanelImageAreaHeightRoundoffPx = ...
                S.PanelImageAreaHeightPx - S.IdealPanelImageAreaHeightPx;
            S.PanelImageAspectRatioHW = S.PanelImageAreaHeightPx / S.PanelWidthPx;
            S.PanelImageAspectRatioError = S.PanelImageAspectRatioHW - S.ImageAspectRatioHW;
            S.LeftPadPx = leftPad;
            S.RightPadPx = rightPad;
            S.TopPadPx = topPad;
            S.BottomPadPx = bottomPad;
            S.HorizontalPadSymmetric = leftPad == rightPad;
            S.VerticalPadSymmetric = topPad == bottomPad;
        end

        function apply(sizingGrid, S)
        %APPLY Set the sizing grid from a valid resize-layout struct.

            % The center cell contains the uipanel. Surrounding tracks are padding.
            set(sizingGrid, ...
                'ColumnWidth',{S.LeftPadPx,S.PanelWidthPx,S.RightPadPx}, ...
                'RowHeight',{S.TopPadPx,S.PanelHeightPx,S.BottomPadPx});
        end

        function S = addDiagnostics(S, component, grid, sizingGrid, panel, mainAxes, staticAxes, opts)
        %ADDDIAGNOSTICS Add realized UI geometry fields to a layout struct.
        %
        %   "Calculated" fields come from compute(). "Actual" fields come from
        %   MATLAB after layout has been realized. Comparing them helps distinguish
        %   layout math issues from UIAxes/uipanel rendering behavior.

            arguments
                S struct
                component
                grid
                sizingGrid
                panel
                mainAxes
                staticAxes
                opts.LastResizeLayoutKey (1,5) double = NaN(1,5)
                opts.PendingSizeUpdate (1,1) logical = false
            end

            % Absolute positions help diagnose parent/layout-manager quirks. They are
            % intentionally excluded from compute() to keep resize work lean.
            S.ComponentAbsolutePositionPx = getpixelposition(component,true);
            S.LastResizeLayoutKey = opts.LastResizeLayoutKey;
            S.PendingSizeUpdate = opts.PendingSizeUpdate;

            % Local and absolute positions are both useful when ImageAxes is nested
            % inside app layouts. Width/height deltas should agree; origins may not.
            S.GridPositionPx = getpixelposition(grid);
            S.GridAbsolutePositionPx = getpixelposition(grid,true);
            S.SizingGridPositionPx = getpixelposition(sizingGrid);
            S.SizingGridAbsolutePositionPx = getpixelposition(sizingGrid,true);
            S.PanelOuterPositionPx = getpixelposition(panel);
            S.PanelAbsoluteOuterPositionPx = getpixelposition(panel,true);
            S.PanelInnerPosition = panel.InnerPosition;
            S.PanelInnerPositionPx = ...
                matlabx.ui.axes.ImageAxesResizeLayout.positionFromReferencePx( ...
                panel.InnerPosition, panel.Units, S.PanelOuterPositionPx);
            S.MainAxesOuterPositionPx = getpixelposition(mainAxes);
            S.MainAxesAbsoluteOuterPositionPx = getpixelposition(mainAxes,true);
            S.MainAxesInnerPosition = mainAxes.InnerPosition;
            S.MainAxesInnerPositionPx = ...
                matlabx.ui.axes.ImageAxesResizeLayout.positionFromReferencePx( ...
                mainAxes.InnerPosition, mainAxes.Units, S.PanelInnerPositionPx);
            S.StaticAxesOuterPositionPx = getpixelposition(staticAxes);
            S.StaticAxesAbsoluteOuterPositionPx = getpixelposition(staticAxes,true);
            S.StaticAxesInnerPosition = staticAxes.InnerPosition;
            S.StaticAxesInnerPositionPx = ...
                matlabx.ui.axes.ImageAxesResizeLayout.positionFromReferencePx( ...
                staticAxes.InnerPosition, staticAxes.Units, S.PanelInnerPositionPx);

            S.SizingGridColumnWidth = sizingGrid.ColumnWidth;
            S.SizingGridRowHeight = sizingGrid.RowHeight;
            S.PanelUnits = string(panel.Units);
            S.PanelFontSize = panel.FontSize;
            S.PanelFontUnits = panel.FontUnits;
            S.PanelTitle = string(panel.Title);
            S.MainAxesUnits = string(mainAxes.Units);
            S.StaticAxesUnits = string(staticAxes.Units);

            % Delta fields compare realized UI sizes against the requested layout.
            % Nonzero values here point to MATLAB container/axes realization rather
            % than the aspect-fit arithmetic.
            S.ActualPanelImageAreaHeightPx = S.PanelOuterPositionPx(4) - S.PanelTopChromePx;
            S.ActualPanelWidthDeltaPx = S.PanelOuterPositionPx(3) - S.PanelWidthPx;
            S.ActualPanelHeightDeltaPx = S.PanelOuterPositionPx(4) - S.PanelHeightPx;
            S.ActualPanelImageAreaHeightDeltaPx = ...
                S.ActualPanelImageAreaHeightPx - S.PanelImageAreaHeightPx;
            S.ActualInnerVsCalculatedImageWidthDeltaPx = ...
                S.PanelInnerPositionPx(3) - S.PanelWidthPx;
            S.ActualInnerVsCalculatedImageHeightDeltaPx = ...
                S.PanelInnerPositionPx(4) - S.PanelImageAreaHeightPx;
            S.ActualMainAxesInnerVsPanelInnerWidthDeltaPx = ...
                S.MainAxesInnerPositionPx(3) - S.PanelInnerPositionPx(3);
            S.ActualMainAxesInnerVsPanelInnerHeightDeltaPx = ...
                S.MainAxesInnerPositionPx(4) - S.PanelInnerPositionPx(4);
            S.ActualStaticAxesInnerVsPanelInnerWidthDeltaPx = ...
                S.StaticAxesInnerPositionPx(3) - S.PanelInnerPositionPx(3);
            S.ActualStaticAxesInnerVsPanelInnerHeightDeltaPx = ...
                S.StaticAxesInnerPositionPx(4) - S.PanelInnerPositionPx(4);
            S.ActualMainAxesOuterVsPanelInnerWidthDeltaPx = ...
                S.MainAxesOuterPositionPx(3) - S.PanelInnerPositionPx(3);
            S.ActualMainAxesOuterVsPanelInnerHeightDeltaPx = ...
                S.MainAxesOuterPositionPx(4) - S.PanelInnerPositionPx(4);
        end
    end

    methods (Static, Access=private)
        function posPx = positionFromReferencePx(pos, units, referencePosPx)
        %POSITIONFROMREFERENCEPX Convert a position vector using a pixel reference.
        %
        %   This is intentionally conservative and diagnostic-only. MATLAB's
        %   getpixelposition does not expose InnerPosition, so normalized inner
        %   positions are scaled from a known pixel rectangle without mutating Units.

            units = string(units);

            if units == "pixels"
                posPx = pos;
                return
            end

            if units ~= "normalized" || numel(pos) ~= 4 || numel(referencePosPx) ~= 4
                posPx = NaN(1,4);
                return
            end

            posPx = [ ...
                referencePosPx(1) + pos(1) * referencePosPx(3), ...
                referencePosPx(2) + pos(2) * referencePosPx(4), ...
                pos(3) * referencePosPx(3), ...
                pos(4) * referencePosPx(4)];
        end
    end

end
