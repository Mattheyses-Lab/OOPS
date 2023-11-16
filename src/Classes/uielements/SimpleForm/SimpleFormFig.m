function Outputs = SimpleFormFig(Name,Params,FontColor,BackgroundColor)
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

    % initialize cell array of output variables
    Outputs = cell(numel(Params),1);

    % create the figure to hold the SimpleForm
    %   will call GatherOutputs() upon close request
    hFig = uifigure(...
        "HandleVisibility","on",...
        "Color","Black",...
        "Name",Name,...
        "Visible","off",...
        "WindowStyle","modal",...
        "CloseRequestFcn",@(o,e) GatherOutputs());

    % create the SimpleForm object in the figure we just created
    hSimpleForm = SimpleForm('Parent',hFig,...
        'Params',Params,...
        'FontColor',FontColor,...
        'BackgroundColor',BackgroundColor);

    % set inner height of figure based on number of inputs (calculated by SimpleForm object)
    hFig.InnerPosition(4) = hSimpleForm.FigInnerHeight;

    % move gui to the center of window
    movegui(hFig,'center');

    drawnow

    % turn on figure visibility
    hFig.Visible = 'On';

    % place focus on the first editfield
    hSimpleForm.focusFirst();    

    % wait until the figure is closed
    waitfor(hFig);

    % gather the output variables
    function GatherOutputs(~,~)
        % return outputs if "Save" button selected, otherwise return 0
        switch hSimpleForm.SaveStatus
            case "Save"
                Outputs = hSimpleForm.Outputs;
            case "Cancel"
                Outputs = 0;
        end
        % delete the figure
        delete(hFig)
    end

end