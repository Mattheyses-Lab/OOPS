classdef CustomFPMStatistic
%%  CUSTOMFPMSTATISTIC class used to define custom FPM statistics for the OOPS GUI
%
%   The OOPS data and settings classes will utilize instances of this class
%   to create a set of dynamic properties, so that user-defined FPM outputs
%   can be incorporated into the software
%
%   NOTES:
%
%       StatisticFun is a function handle, it must accept exactly one input and return exactly one output
%       the input will be a 4 image stack with polarizations of 0°, 45°, 90°, and 135°
%       the output will be a single, 2D image, representing the pixel-wise computation of the statistic
%
%       after creating an instance of this class, it needs to be saved in /path_to_OOPS/assets/custom_statistics
%       to be recognized by the software, where 'path_to_OOPS' is the full path to the directory containing 'OOPS.m'
%       
%       it is recommended that the function specified by StatisticFun be saved as a separate .m file in the directory below: 
%       /path_to_OOPS/src/Classes/custom_outputs/custom_functions
%       (realistically, the function could be saved anywhere on the MATLAB PATH)
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

    properties

        % name of the statistic (used internally by the software)
        StatisticName (1,:) char

        % display name of the statistic (used in image and plot labels)
        StatisticDisplayName (1,:) char
        
        % handle to function that will calculate the output image
        StatisticFun (1,1)

        % possible range of the output, used to scale the display properly
        StatisticRange (1,2) double = [0,1]

    end

    methods

        function obj = CustomFPMStatistic(StatisticName,StatisticDisplayName,StatisticFun,StatisticRange)
            obj.StatisticName = StatisticName;
            obj.StatisticDisplayName = StatisticDisplayName;
            obj.StatisticFun = StatisticFun;
            obj.StatisticRange = StatisticRange;
        end

    end

end