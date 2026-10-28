function writeOmeTiff(filename, image, opts)
%WRITEOMETIFF Write an Image5D as a single-series OME-TIFF.
%
%   matlabx.image.io.writeOmeTiff(FILE,IMAGE) writes compatible scalar
%   components or one RGB component from IMAGE. Scalar components become
%   OME channels. A single RGB component becomes one logical OME channel
%   with three interleaved samples per pixel.
%
%   Logical input is intentionally exported as uint8 mask data: false is 0
%   and true is 255. Other supported classes retain their class and values.
%
%   Name-value options:
%     Overwrite   - Replace an existing file (default false).
%     Compression - Bio-Formats compression name, or "" (default "").
%     BigTiff     - "auto", "on", or "off" (default "auto").
%     Creator     - OME creator string (default "MATLABX").
%     ImageName   - OME image name override (default "").
%     Metadata    - ImageMetadata values that override IMAGE.Metadata.
%     EmbedLUTs   - Embed TIFF lookup tables for scalar uint8/uint16 data
%                   (default false). Explicit ImageComponent LUT values are
%                   preferred; otherwise a linear LUT is built from Color.
%
%   The complete image is validated before the destination is changed. Data
%   is written to a temporary sibling file and moved into place only after
%   the Bio-Formats writer closes successfully.
%
%   See also matlabx.image.Image5D, matlabx.image.ImageMetadata

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

    arguments
        filename {mustBeTextScalar}
        image (1,1) matlabx.image.Image5D
        opts.Overwrite (1,1) logical = false
        opts.Compression (1,1) string = ""
        opts.BigTiff (1,1) string {mustBeMember(opts.BigTiff,["auto","on","off"])} = "auto"
        opts.Creator (1,1) string = "MATLABX"
        opts.ImageName (1,1) string = ""
        opts.Metadata = []
        opts.EmbedLUTs (1,1) logical = false
    end

    filename = string(filename);
    lowerFilename = lower(filename);
    if ~(endsWith(lowerFilename,".ome.tif") || endsWith(lowerFilename,".ome.tiff"))
        error('matlabx:image:io:writeOmeTiff:InvalidExtension', ...
            'OME-TIFF filenames must end in .ome.tif or .ome.tiff.');
    end
    if isfile(filename) && ~opts.Overwrite
        error('matlabx:image:io:writeOmeTiff:FileExists', ...
            'The destination already exists: %s',filename);
    end

    metadata = mergeMetadata_(image.Metadata,opts.Metadata);
    plan = describe_(image,metadata,opts,filename);

    destinationFolder = string(fileparts(filename));
    if strlength(destinationFolder) == 0
        destinationFolder = string(pwd);
        filename = fullfile(destinationFolder,filename);
    elseif ~isfolder(destinationFolder)
        error('matlabx:image:io:writeOmeTiff:FolderNotFound', ...
            'The destination folder does not exist: %s',destinationFolder);
    end

    ensureBioFormats_();

    temporaryFile = string(tempname(destinationFolder)) + ".ome.tiff";
    cleanupTemporary = onCleanup(@() deleteIfPresent_(temporaryFile));

    omeMetadata = createMetadata_(plan);
    originalOmeXml = char(omeMetadata.dumpXML());
    imageWriter = javaObject('loci.formats.ImageWriter');
    writer = imageWriter.getWriter(char(temporaryFile));
    cleanupWriter = onCleanup(@() closeWriterQuietly_(writer));

    writer.setWriteSequentially(true);
    writer.setMetadataRetrieve(omeMetadata);
    writer.setInterleaved(plan.Interleaved);
    validateCompression_(writer,opts.Compression);
    if strlength(opts.Compression) > 0
        writer.setCompression(char(opts.Compression));
    end
    writer.setBigTiff(plan.UseBigTiff);
    writer.setId(char(temporaryFile));

    colorModels = createColorModels_(plan,opts.EmbedLUTs);

    planeReader = image.openPlaneReader();
    cleanupReader = onCleanup(@() delete(planeReader));
    planeIndex = 0;

    for t = 1:plan.SizeT
        for z = 1:plan.SizeZ
            for c = 1:plan.LogicalChannelCount
                plane = planeReader.getPlane(c,z,t);
                validatePlane_(plane,plan,c,z,t);
                bytes = encodePlane_(plane,plan);
                if opts.EmbedLUTs
                    writer.setColorModel(colorModels{c});
                end
                savePlane_(writer,planeIndex,bytes,plan);
                planeIndex = planeIndex + 1;
            end
        end
    end

    writer.close();
    clear cleanupWriter cleanupReader

    % OMETiffWriter rebuilds parts of the supplied model when it closes.
    % Restore the validated XML so channel names, colors, calibration, and
    % RGB SamplesPerPixel semantics exactly match the requested export plan.
    overwriteOmeXml_(temporaryFile,originalOmeXml);

    if opts.Overwrite
        [ok,message] = movefile(temporaryFile,filename,'f');
    else
        [ok,message] = movefile(temporaryFile,filename);
    end
    if ~ok
        error('matlabx:image:io:writeOmeTiff:MoveFailed', ...
            'The completed OME-TIFF could not be moved into place: %s',message);
    end
    clear cleanupTemporary
