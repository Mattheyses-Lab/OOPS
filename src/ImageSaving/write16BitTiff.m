function write16BitTiff(I,filename,Options)
% write16BitTiff  Writes the 2D or 3D matrix, I, to a single channel 16-bit TIFF file
% at the location specified by filename
%
%   INPUTS:
%       I (:,:,:) double, single, uint8, uint16 - 2D or 3D image to write to 16-bit TIFF with 1 or more planes
%       filename (1,:) char - full filename specifying the location of the TIFF
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
    Options.mode (1,1) char {mustBeMember(Options.mode,{'w','a'})} = 'w'
    Options.Software (1,:) char = ''
end

    % convert to uint8 if necessary
    if ~isa(I,'uint16')
        I = im2uint16(I);
    end

    % create connection to the TIFF file specified by filename
    t = Tiff(filename, Options.mode);

    % set tags
    t.setTag('ImageLength',size(I, 1));
    t.setTag('ImageWidth',size(I, 2));
    t.setTag('Photometric',Tiff.Photometric.MinIsBlack);   
    t.setTag('Compression',Tiff.Compression.None);
    t.setTag('SampleFormat',Tiff.SampleFormat.UInt);
    t.setTag('BitsPerSample',16);
    t.setTag('SamplesPerPixel',1);
    t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
    t.setTag('Software',Options.Software);

    % write the first plane and close the file
    t.write(I(:,:,1));
    t.close();

    % if more than one plane, append each plane recursively
    if size(I,3) > 1
        write16BitTiff(I(:,:,2:end),filename,'mode','a','Software',Options.Software);
    end

end