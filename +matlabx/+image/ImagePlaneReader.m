classdef ImagePlaneReader < handle
    %IMAGEPLANEREADER Reusable plane-reading session for an ImageSource.
    %
    %   Plane readers let algorithms stream many planes without repeatedly
    %   opening a file-backed source. Delete the reader when the operation is
    %   complete; its source-specific cleanup callback runs exactly once.

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

    properties (Access = private)
        ReadFcn_ (1,1) function_handle = @() []
        CloseFcn_ (1,1) function_handle = @() []
        Closed_ (1,1) logical = false
    end

    methods
        function obj = ImagePlaneReader(readFcn, closeFcn)
            %IMAGEPLANEREADER Construct a reader from source-owned callbacks.
            arguments
                readFcn (1,1) function_handle
                closeFcn (1,1) function_handle = @() []
            end
            obj.ReadFcn_ = readFcn;
            obj.CloseFcn_ = closeFcn;
        end

        function plane = getPlane(obj, componentIndex, z, t)
            %GETPLANE Read one Y-by-X scalar or Y-by-X-by-3 RGB plane.
            arguments
                obj (1,1) matlabx.image.ImagePlaneReader
                componentIndex (1,1) double {mustBeInteger,mustBePositive}
                z (1,1) double {mustBeInteger,mustBePositive} = 1
                t (1,1) double {mustBeInteger,mustBePositive} = 1
            end
            if obj.Closed_
                error('matlabx:image:ImagePlaneReader:Closed', ...
                    'This plane-reading session has already been closed.');
            end
            plane = obj.ReadFcn_(componentIndex, z, t);
        end

        function close(obj)
            %CLOSE Release source-specific resources held by this session.
            if obj.Closed_
                return
            end
            obj.Closed_ = true;
            obj.CloseFcn_();
        end

        function delete(obj)
            %DELETE Close the session when its handle is destroyed.
            obj.close();
        end
    end
end