end


function colorModels = createColorModels_(plan,embedLUTs)
    colorModels = {};
    if ~embedLUTs
        return
    end
    if plan.IsRGB || ~ismember(plan.PixelClass,["uint8","uint16"])
        error('matlabx:image:io:writeOmeTiff:UnsupportedEmbeddedLUTs', ...
            'Embedded LUTs require scalar uint8 or uint16 components.');
    end

    colorModels = cell(1,plan.LogicalChannelCount);
    for c = 1:plan.LogicalChannelCount
        lut = normalizeLUT_(plan.Components(c));
        if plan.PixelClass == "uint8"
            values = uint8(round(255 * lut));
            colorModels{c} = javaObject('java.awt.image.IndexColorModel', ...
                8,256,typecast(values(:,1),'int8'), ...
                typecast(values(:,2),'int8'),typecast(values(:,3),'int8'));
        else
            values = uint16(round(65535 * lut));
            % Reflection preserves the nested short[3][65536] shape; a
            % numeric MATLAB matrix is otherwise flattened at this boundary.
            table = javaMethod('newInstance','java.lang.reflect.Array', ...
                java.lang.Short.TYPE,int32([3 65536]));
            for channel = 1:3
                table(channel,:) = typecast(values(:,channel),'int16');
            end
            colorModels{c} = javaObject( ...
                'loci.formats.gui.Index16ColorModel',16,65536,table,true);
        end
    end
end


function lut = normalizeLUT_(component)
    lut = component.LUT;
    if isempty(lut)
        if isempty(component.Color)
            rgb = [1 1 1];
        else
            [~,rgb] = matlabx.image.normalizeComponentColor(component.Color);
        end
        lut = linspace(0,1,256).' .* rgb;
    else
        lut = double(lut);
        if size(lut,2) ~= 3 && size(lut,1) == 3
            lut = lut.';
        end
        if size(lut,2) ~= 3 || ~ismember(size(lut,1),[256 65536])
            error('matlabx:image:io:writeOmeTiff:InvalidLUT', ...
                'Component "%s" LUT must be 256-by-3 or 65536-by-3.',component.Name);
        end
        if any(lut(:) < 0)
            % Java byte and short lookup tables arrive in MATLAB as signed data.
            if size(lut,1) == 256
                lut(lut < 0) = lut(lut < 0) + 256;
            else
                lut(lut < 0) = lut(lut < 0) + 65536;
            end
        end
        if max(lut,[],'all') > 1
            if size(lut,1) == 256
                lut = lut ./ 255;
            else
                lut = lut ./ 65535;
            end
        end
        if any(~isfinite(lut),'all') || any(lut < 0 | lut > 1,'all')
            error('matlabx:image:io:writeOmeTiff:InvalidLUT', ...
                'Component "%s" LUT values must describe colors between 0 and 1.',component.Name);
        end
    end

    targetLength = 256;
    if component.Class == "uint16"
        targetLength = 65536;
    end
    if size(lut,1) ~= targetLength
        source = linspace(0,1,size(lut,1));
        target = linspace(0,1,targetLength);
        lut = interp1(source,lut,target,'linear');
    end
