function Write8BitTiff(I,filename,Options)
% write8BitTiff  Writes the 2D or 3D matrix, I, to a single channel 8-bit TIFF file
% at the location specified by filename
%
%   INPUTS:
%       I (:,:,:) double, single, uint8, uint16 - 2D or 3D image to write to 8-bit TIFF with 1 or more planes
%       filename (1,:) char - full filename specifying the location of the TIFF
%       map (256,3) double - colormap/LUT saved along with the grayscale image
%       mode (1,1) char - scalar specifying how the TIFF should be opened
%           mode = 'w' | open file for writing, discard existing contents
%           mode = 'a' | open or create file for writing, append
%
%   OUTPUTS:
%       none
%
%   See also Tiff

arguments
    I (:,:,:) {mustBeNumeric(I)}
    filename (1,:) char
    Options.map (256,3) double {mustBeInRange(Options.map,0,1)} = gray
    Options.mode (1,1) char {mustBeMember(Options.mode,{'w','a'})} = 'w'
    Options.Software (1,:) char = ''
end

    % convert to uint8 if necessary
    if ~isa(I,'uint8')
        I = im2uint8(I);
    end

    % create connection to the TIFF file specified by filename
    t = Tiff(filename, Options.mode);

    % set tags
    t.setTag('ImageLength',size(I, 1));
    t.setTag('ImageWidth',size(I, 2));
    t.setTag('Photometric',Tiff.Photometric.MinIsBlack);   
    t.setTag('Compression',Tiff.Compression.None);
    t.setTag('SampleFormat',Tiff.SampleFormat.UInt);
    t.setTag('BitsPerSample',8);
    t.setTag('SamplesPerPixel',1);
    t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
    t.setTag('ColorMap',Options.map);
    t.setTag('Software',Options.Software);

    % write the first plane and close the file
    t.write(I(:,:,1));
    t.close();

    % if more than one plane, append each plane recursively
    if size(I,3) > 1
        Write8BitTiff(I(:,:,2:end),filename,Options.map,'a');
    end

end