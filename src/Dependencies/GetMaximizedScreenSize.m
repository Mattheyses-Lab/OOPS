function ScreenSize = GetMaximizedScreenSize()
%% GetMaximizedScreenSize  Determine the currently drawable screen size.
%
%   Necessary workaround because the value given by get(0,'MonitorPositions') does not account for launcher bars

% create a temporary figure set to fill the entire usable screen
% keep invisible so it doesn't flash
TempFig = uifigure('Visible','Off','Units','Normalized','Position',[0 0 1 1]);
TempFig.WindowState = 'Maximized';

% change units to pixels
TempFig.Units = 'Pixels';
% ScreenSize comes from Postition property of temporary figure window
ScreenSize = TempFig.Position;
% close the figure
close(TempFig)
end