end


function plan = describe_(image,metadata,opts,filename)
    components = image.Components;
    if isempty(components)
        error('matlabx:image:io:writeOmeTiff:EmptyImage', ...
            'Image5D must contain at least one component.');
    end

    kinds = string({components.Kind});
    classes = string({components.Class});
    sizes = vertcat(components.Size);
    supportedClasses = ["uint8","int8","uint16","int16", ...
        "uint32","int32","single","double","logical"];

    if any(~ismember(classes,supportedClasses))
        bad = unique(classes(~ismember(classes,supportedClasses)),'stable');
        error('matlabx:image:io:writeOmeTiff:UnsupportedClass', ...
            'Unsupported component class: %s.',strjoin(bad,", "));
    end
    if numel(unique(classes)) ~= 1
        error('matlabx:image:io:writeOmeTiff:ClassMismatch', ...
            'All components must have the same numeric class.');
    end
    if any(any(sizes(:,[1 2 4 5]) ~= sizes(1,[1 2 4 5])))
        error('matlabx:image:io:writeOmeTiff:GeometryMismatch', ...
            'All components must have matching Y, X, Z, and T dimensions.');
    end

    isScalar = kinds == "scalar" & sizes(:,3) == 1;
    isRGB = kinds == "rgb" & sizes(:,3) == 3;
    if all(isScalar)
        logicalChannels = numel(components);
        samplesPerPixel = 1;
        sizeC = logicalChannels;
        interleaved = false;
    elseif isscalar(components) && isRGB
        logicalChannels = 1;
        samplesPerPixel = 3;
        sizeC = 3;
        % Store RGB samples in chunky order within each TIFF IFD.
        interleaved = true;
    else
        error('matlabx:image:io:writeOmeTiff:UnsupportedComponents', ...
            ['An OME-TIFF must contain either compatible scalar components ' ...
             'or exactly one RGB component. Mixed or multiple RGB components are unsupported.']);
    end

    inputClass = classes(1);
    if inputClass == "logical"
        pixelClass = "uint8";
    else
        pixelClass = inputClass;
    end

    bytesPerSample = bytesPerSample_(pixelClass);
    estimatedBytes = prod(double(sizes(1,[1 2 4 5]))) * ...
        double(sizeC) * bytesPerSample;
    switch opts.BigTiff
        case "on"
            useBigTiff = true;
        case "off"
            useBigTiff = false;
        otherwise
            useBigTiff = estimatedBytes >= 3.8 * 1024^3;
    end

    imageName = opts.ImageName;
    if strlength(imageName) == 0
        imageName = metadata.ImageName;
    end
    if strlength(imageName) == 0
        [~,stem,extension] = fileparts(filename);
        imageName = regexprep(string(stem) + string(extension), ...
            '(?i)\.ome\.tiff?$','');
    end

    plan = struct( ...
        'SizeX',double(sizes(1,2)), ...
        'SizeY',double(sizes(1,1)), ...
        'SizeC',double(sizeC), ...
        'SizeZ',double(sizes(1,4)), ...
        'SizeT',double(sizes(1,5)), ...
        'LogicalChannelCount',double(logicalChannels), ...
        'SamplesPerPixel',double(samplesPerPixel), ...
        'IsRGB',logical(samplesPerPixel == 3), ...
        'Interleaved',interleaved, ...
        'InputClass',inputClass, ...
        'PixelClass',pixelClass, ...
        'Components',components, ...
        'Metadata',metadata, ...
        'ImageName',imageName, ...
        'Creator',opts.Creator, ...
        'UseBigTiff',useBigTiff);
end


