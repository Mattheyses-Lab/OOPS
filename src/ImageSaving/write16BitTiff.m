function write16BitTiff(I,filename,Options)
%%  write16BitTiff  Writes the 2D or 3D matrix, I, to a single channel 16-bit TIFF file
%   at the location specified by filename
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
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

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