function UpdateGUITheme(source)
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

    OOPSData = guidata(source);

    GUIBackgroundColor = OOPSData.Settings.GUIBackgroundColor;
    GUIForegroundColor = OOPSData.Settings.GUIForegroundColor;
    GUIHighlightColor = OOPSData.Settings.GUIHighlightColor;


    % % testing below
    % GUIPanelTitleBackgroundColor = [0.9 0.9 0.9];
    % GUIPanelTitleFontColor = [0 0 0];
    % GUIPanelBorderColor = [1 1 1];
    % GUIAccordionTitleBackgroundColor = [0.9 0.9 0.9];
    % GUIAccordionTitleFontColor = [0 0 0];
    % GUIAccordionBorderColor = [1 1 1];
    % % end testing

    GUIPanelTitleBackgroundColor = GUIBackgroundColor;
    GUIPanelTitleFontColor = GUIForegroundColor;
    GUIPanelBorderColor = GUIHighlightColor;
    GUIAccordionTitleBackgroundColor = GUIBackgroundColor;
    GUIAccordionTitleFontColor = GUIForegroundColor;
    GUIAccordionBorderColor = GUIHighlightColor;

    % get all accordion items and their children (cannot retrieve with findobj())
    accordionItems = OOPSData.Handles.SettingsAccordion.Items;
    accordionChildren = OOPSData.Handles.SettingsAccordion.Contents;
    
    % uiaccordionitem
    set(accordionItems,...
        'PaneBackgroundColor',GUIBackgroundColor,...
        'BorderColor',GUIAccordionBorderColor,...
        'FontColor',GUIAccordionTitleFontColor,...
        'TitleBackgroundColor',GUIAccordionTitleBackgroundColor);
    
    % uiaccordion
    set(OOPSData.Handles.SettingsAccordion,...
        'BackgroundColor',GUIBackgroundColor);
    
    % uigridlayout
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uigridlayout'),...
        'BackgroundColor',GUIBackgroundColor);
    
    % uipanel
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uipanel'),...
        'BackgroundColor',GUIPanelTitleBackgroundColor,...
        'ForegroundColor',GUIPanelTitleFontColor,...
        'HighlightColor',GUIPanelBorderColor);
    
    % uitextarea
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uitextarea'),...
        'FontColor',GUIForegroundColor,...
        'BackgroundColor',GUIBackgroundColor);
    
    % axes
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','axes'),...
        'XColor',GUIForegroundColor,...
        'YColor',GUIForegroundColor,...
        'Color',GUIBackgroundColor);
    
    % uilabel
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uilabel'),...
        'FontColor',GUIForegroundColor,...
        'BackgroundColor',GUIBackgroundColor);
    
    % uitable
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uitable'),...
        'BackgroundColor',GUIBackgroundColor,...
        'ForegroundColor',GUIForegroundColor);
    
    % uilistbox
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uilistbox'),...
        'BackgroundColor',GUIBackgroundColor,...
        'FontColor',GUIForegroundColor);
    
    % uitree
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uitree'),...
        'BackgroundColor',GUIBackgroundColor,...
        'FontColor',GUIForegroundColor);

    % uicheckboxtree
    set(findobj([OOPSData.Handles.fH;accordionChildren],'type','uicheckboxtree'),...
        'BackgroundColor',GUIBackgroundColor,...
        'FontColor',GUIForegroundColor);

    % set scatter plot colors
    set(OOPSData.Handles.GroupScatterPlot,...
        'BackgroundColor',OOPSData.Settings.ScatterPlotBackgroundColor,...
        'ForegroundColor',OOPSData.Settings.ScatterPlotForegroundColor);

    % set swarm plot colors
    set(OOPSData.Handles.SwarmPlot,...
        'BackgroundColor',OOPSData.Settings.SwarmPlotBackgroundColor,...
        'ForegroundColor',OOPSData.Settings.SwarmPlotForegroundColor);
    
    % set object intensity profile colors
    OOPSData.Handles.ObjectIntensityPlotAxH.Color = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;
    OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Color = OOPSData.Settings.ObjectIntensityProfileForegroundColor;
    OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Color = OOPSData.Settings.ObjectIntensityProfileForegroundColor;
    OOPSData.Handles.ImgPanel2.BackgroundColor = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;
    
    % set built-in intensity slider colors
    set(OOPSData.Handles.PrimaryIntensitySlider,...
        'BackgroundColor',GUIBackgroundColor,...
        'ThumbFaceColor',GUIForegroundColor,...
        'ThumbEdgeColor',GUIForegroundColor,...
        'FontColor',GUIForegroundColor);

    set(OOPSData.Handles.ReferenceIntensitySlider,...
        'BackgroundColor',GUIBackgroundColor,...
        'ThumbFaceColor',GUIForegroundColor,...
        'ThumbEdgeColor',GUIForegroundColor,...
        'FontColor',GUIForegroundColor);

    set(OOPSData.Handles.OrderSlider,...
        'BackgroundColor',GUIBackgroundColor,...
        'ThumbFaceColor',GUIForegroundColor,...
        'ThumbEdgeColor',GUIForegroundColor,...
        'FontColor',GUIForegroundColor);

    % set custom intensity slider colors
    for i = 1:numel(OOPSData.Settings.CustomStatistics)
        set(OOPSData.Handles.([OOPSData.Settings.CustomStatistics(i).StatisticName,'Slider']),...
            'BackgroundColor',GUIBackgroundColor,...
            'ThumbFaceColor',GUIForegroundColor,...
            'ThumbEdgeColor',GUIForegroundColor,...
            'FontColor',GUIForegroundColor);
    end


    OOPSData.Handles.CurrentThresholdLine.Color = GUIForegroundColor;
    
    OOPSData.Handles.OrderAxH.Color = 'Black';
    OOPSData.Handles.AverageIntensityAxH.Color = 'Black';
    OOPSData.Handles.AzimuthAxH.Color = 'Black';
    OOPSData.Handles.MaskAxH.Color = 'Black';
    OOPSData.Handles.CustomStatAxH.Color = 'Black';
    
end