function metadata = createMetadata_(plan)
    service = javaObject('loci.formats.services.OMEXMLServiceImpl');
    metadata = service.createOMEXMLMetadata();
    metadata.createRoot();
    metadata.setCreator(char(plan.Creator));
    metadata.setImageID('Image:0',0);
    metadata.setImageName(char(plan.ImageName),0);
    if strlength(plan.Metadata.Description) > 0
        metadata.setImageDescription(char(plan.Metadata.Description),0);
    end
    metadata.setPixelsID('Pixels:0',0);
    metadata.setPixelsBigEndian(javaObject('java.lang.Boolean',false),0);
    metadata.setPixelsInterleaved(javaObject('java.lang.Boolean',plan.Interleaved),0);

    orderHandler = javaObject('ome.xml.model.enums.handlers.DimensionOrderEnumHandler');
    metadata.setPixelsDimensionOrder(orderHandler.getEnumeration('XYCZT'),0);
    typeHandler = javaObject('ome.xml.model.enums.handlers.PixelTypeEnumHandler');
    pixelType = char(plan.PixelClass);
    if plan.PixelClass == "single"
        pixelType = 'float';
    end
    metadata.setPixelsType(typeHandler.getEnumeration(pixelType),0);
    metadata.setPixelsSizeX(positiveInteger_(plan.SizeX),0);
    metadata.setPixelsSizeY(positiveInteger_(plan.SizeY),0);
    metadata.setPixelsSizeC(positiveInteger_(plan.SizeC),0);
    metadata.setPixelsSizeZ(positiveInteger_(plan.SizeZ),0);
    metadata.setPixelsSizeT(positiveInteger_(plan.SizeT),0);

    for c = 1:plan.LogicalChannelCount
        metadata.setChannelID(sprintf('Channel:0:%d',c-1),0,c-1);
        metadata.setChannelSamplesPerPixel(positiveInteger_(plan.SamplesPerPixel),0,c-1);
        name = plan.Components(c).Name;
        if strlength(name) > 0
            metadata.setChannelName(char(name),0,c-1);
        end
        color = plan.Components(c).Color;
        if ~isempty(color) && plan.SamplesPerPixel == 1
            [~,rgb] = matlabx.image.normalizeComponentColor(color);
            rgb = round(255 * rgb);
            if numel(rgb) == 3
                metadata.setChannelColor(javaObject( ...
                    'ome.xml.model.primitives.Color',rgb(1),rgb(2),rgb(3),255),0,c-1);
            end
        end
        setChannelWavelength_(metadata,plan.Components(c).Metadata, ...
            'ExcitationWavelength','ExcitationWavelengthUnit', ...
            'setChannelExcitationWavelength',c-1);
        setChannelWavelength_(metadata,plan.Components(c).Metadata, ...
            'EmissionWavelength','EmissionWavelengthUnit', ...
            'setChannelEmissionWavelength',c-1);
    end

    setLength_(metadata,'X',plan.Metadata.PhysicalSizeX,plan.Metadata.PhysicalSizeXUnit);
    setLength_(metadata,'Y',plan.Metadata.PhysicalSizeY,plan.Metadata.PhysicalSizeYUnit);
    setLength_(metadata,'Z',plan.Metadata.PhysicalSizeZ,plan.Metadata.PhysicalSizeZUnit);
    if ~isnan(plan.Metadata.TimeIncrement)
        unit = omeUnit_(plan.Metadata.TimeIncrementUnit,'time');
        quantity = javaObject('ome.units.quantity.Time', ...
            javaObject('java.lang.Double',plan.Metadata.TimeIncrement),unit);
        metadata.setPixelsTimeIncrement(quantity,0);
    end


    metadata.setTiffDataIFD(nonnegativeInteger_(0),0,0);
    metadata.setTiffDataFirstC(nonnegativeInteger_(0),0,0);
    metadata.setTiffDataFirstZ(nonnegativeInteger_(0),0,0);
    metadata.setTiffDataFirstT(nonnegativeInteger_(0),0,0);
    metadata.setTiffDataPlaneCount( ...
        nonnegativeInteger_(plan.SizeZ * plan.LogicalChannelCount * plan.SizeT),0,0);
