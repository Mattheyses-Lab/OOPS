function Outputs = SimpleFormFig(Name,Params,FontColor,BackgroundColor)

    % initialize cell array of output variables
    Outputs = cell(numel(Params),1);

    % create the figure to hold the SimpleForm
    %   will call GatherOutputs() upon close request
    hFig = uifigure(...
        "HandleVisibility","on",...
        "Color","Black",...
        "Name",Name,...
        "Visible","on",...
        "CloseRequestFcn",@(o,e) GatherOutputs());

    % create the SimpleForm object in the figure we just created
    hSimpleForm = SimpleForm('Parent',hFig,'Params',Params,'FontColor',FontColor,'BackgroundColor',BackgroundColor);

    % set inner height of figure based on number of inputs (calculated by SimpleForm object)
    hFig.InnerPosition(4) = hSimpleForm.FigInnerHeight;

    % move gui to the center of window
    movegui(hFig,'center');

    % turn on figure visibility
    hFig.Visible = 'On';

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

        % delete the SimpleForm custom container object
        delete(hSimpleForm)

        % delete the figure
        delete(hFig)

    end

end