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

classdef PlotContent < handle
%PLOTCONTENT Base lifecycle for graphics transferable between PlotAxes hosts.

    properties (SetAccess=private)
        Host (:,1) matlabx.ui.axes.PlotAxes = matlabx.ui.axes.PlotAxes.empty(0,1)
    end

    methods

        function attach(obj,host)
        %ATTACH Transfer content to a host and attach its primitive graphics.

            validateattributes(host,{'matlabx.ui.axes.PlotAxes'},{'scalar'});

            % Public attach and host.mount share one ownership path. The host
            % reserves Content before calling back here to move the primitives.
            if isempty(host.Content) || host.Content ~= obj
                host.mount(obj);
                return;
            end

            if ~isempty(obj.Host) && obj.Host == host
                obj.refresh();
                return;
            end

            obj.Host = host;
            obj.attachGraphics(host.Axes);
            obj.refresh();
        end

        function detach(obj,host)
        %DETACH Hide content and clear its host identity without deleting state.

            if isempty(obj.Host)
                return;
            end

            if nargin > 1 && obj.Host ~= host
                return;
            end

            % Direct detach must clear the host as well. Host.clear removes its
            % reference before calling detach again, so this does not recurse.
            if isvalid(obj.Host) && ~isempty(obj.Host.Content) && obj.Host.Content == obj
                obj.Host.clear(obj);
                return;
            end

            obj.hideGraphics();
            % Parent=[] keeps primitives alive without a hidden parking figure.
            % They cannot affect old-host limits or die with the old figure.
            obj.attachGraphics([]);
            obj.Host = matlabx.ui.axes.PlotAxes.empty(0,1);
        end

        function delete(obj)
        %DELETE Release the host identity when renderer content is destroyed.

            obj.detach();
        end

        function refresh(~)
        %REFRESH Render stored content state when attached; subclasses override.
        end

        function handleEvent(~,~,~)
        %HANDLEEVENT Future FigureEventHub routing hook; subclasses may override.
        end

    end

    methods (Access=protected)

        function attachGraphics(~,~)
        %ATTACHGRAPHICS Move owned primitives to the supplied UIAxes.
        end

        function hideGraphics(~)
        %HIDEGRAPHICS Hide owned primitives while content has no host.
        end

    end

end