end


function setLength_(metadata,axisName,value,unitName)
    if isnan(value)
        return
    end
    unit = omeUnit_(unitName,'length');
    quantity = javaObject('ome.units.quantity.Length', ...
        javaObject('java.lang.Double',value),unit);
    switch axisName
        case 'X', metadata.setPixelsPhysicalSizeX(quantity,0);
        case 'Y', metadata.setPixelsPhysicalSizeY(quantity,0);
        case 'Z', metadata.setPixelsPhysicalSizeZ(quantity,0);
    end
end


function setChannelWavelength_(metadata,componentMetadata,valueField,unitField,methodName,channelIndex)
    if ~isstruct(componentMetadata) || ...
            ~isfield(componentMetadata,valueField) || ...
            ~isfield(componentMetadata,unitField)
        return
    end
    value = componentMetadata.(valueField);
    unitName = string(componentMetadata.(unitField));
    if isempty(value) || ~isscalar(value) || ~isfinite(value) || value <= 0 || strlength(unitName) == 0
        return
    end
    unit = omeUnit_(unitName,'length');
    quantity = javaObject('ome.units.quantity.Length', ...
        javaObject('java.lang.Double',double(value)),unit);
    javaMethod(methodName,metadata,quantity,0,channelIndex);
end


function unit = omeUnit_(name,kind)
    key = lower(strtrim(string(name)));
    key = replace(key,"μ","µ");
    if strlength(key) == 0
        error('matlabx:image:io:writeOmeTiff:MissingUnit', ...
            'A unit is required whenever a physical metadata value is supplied.');
    end
    if kind == "length"
        switch key
            case {"m","meter","metre"}, unit = ome.units.UNITS.METRE;
            case {"mm","millimeter","millimetre"}, unit = ome.units.UNITS.MILLIMETRE;
            case {"um","µm","micrometer","micrometre"}, unit = ome.units.UNITS.MICROMETRE;
            case {"nm","nanometer","nanometre"}, unit = ome.units.UNITS.NANOMETRE;
            case {"pm","picometer","picometre"}, unit = ome.units.UNITS.PICOMETRE;
            otherwise
                error('matlabx:image:io:writeOmeTiff:UnsupportedLengthUnit', ...
                    'Unsupported physical-size unit: %s.',name);
        end
    else
        switch key
            case {"s","sec","second"}, unit = ome.units.UNITS.SECOND;
            case {"ms","millisecond"}, unit = ome.units.UNITS.MILLISECOND;
            case {"us","µs","microsecond"}, unit = ome.units.UNITS.MICROSECOND;
            case {"min","minute"}, unit = ome.units.UNITS.MINUTE;
            case {"h","hr","hour"}, unit = ome.units.UNITS.HOUR;
            otherwise
                error('matlabx:image:io:writeOmeTiff:UnsupportedTimeUnit', ...
                    'Unsupported time unit: %s.',name);
        end
    end
end


function bytes = encodePlane_(plane,plan)
    if plan.InputClass == "logical"
        plane = uint8(plane) .* uint8(255);
    end
    if plan.IsRGB
        if plan.Interleaved
            values = permute(plane,[3 2 1]);
        else
            values = permute(plane,[2 1 3]);
        end
    else
        values = plane.';
    end
    values = values(:);
    switch plan.PixelClass
        case {"uint8","int8"}
            bytes = values;
        case {"uint16","int16"}
            bytes = javaMethod('shortsToBytes','loci.common.DataTools',values,true);
        case {"uint32","int32"}
            bytes = javaMethod('intsToBytes','loci.common.DataTools',values,true);
        case "single"
            bytes = javaMethod('floatsToBytes','loci.common.DataTools',values,true);
        case "double"
            bytes = javaMethod('doublesToBytes','loci.common.DataTools',values,true);
    end
end


