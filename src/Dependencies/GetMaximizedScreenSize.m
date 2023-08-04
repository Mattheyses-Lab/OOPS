function ScreenSize = GetMaximizedScreenSize(WithMenu)
%% Obtain the currently usable screen size. Necessary because the value
%  given by get(0,'MonitorPositions') does not account for launcher bars

    % create a temporary figure set to fill the entire usable screen
    % keep invisible so it doesn't flash
    TempFig = uifigure('Visible','Off','Units','Normalized','Position',[0 0 1 1]);
    TempFig.WindowState = 'Maximized';

    % % draw it
    % drawnow
    % % give time for drawnow
    % pause(0.1)
    % % if the figure to be sized will have a MenuBar
    % if WithMenu
    %     % create a temporary MenuBar
    %     TempMenu = uimenu(TempFig,'Text','TempMenu');
    %     % draw it
    %     drawnow
    %     % give time for drawnow
    %     pause(0.5)
    % end

    % change units to pixels
    TempFig.Units = 'Pixels';
    % get the pixel position of the figure w/ or w/o MenuBar
    ScreenSize = TempFig.Position;
    % close the figure
    close(TempFig)
end