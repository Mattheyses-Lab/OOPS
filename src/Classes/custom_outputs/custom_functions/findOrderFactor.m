function OrderFactor = findOrderFactor(FPMStack)
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

% normalize to the maximum along the third dimensions
FPMStackNorm = FPMStack./max(FPMStack,[],3);

% 
a = FPMStackNorm(:,:,1) - FPMStackNorm(:,:,3);
b = FPMStackNorm(:,:,2) - FPMStackNorm(:,:,4);

OrderFactor = hypot(a,b);

end