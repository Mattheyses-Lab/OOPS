function write32BitTiff(I,filename,Options)
% write32BitTiff  Writes the 2D or 3D matrix, I, to a single channel 32-bit TIFF file
% at the location specified by filename
%
%   INPUTS:
%       I (:,:,:) double, single, uint8, uint16 - 2D or 3D image to write to 32-bit TIFF with 1 or more planes
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

    % convert to single if necessary
    if ~isa(I,'single')
        I = im2single(I);
    end

    % create connection to the TIFF file specified by filename
    t = Tiff(filename, Options.mode);

    % set tags
    t.setTag('ImageLength',size(I, 1));
    t.setTag('ImageWidth',size(I, 2));
    t.setTag('Photometric',Tiff.Photometric.MinIsBlack);   
    t.setTag('Compression',Tiff.Compression.None);
    t.setTag('SampleFormat',Tiff.SampleFormat.IEEEFP);
    t.setTag('BitsPerSample',32);
    t.setTag('SamplesPerPixel',1);
    t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
    t.setTag('Software',Options.Software);

    % write the first plane and close the file
    t.write(I(:,:,1));
    t.close();

    % if more than one plane, append each plane recursively
    if size(I,3) > 1
        write32BitTiff(I(:,:,2:end),filename,'a');
    end

end