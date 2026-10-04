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

classdef UICal
%MATLABX.UICAL Static facade for matlabx UI calibration.
%
%   Get the cached calibration object:
%       cal = matlabx.UICal.get()
%
%   Common measurements:
%       h = matlabx.UICal.uipanelTopChromeHeightPx(14)
%       h = matlabx.UICal.panelChromeHeight(14, "FontUnits", "pixels")
%       px = matlabx.UICal.pt2px(12)
%       pt = matlabx.UICal.px2pt(16)
%
%   Maintenance:
%       matlabx.UICal.recalibrate()
%       matlabx.UICal.print()

    methods (Static)

        function cal = get(opts)
        %GET Return the cached UI calibration object.
            arguments
                opts.ForceRecalibrate   (1,1) logical = false
                opts.uipanel            (1,1) logical = true
                opts.uifigure           (1,1) logical = true
            end

            cal = matlabx.ui.calibration.getCalibration( ...
                ForceRecalibrate=opts.ForceRecalibrate, ...
                uipanel=opts.uipanel, ...
                uifigure=opts.uifigure);
        end

        function cal = recalibrate(opts)
        %RECALIBRATE Force UI recalibration and return the new calibration object.
            arguments
                opts.uipanel  (1,1) logical = true
                opts.uifigure (1,1) logical = true
            end

            cal = matlabx.UICal.get( ...
                ForceRecalibrate=true, ...
                uipanel=opts.uipanel, ...
                uifigure=opts.uifigure);
        end

        function px = pt2px(pt)
        %PT2PX Convert points to pixels using the active calibration.
            px = matlabx.UICal.get().pt2px(pt);
        end

        function pt = px2pt(px)
        %PX2PT Convert pixels to points using the active calibration.
            pt = matlabx.UICal.get().px2pt(px);
        end

        function ppi = pixelsPerInch()
        %PIXELSPERINCH Return calibrated screen pixels per inch.
            ppi = matlabx.UICal.get().PixelsPerInch;
        end

        function ppp = pixelsPerPoint()
        %PIXELSPERPOINT Return calibrated screen pixels per point.
            ppp = matlabx.UICal.get().PixelsPerPoint;
        end

        function topChromePx = uipanelTopChromeHeightPx(fontSize, opts)
        %UIPANELTOPCHROMEHEIGHTPX Estimate titled uipanel top chrome height in pixels.
            arguments
                fontSize (1,1) double
                opts.FontUnits (1,:) char {mustBeMember(opts.FontUnits,{'pixels','points'})} = 'pixels'
            end

            cal = matlabx.UICal.get();
            topChromePx = cal.uipanelTopChromeHeightPx(fontSize, ...
                "FontUnits", opts.FontUnits);
        end

        function topChromePx = panelChromeHeight(fontSize, opts)
        %PANELCHROMEHEIGHT Short alias for uipanelTopChromeHeightPx.
            arguments
                fontSize (1,1) double
                opts.FontUnits (1,:) char {mustBeMember(opts.FontUnits,{'pixels','points'})} = 'pixels'
            end

            topChromePx = matlabx.UICal.uipanelTopChromeHeightPx(fontSize, ...
                "FontUnits", opts.FontUnits);
        end

        function pos = uifigureMaximizedOuterPositionPx()
        %UIFIGUREMAXIMIZEDOUTERPOSITIONPX Return calibrated maximized uifigure OuterPosition.
            pos = matlabx.UICal.get().uifigureMaximizedOuterPositionPx();
        end

        function pos = uifigureMaximizedPositionPx()
        %UIFIGUREMAXIMIZEDPOSITIONPX Return calibrated maximized uifigure Position.
            pos = matlabx.UICal.get().uifigureMaximizedPositionPx();
        end

        function pos = uifigureMaximizedInnerPositionPx()
        %UIFIGUREMAXIMIZEDINNERPOSITIONPX Return calibrated maximized uifigure InnerPosition.
            pos = matlabx.UICal.get().uifigureMaximizedInnerPositionPx();
        end

        function s = screenSize()
        %SCREENSIZE Return monitor positions from MATLAB root.
            s = matlabx.ui.calibration.getScreenSize();
        end

        function sc = screenCenter(units)
        %SCREENCENTER Return calibrated screen center.
            arguments
                units (1,:) char {mustBeMember(units,{'pixels','inches','points'})} = 'pixels'
            end

            sc = matlabx.ui.calibration.getScreenCenter(units);
        end

        function pos = centeredFigOuterPosition(W, H)
        %CENTEREDFIGOUTERPOSITION Return centered figure OuterPosition for W x H.
            pos = matlabx.ui.calibration.getCenteredFigOuterPosition(W, H);
        end

        function txt = print()
        %PRINT Print the active UI calibration state.
        %   txt = matlabx.UICal.print() returns formatted text.
            cal = matlabx.UICal.get();
            S = cal.toStruct();

            if nargout == 0
                matlabx.struct.prettyPrint(S);
            else
                txt = matlabx.struct.prettyPrint(S);
            end
        end

    end

end
