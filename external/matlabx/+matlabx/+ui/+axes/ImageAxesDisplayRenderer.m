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

classdef ImageAxesDisplayRenderer
%IMAGEAXESDISPLAYRENDERER Rendering helpers for ImageAxes display state.
%
%   ImageAxes owns view/display state and decides when to refresh. This helper
%   owns the stateless mechanics of converting that state into graphics-ready
%   CData, axes colormaps, composite RGB images, and colorbar labels.
%
%   Important terminology:
%       RenderSource
%           The currently selected raw component plane, or an already-composited
%           RGB image when ShowComposite is true.
%       DisplayCData
%           The CData assigned to the MATLAB image graphics object. Scalar data
%           are contrast-scaled into display space. RGB data pass through.
%       DisplayMap
%           The N-by-3 colormap used by mainAxes for a component. In "colors"
%           mode this is a black-to-color gradient. In "luts" mode this is the
%           component LUT/colormap itself.
%
%   The class has no persistent state. It receives ImageAxes state objects and
%   graphics handles from the host, performs the conversion/update, and returns
%   results where value-object mutation would otherwise be lost.

    methods (Static)
        function cdata = getDisplayCData(renderSource, imageData, componentDisplay, viewState)
        %GETDISPLAYCDATA Return graphics-ready CData for the current view.

            % Composite rendering already produces RGB display data. Do not apply
            % the current component CLim to a composite.
            if viewState.ShowComposite
                cdata = renderSource;
                return
            end

            % Non-composite rendering is based on the current component. Scalar
            % components use CLim; RGB components are already graphics-ready.
            clim = componentDisplay(viewState.C).CLim;
            comp = imageData.Components(viewState.C);

            switch comp.Kind
                case 'scalar'
                    % Logical images and components without CLim are displayed in
                    % their native values. Numeric scalar data are rescaled to [0,1].
                    if strcmp(comp.Class, 'logical') || isempty(clim)
                        cdata = renderSource;
                    else
                        cdata = matlabx.image.process.rescaleLinear(renderSource, clim);
                    end
                case 'rgb'
                    cdata = renderSource;
            end
        end

        function updateImageCData(hImage, cdata)
        %UPDATEIMAGECDATA Assign rendered CData to the image primitive.
            % Keep the host's refresh method readable and centralize the graphics
            % assignment for future rendering quirks.
            hImage.CData = cdata;
        end

        function updateAxesColormap(ax, componentDisplay, componentIndex)
        %UPDATEAXESCOLORMAP Assign the current component display map to axes.
            % MATLAB colormap is axes-scoped, so ImageAxes updates it whenever the
            % current component or component DisplayMap changes.
            ax.Colormap = componentDisplay(componentIndex).DisplayMap;
        end

        function updateColorbar(colorbar, imageData, componentDisplay, componentIndex)
        %UPDATECOLORBAR Update colorbar ticks for the current component.

            % Empty ticks/labels are intentional for RGB/logical components or when
            % CLim is unavailable. The colorbar object can remain visible but quiet.
            ticks = {};
            labels = {};

            comp = imageData.Components(componentIndex);
            clim = componentDisplay(componentIndex).CLim;

            if strcmp(comp.Kind, 'scalar') && ~strcmp(comp.Class, 'logical') && ~isempty(clim)
                [ticks, labels] = ...
                    matlabx.ui.axes.ImageAxesDisplayRenderer.getColorbarTickLabels(comp.Class, clim);
            end

            colorbar.Ticks = ticks;
            colorbar.TickLabels = labels;
        end

        function componentDisplay = updateAllDisplayMaps(componentDisplay, mode)
        %UPDATEALLDISPLAYMAPS Refresh DisplayMap on each component state object.
            % ImageAxesComponentDisplayState is a value class, so return the updated
            % array to the caller instead of assuming in-place mutation persists.
            for i = 1:numel(componentDisplay)
                componentDisplay(i).DisplayMap = ...
                    matlabx.ui.axes.ImageAxesDisplayRenderer.getDisplayMap(componentDisplay(i), mode);
            end
        end

        function map = getDisplayMap(displayState, mode)
        %GETDISPLAYMAP Return colormap for color-name or LUT display modes.
            switch mode
                case 'colors'
                    % Color mode uses the component's canonical MATLAB color name to
                    % create a grayscale-like ramp ending at that color.
                    map = matlabx.colors.ops.colorGradient( ...
                        [0 0 0], ...
                        matlabx.colors.names.toRGB(char(displayState.ColorName), "Palette", "MATLAB"), ...
                        256);
                case 'luts'
                    % LUT mode uses the stored colormap directly.
                    map = displayState.Colormap;
            end
        end

        function I = getCompositeImage(imageData, componentDisplay, viewState)
        %GETCOMPOSITEIMAGE Merge scalar components into an RGB composite.

            % Composite display only makes sense for mergeable scalar components.
            % Otherwise fall back to the currently selected component plane.
            if ~imageData.CanMergeComponents
                I = imageData.getPlane(viewState.C, viewState.Z, viewState.T);
                return
            end

            if ~strcmp(imageData.MultiComponentKind, 'scalar')
                I = imageData.getPlane(viewState.C, viewState.Z, viewState.T);
                return
            end

            n = imageData.NumComponents;
            data = cell(1, n);
            clims = zeros(n, 2);

            % Collect the same Z/T plane from every component, with each component's
            % own contrast limits.
            for c = 1:n
                data{c} = imageData.getPlane(c, viewState.Z, viewState.T);
                clims(c,:) = componentDisplay(c).CLim;
            end

            switch viewState.ComponentColorMode
                case 'colors'
                    % Colors mode merges channels using one RGB color per component.
                    colors = zeros(n, 3);
                    for i = 1:n
                        colors(i,:) = matlabx.colors.names.toRGB( ...
                            char(componentDisplay(i).ColorName), "Palette", "MATLAB");
                    end
                    I = matlabx.image.compose.mergeChannelsRGB_add(data, clims, colors);

                case 'luts'
                    % LUT mode maps each channel through its stored DisplayMap before
                    % merging.
                    maps = {componentDisplay.DisplayMap};
                    I = matlabx.image.compose.mergeChannelsRGB_LUT(data, clims, maps);
            end
        end

        function [ticks, labels] = getColorbarTickLabels(valClass, clim, N)
        %GETCOLORBARTICKLABELS Return colorbar ticks/labels for display range.
        %
        %   Colorbar ticks are normalized because DisplayCData is normalized to
        %   [0,1]. Labels show the corresponding source-data values from CLim.
            arguments
                valClass (1,:) char {mustBeMember(valClass, {'logical','double','single','uint16','uint8'})}
                clim (1,2) double
                N (:,1) = []
            end

            % Use a compact binary scale for logical values and a denser numeric
            % scale for ordinary scalar images.
            if isempty(N)
                if strcmp(valClass, 'logical')
                    N = 2;
                else
                    N = 11;
                end
            end

            % Ticks are in displayed CData space.
            ticks = linspace(0, 1, N);

            % Labels are formatted in source-data space.
            switch valClass
                case 'logical'
                    labels = arrayfun(@(v) sprintf('%i', v), ticks, 'UniformOutput', false);
                case {'double','single'}
                    labels = arrayfun(@(v) sprintf('%.2f', v), ...
                        linspace(clim(1), clim(2), N), 'UniformOutput', false);
                case {'uint16','uint8'}
                    labels = arrayfun(@(v) sprintf('%i', v), ...
                        round(linspace(clim(1), clim(2), N)), 'UniformOutput', false);
            end
        end
    end

end
