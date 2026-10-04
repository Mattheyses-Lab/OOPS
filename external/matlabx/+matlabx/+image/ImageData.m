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

classdef ImageData < handle
%%IMAGEDATA  Normalized multi-channel image container
%
%   img = matlabx.image.ImageData(cdata)
%   img = matlabx.image.ImageData(cdata, ChannelNames=["Ch1","Ch2"])
%
%   Supported inputs:
%   - MxN grayscale image
%   - MxNx3 RGB image
%   - 1xN or Nx1 cell array of grayscale and/or RGB images
%
%   This class stores normalized per-channel raw image data plus structural
%   metadata. It does not store viewer state such as active channel,
%   composite mode, display LUT, or current CLim.
%

    properties (Access=private)
        Channels_ (1,:) struct = struct( ...
            'Data', {}, ...
            'Type', {}, ...          % 'grayscale' | 'rgb'
            'Class', {}, ...
            'Size', {}, ...
            'DefaultCLim', {}, ...
            'ChannelName', {}, ...
            'Range', {})
    end

    properties (Dependent, SetAccess=private)
        nChannels
        MultiChannel
        MultiChannelType
        CanMerge
        ChannelNames
    end

    methods
        function obj = ImageData(cdata, opts)
            arguments
                cdata {mustBeA(cdata,{'double','single','uint8','uint16','logical','cell'})}
                opts.ChannelNames = []
            end

            obj.setData(cdata, ChannelNames=opts.ChannelNames);
        end
    end

    %% Public API
    methods
        function setData(obj, cdata, opts)
            arguments
                obj (1,1) matlabx.image.ImageData
                cdata {mustBeA(cdata,{'double','single','uint8','uint16','logical','cell'})}
                opts.ChannelNames = []
            end

            if isempty(cdata)
                cdata = matlabx.image.ImageData.placeholderImage();
            end

            obj.Channels_ = obj.normalizeChannels(cdata, opts.ChannelNames);
        end

        function ch = getChannel(obj, idx)
            idx = obj.validateChannelIndex(idx);
            ch = obj.Channels_(idx);
        end

        function data = getChannelData(obj, idx)
            idx = obj.validateChannelIndex(idx);
            data = obj.Channels_(idx).Data;
        end

        function type = getChannelType(obj, idx)
            idx = obj.validateChannelIndex(idx);
            type = obj.Channels_(idx).Type;
        end

        function cls = getChannelClass(obj, idx)
            idx = obj.validateChannelIndex(idx);
            cls = obj.Channels_(idx).Class;
        end

        function sz = getChannelSize(obj, idx)
            idx = obj.validateChannelIndex(idx);
            sz = obj.Channels_(idx).Size;
        end

        function clim = getDefaultCLim(obj, idx)
            idx = obj.validateChannelIndex(idx);
            clim = obj.Channels_(idx).DefaultCLim;
        end

        function name = getChannelName(obj, idx)
            idx = obj.validateChannelIndex(idx);
            name = obj.Channels_(idx).ChannelName;
        end

        function name = getChannelRange(obj, idx)
            idx = obj.validateChannelIndex(idx);
            name = obj.Channels_(idx).Range;
        end


        function setChannelName(obj, idx, name)
            arguments
                obj (1,1) matlabx.image.ImageData
                idx (1,1) double
                name {mustBeTextScalar}
            end

            idx = obj.validateChannelIndex(idx);
            obj.Channels_(idx).ChannelName = string(name);
        end
    end

    %% Dependent getters
    methods
        function n = get.nChannels(obj)
            n = numel(obj.Channels_);
        end

        function tf = get.MultiChannel(obj)
            tf = obj.nChannels > 1;
        end

        function val = get.MultiChannelType(obj)
            if obj.nChannels <= 1
                val = 'none';
                return
            end

            types = {obj.Channels_.Type};

            if all(strcmp(types,'grayscale'))
                val = 'grayscale';
            elseif all(strcmp(types,'rgb'))
                val = 'rgb';
            else
                val = 'mixed';
            end
        end

        function tf = get.CanMerge(obj)
            % Intended for grayscale composite workflows only.
            if obj.nChannels <= 1
                tf = false;
                return
            end

            if ~strcmp(obj.MultiChannelType,'grayscale')
                tf = false;
                return
            end

            sz0 = obj.Channels_(1).Size;
            cls0 = obj.Channels_(1).Class;

            sameSize  = all(arrayfun(@(ch) isequal(ch.Size, sz0), obj.Channels_));
            sameClass = all(strcmp({obj.Channels_.Class}, cls0));

            tf = sameSize && sameClass;
        end

        function names = get.ChannelNames(obj)
            names = strings(1, obj.nChannels);
            for i = 1:obj.nChannels
                names(i) = obj.Channels_(i).ChannelName;
            end
        end
    end

    %% Internal normalization
    methods (Access=private)
        function channels = normalizeChannels(obj, cdata, channelNames)
            if ~iscell(cdata)
                cdata = {cdata};
            end

            n = numel(cdata);
            channelNames = obj.normalizeChannelNames(channelNames, n);

            channels = repmat(struct( ...
                'Data', [], ...
                'Type', '', ...
                'Class', '', ...
                'Size', [], ...
                'DefaultCLim', [], ...
                'ChannelName', "", ...
                'Range', []), 1, n);

            for i = 1:n
                this = cdata{i};
                [type, sz] = obj.inferChannelTypeAndSize(this);

                channels(i).Data = this;
                channels(i).Type = type;
                channels(i).Class = class(this);
                channels(i).Size = sz;
                channels(i).DefaultCLim = obj.computeDefaultCLim(this, type);
                channels(i).ChannelName = channelNames(i);
                channels(i).Range = getrangefromclass(this);
            end
        end

        function names = normalizeChannelNames(~, namesIn, n)
            if isempty(namesIn)
                names = strings(1,n);
                return
            end

            if ischar(namesIn)
                namesIn = string({namesIn});
            elseif isstring(namesIn)
                namesIn = reshape(namesIn, 1, []);
            elseif iscellstr(namesIn)
                namesIn = string(namesIn);
                namesIn = reshape(namesIn, 1, []);
            else
                error('ImageData:InvalidChannelNames', ...
                    'ChannelNames must be a string array, cellstr, char vector, or empty.');
            end

            if numel(namesIn) > n
                names = namesIn(1:n);
            elseif numel(namesIn) < n
                names = [namesIn, strings(1, n-numel(namesIn))];
            else
                names = namesIn;
            end
        end

        function [type, sz] = inferChannelTypeAndSize(~, cdata)
            sz = size(cdata);

            switch ndims(cdata)
                case 2
                    type = 'grayscale';
                case 3
                    if size(cdata,3) == 3
                        type = 'rgb';
                    else
                        error('ImageData:InvalidCDataSize', ...
                            'CData must be MxN (grayscale) or MxNx3 (truecolor).');
                    end
                otherwise
                    error('ImageData:InvalidCDataDimensions', ...
                        'CData must have either 2 or 3 dimensions.');
            end
        end

        function clim = computeDefaultCLim(~, cdata, type)
            switch type
                case 'rgb'
                    clim = [];
                    return
                case 'grayscale'
                    if islogical(cdata)
                        clim = [];
                        return
                    end
            end

            clim = double([min(cdata(:)) max(cdata(:))]);

            if clim(1) == clim(2)
                clim = getrangefromclass(cdata);
            end
        end

        function idx = validateChannelIndex(obj, idx)
            if idx < 1 || idx > obj.nChannels || idx ~= round(idx)
                error('ImageData:InvalidChannelIndex', ...
                    'Index %g does not refer to an existing channel.', idx);
            end
        end
    end

    methods (Static, Access=private)
        function I = placeholderImage()
            I = zeros(256,256,3);
        end
    end
end