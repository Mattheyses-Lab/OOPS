classdef testWriteOmeTiff < matlab.unittest.TestCase
    %TESTWRITEOMETIFF Focused Image5D OME-TIFF writer regression tests.

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

    properties
        Folder (1,1) string
    end

    methods (TestClassSetup)
        function configureBioFormats(testCase)
            matlabx.setup.bioFormats();
            testCase.Folder = string(tempname);
            mkdir(testCase.Folder);
            testCase.addTeardown(@() rmdir(testCase.Folder,'s'));
        end
    end

    methods (Test)
        function scalarCztRoundTrip(testCase)
            a = reshape(uint16(1:210),[5 7 1 2 3]);
            b = uint16(1000) + a;
            metadata = matlabx.image.ImageMetadata( ...
                ImageName="CZT example", ...
                Description="Asymmetric round trip", ...
                PhysicalSizeX=0.11, ...
                PhysicalSizeY=0.23, ...
                PhysicalSizeZ=0.7, ...
                PhysicalSizeUnit="um", ...
                TimeIncrement=2.5, ...
                TimeIncrementUnit="s");
            image = matlabx.image.Image5D.fromComponents( ...
                {a,b},Names=["First","Second"], ...
                Colors=["red","cyan"],Metadata=metadata);
            image.Components(1).Metadata = struct( ...
                'ExcitationWavelength',488, ...
                'ExcitationWavelengthUnit',"nm", ...
                'EmissionWavelength',525, ...
                'EmissionWavelengthUnit',"nm");
            file = testCase.file_("czt.ome.tiff");

            matlabx.image.io.writeOmeTiff(file,image);
            actual = matlabx.image.Image5D.fromFile(file,LoadOnCreate=true);

            testCase.verifyEqual(actual.Size,[5 7 2 2 3]);
            testCase.verifyEqual(actual.Components(1).Data,a);
            testCase.verifyEqual(actual.Components(2).Data,b);
            testCase.verifyEqual([actual.Components.Name],["First","Second"]);
            testCase.verifyEqual(actual.Components(1).Color,[1 0 0],'AbsTol',1/255);
            testCase.verifyEqual(actual.Components(2).Color,[0 1 1],'AbsTol',1/255);
            testCase.verifyEqual(actual.Metadata.ImageName,"CZT example");
            testCase.verifyEqual(actual.Metadata.Description,"Asymmetric round trip");
            testCase.verifyEqual(actual.Metadata.PhysicalSizeX,0.11,'AbsTol',1e-12);
            testCase.verifyEqual(actual.Metadata.PhysicalSizeY,0.23,'AbsTol',1e-12);
            testCase.verifyEqual(actual.Metadata.PhysicalSizeZ,0.7,'AbsTol',1e-12);
            testCase.verifyEqual(actual.Metadata.TimeIncrement,2.5,'AbsTol',1e-12);
            excitation = actual.OMEMetadata.Store.getChannelExcitationWavelength(0,0);
            emission = actual.OMEMetadata.Store.getChannelEmissionWavelength(0,0);
            testCase.verifyEqual(excitation.value(ome.units.UNITS.NANOMETRE).doubleValue(),488);
            testCase.verifyEqual(emission.value(ome.units.UNITS.NANOMETRE).doubleValue(),525);
        end

        function supportedScalarClassesRoundTrip(testCase)
            classes = ["uint8","int8","uint16","int16", ...
                "uint32","int32","single","double"];
            for className = classes
                values = reshape(1:35,[5 7]);
                switch className
                    case {"int8","int16","int32"}
                        expected = cast(reshape(-17:17,[5 7]),className);
                    case "uint32"
                        expected = intmax('uint32') - uint32(values);
                    case "single"
                        expected = single(values) ./ 7;
                    case "double"
                        expected = double(values) ./ 11;
                    otherwise
                        expected = cast(values,className);
                end
                file = testCase.file_("scalar-" + className + ".ome.tiff");
                image = matlabx.image.Image5D.fromComponents(expected);
                matlabx.image.io.writeOmeTiff(file,image);
                actual = matlabx.image.Image5D.fromFile(file,LoadOnCreate=true);
                testCase.verifyClass(actual.Components(1).Data,char(className));
                testCase.verifyEqual(actual.Components(1).Data,expected);
            end
        end

        function logicalBecomesEightBitMask(testCase)
            mask = false(5,7);
            mask(2:4,3:6) = true;
            file = testCase.file_("mask.ome.tiff");
            image = matlabx.image.Image5D.fromComponents(mask);

            matlabx.image.io.writeOmeTiff(file,image);
            actual = matlabx.image.Image5D.fromFile(file,LoadOnCreate=true);

            testCase.verifyClass(actual.Components(1).Data,'uint8');
            testCase.verifyEqual(actual.Components(1).Data,uint8(mask) .* 255);
        end

        function embedsChannelLookupTables(testCase)
            first = reshape(uint8(1:35),[5 7]);
            second = uint8(100) + first;
            image = matlabx.image.Image5D.fromComponents( ...
                {first,second},Colors=["red","cyan"]);
            file = testCase.file_("lookup-tables.ome.tiff");

            matlabx.image.io.writeOmeTiff(file,image,EmbedLUTs=true);

            reader = javaObject('loci.formats.ImageReader');
            cleanup = onCleanup(@() reader.close());
            reader.setId(char(file));
            reader.openBytes(reader.getIndex(0,0,0));
            red = double(reader.get8BitLookupTable()).';
            reader.openBytes(reader.getIndex(0,1,0));
            cyan = double(reader.get8BitLookupTable()).';
            red(red < 0) = red(red < 0) + 256;
            cyan(cyan < 0) = cyan(cyan < 0) + 256;

            testCase.verifyEqual(red(end,:),[255 0 0]);
            testCase.verifyEqual(cyan(end,:),[0 255 255]);
        end

        function embedsSixteenBitLookupTable(testCase)
            data = reshape(uint16(1:35),[5 7]);
            image = matlabx.image.Image5D.fromComponents(data,Colors="magenta");
            file = testCase.file_("lookup-table-16.ome.tiff");

            matlabx.image.io.writeOmeTiff(file,image,EmbedLUTs=true);

            reader = javaObject('loci.formats.ImageReader');
            cleanup = onCleanup(@() reader.close());
            reader.setId(char(file));
            reader.openBytes(0);
            lut = double(reader.get16BitLookupTable()).';
            lut(lut < 0) = lut(lut < 0) + 65536;

            testCase.verifyEqual(lut(end,:),[65535 0 65535]);
        end

        function rgbRoundTrip(testCase)
            rgb = zeros(5,7,3,2,3,'uint8');
            base = reshape(uint8(1:35),5,7);
            for t = 1:3
                for z = 1:2
                    rgb(:,:,1,z,t) = base + 10*z + 30*t;
                    rgb(:,:,2,z,t) = 70 + 3*z;
                    rgb(:,:,3,z,t) = 140 + 2*t;
                end
            end
            file = testCase.file_("rgb.ome.tiff");
            image = matlabx.image.Image5D.fromComponents(rgb,Kinds="rgb",Names="RGB image");

            matlabx.image.io.writeOmeTiff(file,image);
            actual = matlabx.image.Image5D.fromFile(file,LoadOnCreate=true);

            testCase.verifyEqual(actual.NumComponents,1);
            testCase.verifyTrue(actual.Components(1).IsRGB);
            testCase.verifyEqual(actual.Components(1).Data,rgb);

            % Bio-Formats normalizes RGB samples to scalar channel entries in
            % its reader metadata store. Inspect the source OME-XML embedded
            % in the TIFF to verify the writer's logical-channel contract.
            info = imfinfo(file);
            xml = string(info(1).ImageDescription);
            testCase.verifySubstring(xml,'SizeC="3"');
            testCase.verifySubstring(xml,'SamplesPerPixel="3"');
            testCase.verifyEqual(count(xml,'<Channel '),1);
        end

        function rejectsMixedScalarAndRgb(testCase)
            scalar = matlabx.image.ImageComponent(uint8(ones(5,7)),Kind="scalar");
            rgb = matlabx.image.ImageComponent(uint8(ones(5,7,3)),Kind="rgb");
            source = matlabx.image.InMemoryImageSource([scalar rgb]);
            image = matlabx.image.Image5D(source);

            testCase.verifyError( ...
                @() matlabx.image.io.writeOmeTiff(testCase.file_("mixed.ome.tiff"),image), ...
                'matlabx:image:io:writeOmeTiff:UnsupportedComponents');
        end

        function rejectsMismatchedClasses(testCase)
            first = matlabx.image.ImageComponent(uint8(ones(5,7)));
            second = matlabx.image.ImageComponent(uint16(ones(5,7)));
            source = matlabx.image.InMemoryImageSource([first second]);
            image = matlabx.image.Image5D(source);

            testCase.verifyError( ...
                @() matlabx.image.io.writeOmeTiff(testCase.file_("classes.ome.tiff"),image), ...
                'matlabx:image:io:writeOmeTiff:ClassMismatch');
        end

        function existingFileIsNotChangedWithoutOverwrite(testCase)
            file = testCase.file_("existing.ome.tiff");
            fid = fopen(file,'w');
            fwrite(fid,uint8([1 2 3]));
            fclose(fid);
            image = matlabx.image.Image5D.fromComponents(uint8(ones(5,7)));

            testCase.verifyError( ...
                @() matlabx.image.io.writeOmeTiff(file,image), ...
                'matlabx:image:io:writeOmeTiff:FileExists');
            fid = fopen(file,'r');
            bytes = fread(fid,Inf,'*uint8');
            fclose(fid);
            testCase.verifyEqual(bytes,uint8([1;2;3]));
        end
    end

    methods (Access = private)
        function file = file_(testCase,name)
            file = fullfile(testCase.Folder,name);
        end
    end
end