function validatePlane_(plane,plan,c,z,t)
    expected = [plan.SizeY plan.SizeX];
    if plan.IsRGB
        expected(3) = 3;
    end
    actual = size(plane,1:numel(expected));
    if ~isequal(actual,expected) || string(class(plane)) ~= plan.InputClass
        error('matlabx:image:io:writeOmeTiff:InvalidPlane', ...
            'Component %d, Z=%d, T=%d returned %s %s; expected %s %s.', ...
            c,z,t,class(plane),mat2str(actual),plan.InputClass,mat2str(expected));
    end
end


function savePlane_(writer,index,bytes,plan)
    if ~plan.IsRGB
        writer.saveBytes(index,bytes);
        return
    end

    % The TIFF tags are explicit because treating a three-sample plane as
    % grayscale causes OMETiffWriter to expand it into three logical channels.
    ifd = javaObject('loci.formats.tiff.IFD');
    ifd.putIFDValue(262,2); % PhotometricInterpretation = RGB
    ifd.putIFDValue(277,3); % SamplesPerPixel = 3
    writer.saveBytes(index,bytes,ifd,0,0,plan.SizeX,plan.SizeY);
end


function validateCompression_(writer,compression)
    if strlength(compression) == 0
        return
    end
    supported = string(arrayfun(@char,writer.getCompressionTypes(), ...
        'UniformOutput',false));
    if ~any(compression == supported)
        error('matlabx:image:io:writeOmeTiff:UnsupportedCompression', ...
            'Unsupported compression "%s". Supported values are: %s.', ...
            compression,strjoin(supported,", "));
    end
end


function metadata = mergeMetadata_(base,override)
    if isempty(override)
        metadata = base;
        return
    end
    if ~isa(override,'matlabx.image.ImageMetadata') || ~isscalar(override)
        error('matlabx:image:io:writeOmeTiff:InvalidMetadata', ...
            'Metadata must be a scalar matlabx.image.ImageMetadata.');
    end
    metadata = base;
    textProperties = ["ImageName","Description","PhysicalSizeXUnit", ...
        "PhysicalSizeYUnit","PhysicalSizeZUnit","TimeIncrementUnit"];
    numericProperties = ["PhysicalSizeX","PhysicalSizeY", ...
        "PhysicalSizeZ","TimeIncrement"];
    for name = textProperties
        if strlength(override.(name)) > 0
            metadata.(name) = override.(name);
        end
    end
    for name = numericProperties
        if ~isnan(override.(name))
            metadata.(name) = override.(name);
        end
    end
end


function value = positiveInteger_(value)
    value = javaObject('ome.xml.model.primitives.PositiveInteger', ...
        javaObject('java.lang.Integer',value));
end


function value = nonnegativeInteger_(value)
    value = javaObject('ome.xml.model.primitives.NonNegativeInteger', ...
        javaObject('java.lang.Integer',value));
end


function n = bytesPerSample_(className)
    switch className
        case {"uint8","int8"}, n = 1;
        case {"uint16","int16"}, n = 2;
        case {"uint32","int32","single"}, n = 4;
        case "double", n = 8;
    end
end


function deleteIfPresent_(file)
    if isfile(file)
        delete(file);
    end
end


function ensureBioFormats_()
    % Avoid reconfiguring the dynamic Java path while live Bio-Formats
    % metadata objects exist. Full setup is only needed when the API is not
    % already available in the current MATLAB session.
    available = exist('bfCheckJavaPath','file') == 2 && bfCheckJavaPath(false);
    if ~available
        matlabx.setup.bioFormats();
    end
    javaMethod('enableLogging','loci.common.DebugTools','OFF');
    javaMethod('setRootLevel','loci.common.DebugTools','OFF');
end


function closeWriterQuietly_(writer)
    try
        writer.close();
    catch
    end
end


function overwriteOmeXml_(file,xml)
    stream = javaObject('loci.common.RandomAccessInputStream',char(file));
    cleanupStream = onCleanup(@() stream.close());
    saver = javaObject('loci.formats.tiff.TiffSaver',char(file));
    cleanupSaver = onCleanup(@() saver.close());
    saver.overwriteComment(stream,xml);
    clear cleanupSaver cleanupStream
end
