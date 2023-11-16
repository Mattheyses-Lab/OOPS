function Iout = quasihbreak(I)
%%  QUASIHBREAK remove h-connected and "nearly" h-connected pixels from a binary image
%
%   DESCRIPTION:
%       Given a binary image, remove h-connected pixels and "nearly" h-connected pixels, 
%       return the adjusted image
%
%   INPUT:
%       I | (mxn) logical | binary image
%
%   OUTPUT:
%       Iout | (double) | adjusted binary image, same size as I
%
%   ASSUMPTIONS AND LIMITATIONS:
%       I think I have accounted for all possible "near h's" here but, as I manually defined them,
%       I may have missed some. This could be updated to automatically generate the set of 
%       reference matrices more elegantly
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

%% define the types of neighborhoods we are searching for
% upper left corner missing
quasihnhoods{1} = [0 1 1;...
                   0 1 0;...
                   1 1 1];
% upper right corner missing
quasihnhoods{2} = [1 1 0;...
                   0 1 0;...
                   1 1 1];
% lower left corner missing
quasihnhoods{3} = [1 1 1;...
                   0 1 0;...
                   0 1 1];
% lower right corner missing
quasihnhoods{4} = [1 1 1;...
                   0 1 0;...
                   1 1 0];
% both upper corners missing
quasihnhoods{5} = [0 1 0;...
                   0 1 0;...
                   1 1 1];
% both lower corners missing
quasihnhoods{6} = [1 1 1;...
                   0 1 0;...
                   0 1 0];
% both upper, lower left missing
quasihnhoods{7} = [0 1 0;...
                   0 1 0;...
                   0 1 1];
% both upper, lower right missing
quasihnhoods{8} = [0 1 0;...
                   0 1 0;...
                   1 1 0];
% both lower, upper left missing
quasihnhoods{9} = [0 1 1;...
                   0 1 0;...
                   0 1 0];
% both lower, upper right missing
quasihnhoods{10} = [1 1 0;...
                    0 1 0;...
                    0 1 0];
% both upper and lower left missing
quasihnhoods{11} = [0 1 1;...
                    0 1 0;...
                    0 1 1];
% both upper and lower right missing
quasihnhoods{12} = [1 1 0;...
                    0 1 0;...
                    1 1 0];
% upper left, lower right missing
quasihnhoods{13} = [0 1 1;...
                    0 1 0;...
                    1 1 0];
% upper right, lower left missing
quasihnhoods{14} = [1 1 0;...
                    0 1 0;...
                    0 1 1];
% the "true" h-connected nhood
quasihnhoods{15} = [1 1 1;...
                    0 1 0;...
                    1 1 1];
%% create a lookup table function for the neighborhoods we are searching for

% anonymous lut function
quasihlutfun = @(x) checkMatch(x);

% create 3x3 lut using function handle above
quasihlut = makelut(quasihlutfun,3);

% image representing locations of pixels at centers of 3x3 nhoods that 
% match at least one of the reference nhoods (or their 90° rotation)
quasihlocations = bwlookup(I,quasihlut);

% remove those pixels from the original binary image
Iout = I-quasihlocations;

    function match = checkMatch(nhood)
        % check each nhood to see if it matches the any of the reference nhoods
        % default result (no match found)
        match = false;
        % for each reference neighborhood
        for i = 1:numel(quasihnhoods)
            % pull its value into ref
            ref = quasihnhoods{i};
            % check for a match
            if all(nhood(:)==ref(:))
                match = true;
                % exit the loop if a match was found
                break
            end
            % rotate the reference nhood 90 degrees
            ref = rot90(ref);
            % check for match again
            if (all(nhood(:)==ref(:)))
                match = true;
                % and exit if match found
                break
            end
        end
    end

end