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

classdef BioFormatsImageSource < matlabx.image.ImageSource
    %BIOFORMATSIMAGESOURCE File-backed source using Bio-Formats.
    %
    % Notes:
    %   - First-pass implementation assumes scalar channels from a single series.
    %   - Uses Bio-Formats to infer Z/C/T sizes.
    %   - On load(), reads all planes into memory as ImageComponent objects.
    %   - unload() clears component Data but keeps metadata.
    %
    % Requires Bio-Formats MATLAB toolbox on path.

    properties
        FilePath (1,1) string
        SeriesIndex (1,1) double {mustBeInteger, mustBePositive} = 1
    end

    properties (Access = private)
        Components_ (1,:) matlabx.image.ImageComponent = matlabx.image.ImageComponent.empty(1,0)
        IsLoaded_ (1,1) logical = false

        OriginalMetadata_ struct = struct()
        OMEMetadata_ struct = struct()
        CoreMetadata_ struct = struct()
        GraphicsFileMetadata_ struct = struct()
    end


    methods
        function obj = BioFormatsImageSource(filePath, opts)
            arguments
                filePath {mustBeTextScalar}
                opts.SeriesIndex (1,1) double {mustBeInteger, mustBePositive} = 1
            end

            obj.FilePath = string(filePath);
            obj.SeriesIndex = opts.SeriesIndex;

            if ~isfile(obj.FilePath)
                error('BioFormatsImageSource:FileNotFound', ...
                    'File not found: %s', obj.FilePath);
            end

            obj.initializeMetadata_();
            obj.initializeComponents_();
        end

        function comps = getComponents(obj)
            comps = obj.Components_;
        end

        function tf = isLoaded(obj)
            tf = obj.IsLoaded_;
        end

        function tf = isFileBacked(~)
            tf = true;
        end

        function load(obj)
            if obj.IsLoaded_
                return
            end

            r = obj.createReader_();
            cleaner = onCleanup(@() obj.closeReader_(r));

            sizeX = r.getSizeX();
            sizeY = r.getSizeY();
            sizeZ = r.getSizeZ();
            sizeC = r.getSizeC();
            sizeT = r.getSizeT();
            pixelType = obj.bfPixelTypeToMatlabClass_(r.getPixelType());

            % RGB component path
            if obj.shouldTreatAsRGB_()
                data = zeros(sizeY, sizeX, 3, sizeZ, sizeT, pixelType);
            
                for t = 1:sizeT
                    for z = 1:sizeZ
                        % First try reading a single plane directly
                        iPlane = r.getIndex(z-1, 0, t-1) + 1;
                        plane = bfGetPlane(r, iPlane);
            
                        % plane has size [Y X 3] -> add to stack
                        if ndims(plane) == 3 && size(plane,3) == 3
                            data(:, :, :, z, t) = plane;
                        elseif ismatrix(plane) && sizeC >= 3
                            % Pack first 3 C planes into RGB
                            data(:, :, 1, z, t) = plane;
            
                            for c = 2:3
                                iPlane = r.getIndex(z-1, c-1, t-1) + 1;
                                planeC = bfGetPlane(r, iPlane);
            
                                if ~ismatrix(planeC)
                                    error('matlabx:image:BioFormatsImageSource:UnexpectedRGBPlaneShape', ...
                                        'Expected scalar plane for RGB sample %d, got size %s.', ...
                                        c, mat2str(size(planeC)));
                                end
            
                                data(:, :, c, z, t) = planeC;
                            end
                        else
                            error('matlabx:image:BioFormatsImageSource:UnexpectedRGBPlaneShape', ...
                                'Could not interpret RGB data from plane of size %s.', ...
                                mat2str(size(plane)));
                        end
                    end
                end
            
                obj.Components_(1).setData(data);
                obj.IsLoaded_ = true;
                return
            end

            % Scalar-channel path
            for c = 1:sizeC
                data = zeros(sizeY, sizeX, 1, sizeZ, sizeT, pixelType);

                for t = 1:sizeT
                    for z = 1:sizeZ
                        iPlane = r.getIndex(z-1, c-1, t-1) + 1;
                        plane = bfGetPlane(r, iPlane);
                        data(:, :, 1, z, t) = plane;
                    end
                end

                obj.Components_(c).setData(data);

                % testing below

                if isempty(obj.Components_(c).LUT)

                    try
                        lut = r.get8BitLookupTable(); % gets 8-bit LUT for the last opened image

                        if isempty(lut)
                            temp = r.get16BitLookupTable();
                            temp = temp';
                            temp = double(temp);
                            temp(temp<0) = temp(temp<0) + 65536;
                            temp = (temp./65535);
                            lut = zeros(256,3);
                            lutIdx = linspace(1,65536,256);
                            lut(1:256,:) = temp(lutIdx,:);
                        end

                        obj.Components_(c).LUT = lut;

                    catch
                    end

                end


                % end testing


            end

            obj.IsLoaded_ = true;
        end

        function unload(obj)
            for k = 1:numel(obj.Components_)
                obj.Components_(k).clearData();
            end
            obj.IsLoaded_ = false;
        end

        function I = getPlane(obj, idx, z, t)
            if obj.IsLoaded_
                
                I = obj.Components_(idx).getPlane(z, t);
                return
            end
        
            r = obj.createReader_();
            cleaner = onCleanup(@() obj.closeReader_(r));

            if obj.shouldTreatAsRGB_()
                iPlane = r.getIndex(z-1, 0, t-1) + 1;
                plane = bfGetPlane(r, iPlane);
            
                if ndims(plane) == 3 && size(plane,3) == 3
                    I = plane;
                    return
                end
            
                if ismatrix(plane) && r.getSizeC() >= 3
                    I = zeros(size(plane,1), size(plane,2), 3, class(plane));
                    I(:,:,1) = plane;
            
                    for c = 2:3
                        iPlane = r.getIndex(z-1, c-1, t-1) + 1;
                        I(:,:,c) = bfGetPlane(r, iPlane);
                    end
                    return
                end
            
                error('matlabx:image:BioFormatsImageSource:UnexpectedRGBPlaneShape', ...
                    'Could not interpret RGB plane.');
            end

        
            iPlane = r.getIndex(z-1, idx-1, t-1) + 1;
            I = bfGetPlane(r, iPlane);
        end

        function md = getOriginalMetadata(obj)
            md = obj.OriginalMetadata_;
        end
        
        function md = getOMEMetadata(obj)
            md = obj.OMEMetadata_;
        end

        function md = getCoreMetadata(obj)
            md = obj.CoreMetadata_;
        end
        
        function md = getGraphicsFileMetadata(obj)
            md = obj.GraphicsFileMetadata_;
        end


    end

    methods (Access = private)

        function initializeMetadata_(obj)
            r = obj.createReader_();
            cleaner = onCleanup(@() obj.closeReader_(r));
        
            obj.CoreMetadata_.SizeX = r.getSizeX();
            obj.CoreMetadata_.SizeY = r.getSizeY();
            obj.CoreMetadata_.SizeZ = r.getSizeZ();
            obj.CoreMetadata_.SizeC = r.getSizeC();
            obj.CoreMetadata_.SizeT = r.getSizeT();
            obj.CoreMetadata_.ImageCount = r.getImageCount();
            obj.CoreMetadata_.DimensionOrder = string(char(r.getDimensionOrder()));
            obj.CoreMetadata_.PixelType = string(obj.bfPixelTypeToMatlabClass_(r.getPixelType()));
            obj.CoreMetadata_.IsRGB = logical(r.isRGB());
            obj.CoreMetadata_.RGBChannelCount = double(r.getRGBChannelCount());
            obj.CoreMetadata_.IsIndexed = logical(r.isIndexed());
            obj.CoreMetadata_.IsInterleaved = logical(r.isInterleaved());
            obj.CoreMetadata_.SeriesIndex = obj.SeriesIndex;
            obj.CoreMetadata_.FilePath = obj.FilePath;
        
            try
                coreList = r.getCoreMetadataList();
                obj.CoreMetadata_.CoreMetadataList = coreList;
            catch
                obj.CoreMetadata_.CoreMetadataList = [];
            end
        
            obj.OriginalMetadata_ = obj.readOriginalMetadata_(r);
            obj.OMEMetadata_ = obj.readOMEMetadata_(r);
        
            try
                obj.GraphicsFileMetadata_ = imfinfo(obj.FilePath);
            catch
                obj.GraphicsFileMetadata_ = struct();
            end
        end


        function initializeComponents_(obj)
        
            isRGB = obj.shouldTreatAsRGB_();

            szY = obj.CoreMetadata_.SizeY;
            szX = obj.CoreMetadata_.SizeX;
            szZ = obj.CoreMetadata_.SizeZ;
            szT = obj.CoreMetadata_.SizeT;

            if isRGB
                comps = matlabx.image.ImageComponent([], ...
                    Name="RGB", ...
                    Kind="rgb", ...
                    Class=obj.CoreMetadata_.PixelType, ...
                    Size=[szY,szX,3,szZ,szT], ...
                    NativeDisplayRange=[0 255], ...
                    Metadata=struct( ...
                        'FilePath', obj.FilePath, ...
                        'SeriesIndex', obj.SeriesIndex), ...
                    LUT=[], ...
                    Color=[]);
        
                obj.Components_ = comps;
                return
            end
        
            nC = obj.CoreMetadata_.SizeC;
            comps(1,nC) = matlabx.image.ImageComponent();

            luts = obj.tryGetChannelLUTs_();
        
            omeChannels = [];
            if isfield(obj.OMEMetadata_, 'Basic') && ...
                    isstruct(obj.OMEMetadata_.Basic) && ...
                    isfield(obj.OMEMetadata_.Basic, 'Channels')
                omeChannels = obj.OMEMetadata_.Basic.Channels;
            end
        
            for c = 1:nC
                name = "Component " + c;
                color = [];
                lut = [];
        
                if ~isempty(omeChannels) && numel(omeChannels) >= c
                    if isfield(omeChannels(c), 'Name') && strlength(string(omeChannels(c).Name)) > 0
                        name = string(omeChannels(c).Name);
                    end
        
                    if isfield(omeChannels(c), 'Color') && ~isempty(omeChannels(c).Color)
                        color = matlabx.image.BioFormatsImageSource.omeColorStructToRgb_(omeChannels(c).Color);
                    end
                end
        
                if c <= numel(luts)
                    lut = luts{c};
                end

                className = obj.CoreMetadata_.PixelType;
                nativeDisplayRange = matlabx.image.BioFormatsImageSource.inferNativeDisplayRangeFromClass(className);
        
                comps(c) = matlabx.image.ImageComponent([], ...
                    Name=name, ...
                    Kind="scalar", ...
                    Class=className, ...
                    Size=[szY,szX,1,szZ,szT], ...
                    NativeDisplayRange=nativeDisplayRange, ...
                    Metadata=struct( ...
                        'FilePath', obj.FilePath, ...
                        'SeriesIndex', obj.SeriesIndex, ...
                        'ChannelIndex', c), ...
                    LUT=lut, ...
                    Color=color);
            end
        
            obj.Components_ = comps;
        end


        function md = readOriginalMetadata_(~, r)
            md = struct();
        
            try
                globalMD = r.getGlobalMetadata();
                md.Global = matlabx.image.BioFormatsImageSource.javaMapToStruct_(globalMD);
            catch ME
                warning('Error reading global metadata...')
                disp(ME.getReport)
                md.Global = struct();
            end
        
            try
                seriesMD = r.getSeriesMetadata();
                md.Series = matlabx.image.BioFormatsImageSource.javaMapToStruct_(seriesMD);
            catch
                md.Series = struct();
            end
        end
        
        function md = readOMEMetadata_(~, r)
            md = struct();
        
            try
                omeMeta = r.getMetadataStore();
                md.Store = omeMeta;
            catch
                md.Store = [];
                omeMeta = [];
            end
        
            try
                if ~isempty(omeMeta)
                    md.XML = char(omeMeta.dumpXML());
                else
                    md.XML = '';
                end
            catch
                md.XML = '';
            end
        
            try
                if ~isempty(omeMeta)
                    md.Basic = matlabx.image.BioFormatsImageSource.omeMetadataToStruct_(omeMeta, r.getSeries());
                else
                    md.Basic = struct();
                end
            catch
                md.Basic = struct();
            end
        end

        function r = createReader_(obj)
            bfCheckJavaPath();

            r = bfGetReader(char(obj.FilePath));
            r.setSeries(obj.SeriesIndex - 1);
        end

        function closeReader_(~, r)
            try
                r.close();
            catch
            end
        end

        function cls = bfPixelTypeToMatlabClass_(~, pixelType)
            if pixelType == loci.formats.FormatTools.UINT8
                cls = 'uint8';
            elseif pixelType == loci.formats.FormatTools.INT8
                cls = 'int8';
            elseif pixelType == loci.formats.FormatTools.UINT16
                cls = 'uint16';
            elseif pixelType == loci.formats.FormatTools.INT16
                cls = 'int16';
            elseif pixelType == loci.formats.FormatTools.UINT32
                cls = 'uint32';
            elseif pixelType == loci.formats.FormatTools.INT32
                cls = 'int32';
            elseif pixelType == loci.formats.FormatTools.SINGLE
                cls = 'single';
            elseif pixelType == loci.formats.FormatTools.DOUBLE
                cls = 'double';
            else
                error('BioFormatsImageSource:UnsupportedPixelType', ...
                    'Unsupported Bio-Formats pixel type.');
            end
        end

        function luts = tryGetChannelLUTs_(obj)
            try
                r = obj.createReader_();
                cleaner = onCleanup(@() obj.closeReader_(r));
        
                nC = r.getSizeC();
                luts = cell(1, nC);
        
                for c = 1:nC
                    try
                        iPlane = r.getIndex(0, c-1, 0) + 1;
                        lut = r.get8BitLookupTable();
        
                        if ~isempty(lut)
                            luts{c} = lut;
                        else
                            luts{c} = [];
                        end
                    catch
                        luts{c} = [];
                    end
                end
            catch
                luts = {};
            end
        end

        function tf = shouldTreatAsRGB_(obj)
            tf = false;
        
            % Bio-Formats direct signal
            if isfield(obj.CoreMetadata_, 'IsRGB') && obj.CoreMetadata_.IsRGB
                tf = true;
                return
            end
        
            info = obj.GraphicsFileMetadata_;
            if isempty(info) || ~isstruct(info)
                return
            end
        
            % PNG/JPEG/etc
            if isfield(info, 'ColorType') && strcmpi(info(1).ColorType, 'truecolor')
                tf = true;
                return
            end

            % GIF (and other indexed formats that Bio-Formats splits into RGB channels)
            if isfield(info, 'ColorType') && strcmpi(info(1).ColorType, 'indexed')
                tf = true;
                return
            end


            % TIFF-specific fallback
            if isfield(info, 'PhotometricInterpretation') && strcmpi(info(1).PhotometricInterpretation, 'RGB')
                tf = true;
                return
            end

        end

    end


    methods (Static, Access = private)

        function r = inferNativeDisplayRangeFromClass(className)
            switch string(className)
                case "uint8"
                    r = [0 255];
                case "int8"
                    r = [-128 127];
                case "uint16"
                    r = [0 65535];
                case "int16"
                    r = [-32768 32767];
                case "uint32"
                    r = [0 4294967295];
                case "int32"
                    r = [-2147483648 2147483647];
                case {"single","double"}
                    r = [0 1];   % display default, not numeric representable range
                case "logical"
                    r = [0 1];
                otherwise
                    r = [0 1];
            end
        end

        function s = javaMapToStruct_(mapObj)
            s = struct();
        
            if isempty(mapObj)
                return
            end
        
            try
                keys = mapObj.keySet().toArray();
            catch ME
                error('matlabx:image:BioFormatsImageSource:MetadataMapReadFailed', ...
                    'Failed to read Java metadata map keys: %s', ME.message);
            end
        
            for k = 1:numel(keys)
                key = keys(k);
        
                if isempty(key), continue; end
        
                % convert to char
                keyStr = matlabx.image.BioFormatsImageSource.javaKeyToChar_(key);
        
                % empty key -> warn and continue
                if isempty(keyStr)
                    warning('Empty key...')
                    continue
                end
        
                % attempt to grab value
                try
                    value = mapObj.get(key);
                catch
                    warning('Unable to metadata value for map key: %s',key)
                    value = [];
                end
        
                % create a valid struct fieldname
                field = matlab.lang.makeValidName(keyStr);
        
                % Avoid accidental overwrites if two keys sanitize to same field name
                if isfield(s, field)
                    duplicateField = field;
                    field = matlab.lang.makeUniqueStrings(field, fieldnames(s));
                    warning('Duplicate metadata fieldname %s renamed to %s',duplicateField,field);
                end
        
                % add value to the struct
                s.(field) = matlabx.image.BioFormatsImageSource.javaValueToMatlab_(value);
            end
        end

        function v = javaValueToMatlab_(value)
            if isempty(value)
                v = [];
                return
            end
        
            try
                if isjava(value)
                    v = char(value.toString());
                elseif isstring(value) || ischar(value) || isnumeric(value) || islogical(value)
                    v = value;
                else
                    v = string(value);
                end
            catch
                try
                    v = char(string(value));
                catch
                    v = [];
                end
            end
        end

        function str = javaKeyToChar_(key)
            if isempty(key)
                str = '';
            elseif ischar(key)
                str = key;
            elseif isstring(key)
                str = char(key);
            else
                str = char(key.toString());
            end
        end

        function out = javaObjToChar_(obj)
            if isempty(obj)
                out = '';
            elseif ischar(obj)
                out = obj;
            elseif isstring(obj)
                out = char(obj);
            else
                out = char(obj.toString());
            end
        end
        
        function s = lengthToStruct_(lenObj)
            s = struct('Value', [], 'Unit', '');
        
            if isempty(lenObj)
                return
            end
        
            try
                s.Value = lenObj.value().doubleValue();
            catch
            end
        
            try
                s.Unit = char(lenObj.unit().getSymbol());
            catch
                try
                    s.Unit = char(lenObj.unit().toString());
                catch
                end
            end
        end

        function s = omeMetadataToStruct_(omeMeta, iSeries)
            s = struct();
        
            % OME uses 0-based indices
            iImage = iSeries;
        
            try
                s.ImageName = matlabx.image.BioFormatsImageSource.javaObjToChar_( ...
                    omeMeta.getImageName(iImage));
            catch
                s.ImageName = '';
            end
        
            try
                s.ImageDescription = matlabx.image.BioFormatsImageSource.javaObjToChar_( ...
                    omeMeta.getImageDescription(iImage));
            catch
                s.ImageDescription = '';
            end
        
            try
                s.PixelsDimensionOrder = char(omeMeta.getPixelsDimensionOrder(iImage).getValue());
            catch
                s.PixelsDimensionOrder = '';
            end
        
            try
                s.PixelsType = char(omeMeta.getPixelsType(iImage).getValue());
            catch
                s.PixelsType = '';
            end
        
            try
                s.SizeX = omeMeta.getPixelsSizeX(iImage).getValue();
            catch
                s.SizeX = [];
            end
        
            try
                s.SizeY = omeMeta.getPixelsSizeY(iImage).getValue();
            catch
                s.SizeY = [];
            end
        
            try
                s.SizeZ = omeMeta.getPixelsSizeZ(iImage).getValue();
            catch
                s.SizeZ = [];
            end
        
            try
                s.SizeC = omeMeta.getPixelsSizeC(iImage).getValue();
            catch
                s.SizeC = [];
            end
        
            try
                s.SizeT = omeMeta.getPixelsSizeT(iImage).getValue();
            catch
                s.SizeT = [];
            end
        
            try
                s.PhysicalSizeX = matlabx.image.BioFormatsImageSource.lengthToStruct_( ...
                    omeMeta.getPixelsPhysicalSizeX(iImage));
            catch
                s.PhysicalSizeX = struct();
            end
        
            try
                s.PhysicalSizeY = matlabx.image.BioFormatsImageSource.lengthToStruct_( ...
                    omeMeta.getPixelsPhysicalSizeY(iImage));
            catch
                s.PhysicalSizeY = struct();
            end
        
            try
                s.PhysicalSizeZ = matlabx.image.BioFormatsImageSource.lengthToStruct_( ...
                    omeMeta.getPixelsPhysicalSizeZ(iImage));
            catch
                s.PhysicalSizeZ = struct();
            end
        
            % Channels
            nC = double(s.SizeC);
            if isempty(nC) || isnan(nC)
                nC = 0;
            end
        
            ch = repmat(struct( ...
                'Name', '', ...
                'Fluor', '', ...
                'EmissionWavelength', struct(), ...
                'ExcitationWavelength', struct()), 1, nC);
        
            for c = 1:nC
                iC = c - 1;
        
                try
                    ch(c).Name = matlabx.image.BioFormatsImageSource.javaObjToChar_( ...
                        omeMeta.getChannelName(iImage, iC));
                catch
                end
        
                try
                    ch(c).Fluor = matlabx.image.BioFormatsImageSource.javaObjToChar_( ...
                        omeMeta.getChannelFluor(iImage, iC));
                catch
                end

                try
                    ch(c).Color = matlabx.image.BioFormatsImageSource.omeColorToStruct_( ...
                        omeMeta.getChannelColor(iImage, iC));
                catch
                end

                try
                    ch(c).EmissionWavelength = matlabx.image.BioFormatsImageSource.lengthToStruct_( ...
                        omeMeta.getChannelEmissionWavelength(iImage, iC));
                catch
                end
        
                try
                    ch(c).ExcitationWavelength = matlabx.image.BioFormatsImageSource.lengthToStruct_( ...
                        omeMeta.getChannelExcitationWavelength(iImage, iC));
                catch
                end
            end
        
            s.Channels = ch;
        end

        function s = omeColorToStruct_(colorObj)
            s = struct('R', [], 'G', [], 'B', [], 'A', [], 'RGBA', []);
        
            if isempty(colorObj)
                return
            end
        
            % OME Color is commonly exposed as packed 32-bit RGBA plus channel getters,
            % depending on the Java object/version.
            try
                s.R = double(colorObj.getRed());
            catch
            end
        
            try
                s.G = double(colorObj.getGreen());
            catch
            end
        
            try
                s.B = double(colorObj.getBlue());
            catch
            end
        
            try
                s.A = double(colorObj.getAlpha());
            catch
            end
        
            try
                s.RGBA = double(colorObj.getValue());
            catch
            end
        
            % Fallback: if channel getters were unavailable but packed value exists,
            % unpack as 0xAARRGGBB
            if isempty(s.R) && ~isempty(s.RGBA)
                rgba = uint32(s.RGBA);
                s.A = double(bitand(bitshift(rgba, -24), 255));
                s.R = double(bitand(bitshift(rgba, -16), 255));
                s.G = double(bitand(bitshift(rgba,  -8), 255));
                s.B = double(bitand(rgba, 255));
            end
        end

        function rgb = omeColorStructToRgb_(colorStruct)
            rgb = [];
        
            if isempty(colorStruct) || ~isstruct(colorStruct)
                return
            end
        
            if all(isfield(colorStruct, {'R','G','B'})) && ...
                    ~isempty(colorStruct.R) && ...
                    ~isempty(colorStruct.G) && ...
                    ~isempty(colorStruct.B)
        
                rgb = double([colorStruct.R, colorStruct.G, colorStruct.B]);
        
                % Normalize 0-255 to 0-1 for MATLAB-style RGB if needed
                if any(rgb > 1)
                    rgb = rgb / 255;
                end
            end
        end

    end

end