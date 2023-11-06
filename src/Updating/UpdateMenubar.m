function UpdateMenubar(source)

    % the main data structure
    OOPSData = guidata(source);

    % hide or show top level menus based on project status
    OOPSData.Handles.hTabMenu.Enable = OOPSData.GUIProjectStarted;
    OOPSData.Handles.hProcessMenu.Enable = OOPSData.GUIProjectStarted;
    OOPSData.Handles.hSummaryMenu.Enable = OOPSData.GUIProjectStarted;
    OOPSData.Handles.hObjectsMenu.Enable = OOPSData.GUIProjectStarted;
    OOPSData.Handles.hPlotMenu.Enable = OOPSData.GUIProjectStarted;

end